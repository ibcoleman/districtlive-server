import 'dart:async';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drift/drift.dart' show Value;
import 'package:district_live/core/database/app_database.dart';
import 'package:district_live/core/database/sync_metadata_dao.dart';
import 'package:district_live/features/events/data/events_api.dart';
import 'package:district_live/features/events/data/events_filter_state.dart';
import 'package:district_live/features/events/data/event_dao.dart';
import 'package:district_live/features/events/data/artist_dao.dart';
import 'package:district_live/features/events/domain/date_preset.dart';
import 'package:district_live/features/events/domain/event.dart';
import 'package:district_live/core/network/page_response.dart';
import 'package:district_live/features/venues/data/venue_dao.dart';

part 'events_notifier.freezed.dart';
part 'events_notifier.g.dart';

/// Filter state provider scoped by scopeKey to support multiple independent event lists.
@riverpod
class EventsFilter extends _$EventsFilter {
  @override
  EventsFilterState build(String scopeKey) => const EventsFilterState();

  void setDatePreset(DatePreset preset) {
    state = state.copyWith(datePreset: preset);
  }

  void setVenueFilter(String? id, String? name, {String? slug}) {
    state = state.copyWith(selectedVenueId: id, selectedVenueName: name, selectedVenueSlug: slug);
  }

  void setGenreFilter(String? genre) {
    state = state.copyWith(selectedGenre: genre);
  }

  void setSort(String? sort) {
    state = state.copyWith(sort: sort);
  }

  void clearAllFilters() {
    state = const EventsFilterState();
  }
}

/// UI state for the events list.
@freezed
abstract class EventsUiState with _$EventsUiState {
  const factory EventsUiState({
    required List<EventsTableData> events,
    required bool isLoading,
    required bool isRefreshing,
    @Default(false) bool isLoadingMore,
    Object? error,
    required int currentPage,
    required bool hasMorePages,
  }) = _EventsUiState;

  const EventsUiState._();

  bool get isEmpty => events.isEmpty && !isLoading && error == null;
  bool get isError => error != null;
  bool get hasData => events.isNotEmpty;
}

/// Events notifier that implements cache-first loading with background refresh.
/// Family provider scoped by scopeKey to support multiple independent event lists.
@riverpod
class EventsNotifier extends _$EventsNotifier {
  late EventDao _eventDao;
  late ArtistDao _artistDao;
  late VenueDao _venueDao;
  late SyncMetadataDao _syncMetadataDao;
  late EventsApi _eventsApi;

  int _currentPage = 0;
  static const int _pageSize = 20;

  @override
  Future<EventsUiState> build(String scopeKey) async {
    // Get DAOs and API from refs
    final database = ref.watch(appDatabaseProvider);
    _eventDao = database.eventDao;
    _artistDao = database.artistDao;
    _venueDao = database.venueDao;
    _syncMetadataDao = database.syncMetadataDao;
    _eventsApi = ref.watch(eventsApiProvider);

    // Watch filter changes
    final filter = ref.watch(eventsFilterProvider(scopeKey));

    // Reset page when filter changes
    _currentPage = 0;

    // Get cached events immediately
    final cachedEvents = await _getCachedEvents(filter);

    // Schedule background refresh
    unawaited(Future.microtask(() => _backgroundRefresh(filter, scopeKey)));

    final hasMorePages = cachedEvents.length >= _pageSize;

    return EventsUiState(
      events: cachedEvents,
      isLoading: cachedEvents.isEmpty,
      isRefreshing: false,
      isLoadingMore: false,
      error: null,
      currentPage: _currentPage,
      hasMorePages: hasMorePages,
    );
  }

  /// Get cached events from Drift with current filter.
  /// Returns all pages loaded so far (page 0 through _currentPage).
  Future<List<EventsTableData>> _getCachedEvents(EventsFilterState filter) async {
    final dateRange = filter.datePreset.getRange();
    return _eventDao.watchEvents(
      venueId: filter.selectedVenueId,
      genre: filter.selectedGenre,
      dateFrom: dateRange.dateFrom,
      dateTo: dateRange.dateTo,
      sort: filter.sort,
      limit: _pageSize * (_currentPage + 1),
      offset: 0,
    ).first;
  }

  /// Background refresh from API
  Future<void> _backgroundRefresh(EventsFilterState filter, String scopeKey) async {
    try {
      // Check staleness — but always refresh when a venue filter is active,
      // since the global 'events' sync key doesn't track per-venue freshness
      final isStale = await _syncMetadataDao.isStale('events');
      if (!isStale && filter.selectedVenueSlug == null) {
        return; // Cache is fresh and no venue filter, skip refresh
      }

      // Fetch from API
      final dateRange = filter.datePreset.getRange();
      final response = await _eventsApi.getEvents(
        page: _currentPage,
        size: _pageSize,
        dateFrom: dateRange.dateFrom,
        dateTo: dateRange.dateTo,
        venue: filter.selectedVenueSlug,
        genre: filter.selectedGenre,
        sort: filter.sort,
      );

      // Upsert data into Drift (atomic transaction)
      await _upsertApiResponse(response);

      // Update sync metadata
      await _syncMetadataDao.updateLastSyncedAt('events', DateTime.now());

      // Update state with refreshed data from cache
      final refreshedEvents = await _getCachedEvents(filter);
      state = AsyncValue.data(
        EventsUiState(
          events: refreshedEvents,
          isLoading: false,
          isRefreshing: false,
          isLoadingMore: false,
          error: null,
          currentPage: _currentPage,
          hasMorePages: refreshedEvents.length >= _pageSize,
        ),
      );
    } catch (e) {
      // If network fails, update state with soft error if we have cached data
      final cachedEvents = await _getCachedEvents(filter);
      if (cachedEvents.isNotEmpty) {
        // Soft error: show cached data with error notification
        state = AsyncValue.data(
          EventsUiState(
            events: cachedEvents,
            isLoading: false,
            isRefreshing: false,
            isLoadingMore: false,
            error: e,
            currentPage: _currentPage,
            hasMorePages: cachedEvents.length >= _pageSize,
          ),
        );
      } else {
        // Hard error: no cached data, show error state
        state = AsyncValue.error(e, StackTrace.current);
      }
    }
  }

  /// Upsert API response data into Drift
  Future<void> _upsertApiResponse(PageResponse<Event> response) async {
    // response is a PageResponse<Event>
    final events = response.content;

    // Prepare companions for upsert
    final eventCompanions = <EventsTableCompanion>[];
    final eventArtistMap = <String, List<String>>{};

    for (final event in events) {
      eventCompanions.add(
        EventsTableCompanion(
          id: Value(event.id),
          title: Value(event.title),
          slug: Value(event.slug),
          description: Value(event.description),
          startTime: Value(event.startTime),
          doorsTime: Value(event.doorsTime),
          venueId: Value(event.venue?.id),
          minPrice: Value(event.minPrice),
          maxPrice: Value(event.maxPrice),
          priceTier: Value(event.priceTier?.toString().split('.').last),
          ticketUrl: Value(event.ticketUrl),
          soldOut: Value(event.soldOut),
          imageUrl: Value(event.imageUrl),
          ageRestriction: Value(event.ageRestriction.toString().split('.').last),
          status: Value(event.status.toString().split('.').last),
          createdAt: Value(event.createdAt),
        ),
      );

      // Collect artist IDs
      if (event.artists.isNotEmpty) {
        eventArtistMap[event.id] = event.artists.map((a) => a.id).toList();
      }
    }

    // Collect all venues and artists
    final venuesMap = <String, VenuesTableCompanion>{};
    final artistsMap = <String, ArtistsTableCompanion>{};

    for (final event in events) {
      if (event.venue != null) {
        final venue = event.venue!;
        venuesMap[venue.id] = VenuesTableCompanion(
          id: Value(venue.id),
          name: Value(venue.name),
          slug: Value(venue.slug),
          neighborhood: Value(venue.neighborhood),
        );
      }

      for (final artist in event.artists) {
        artistsMap[artist.id] = ArtistsTableCompanion(
          id: Value(artist.id),
          name: Value(artist.name),
          slug: Value(artist.slug),
          genres: Value(artist.genres.join('|||')),
          imageUrl: Value(artist.imageUrl),
          isLocal: Value(artist.isLocal),
        );
      }
    }

    // Upsert venues
    if (venuesMap.isNotEmpty) {
      await _venueDao.upsertVenues(venuesMap.values.toList());
    }

    // Upsert artists
    if (artistsMap.isNotEmpty) {
      await _artistDao.upsertArtists(artistsMap.values.toList());
    }

    // Upsert events
    await _eventDao.upsertEvents(eventCompanions);

    // Upsert event-artist associations
    for (final entry in eventArtistMap.entries) {
      await _eventDao.upsertEventArtists(entry.key, entry.value);
    }
  }

  /// Manually load the next page
  Future<void> loadNextPage(String scopeKey) async {
    final filter = ref.read(eventsFilterProvider(scopeKey));
    final currentState = state.requireValue;

    // Set loading state
    state = AsyncValue.data(
      currentState.copyWith(isLoadingMore: true),
    );

    _currentPage++;

    try {
      final dateRange = filter.datePreset.getRange();
      final response = await _eventsApi.getEvents(
        page: _currentPage,
        size: _pageSize,
        dateFrom: dateRange.dateFrom,
        dateTo: dateRange.dateTo,
        venue: filter.selectedVenueSlug,
        genre: filter.selectedGenre,
        sort: filter.sort,
      );

      await _upsertApiResponse(response);

      // Update state with new page
      final newEvents = await _getCachedEvents(filter);
      state = AsyncValue.data(
        EventsUiState(
          events: newEvents,
          isLoading: false,
          isRefreshing: false,
          isLoadingMore: false,
          error: null,
          currentPage: _currentPage,
          hasMorePages: (response.content as List).length >= _pageSize,
        ),
      );
    } catch (e) {
      // Restore previous page number on error
      _currentPage--;
      state = AsyncValue.data(
        currentState.copyWith(isLoadingMore: false, error: e),
      );
    }
  }

  /// Refresh from API regardless of staleness
  Future<void> refresh(String scopeKey) async {
    state = AsyncValue.data(
      (state.requireValue).copyWith(isRefreshing: true),
    );

    final filter = ref.read(eventsFilterProvider(scopeKey));
    _currentPage = 0;

    try {
      final dateRange = filter.datePreset.getRange();
      final response = await _eventsApi.getEvents(
        page: 0,
        size: _pageSize,
        dateFrom: dateRange.dateFrom,
        dateTo: dateRange.dateTo,
        venue: filter.selectedVenueSlug,
        genre: filter.selectedGenre,
        sort: filter.sort,
      );

      await _upsertApiResponse(response);
      await _syncMetadataDao.updateLastSyncedAt('events', DateTime.now());

      final newEvents = await _getCachedEvents(filter);
      state = AsyncValue.data(
        EventsUiState(
          events: newEvents,
          isLoading: false,
          isRefreshing: false,
          isLoadingMore: false,
          error: null,
          currentPage: _currentPage,
          hasMorePages: (response.content as List).length >= _pageSize,
        ),
      );
    } catch (e) {
      final cachedEvents = await _getCachedEvents(filter);
      if (cachedEvents.isNotEmpty) {
        // Soft error
        state = AsyncValue.data(
          EventsUiState(
            events: cachedEvents,
            isLoading: false,
            isRefreshing: false,
            isLoadingMore: false,
            error: e,
            currentPage: _currentPage,
            hasMorePages: cachedEvents.length >= _pageSize,
          ),
        );
      } else {
        state = AsyncValue.error(e, StackTrace.current);
      }
    }
  }
}

