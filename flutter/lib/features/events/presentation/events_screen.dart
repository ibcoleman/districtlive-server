import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:district_live/core/database/app_database.dart';
import 'package:district_live/core/widgets/error_state.dart';
import 'package:district_live/core/widgets/empty_state.dart';
import 'package:district_live/core/widgets/loading_state.dart';
import 'package:district_live/features/events/data/events_notifier.dart';
import 'package:district_live/features/events/data/events_filter_state.dart';
import 'package:district_live/features/events/domain/date_preset.dart';
import 'package:district_live/features/events/presentation/event_card.dart';
import 'package:district_live/features/events/presentation/filter_bottom_sheet.dart';

/// EventsScreen displays a paginated, filterable list of events.
///
/// Parameters:
/// - scopeKey: A string key that scopes the filter state and notifier.
///   Main events tab uses 'events-tab'; venue events uses 'venue-events-$venueId'.
/// - lockedVenueId: Optional venue ID to lock the venue filter (used in VenueEventsScreen).
/// - lockedVenueName: Optional venue name for display when venue is locked.
/// - title: Optional custom AppBar title. Defaults to 'Events' if not provided.
class EventsScreen extends ConsumerStatefulWidget {
  final String scopeKey;
  final String? lockedVenueId;
  final String? lockedVenueName;
  final String? lockedVenueSlug;
  final String? title;
  final String? defaultSort;
  final bool showDatePresets;
  final String basePath;

  const EventsScreen({
    super.key,
    required this.scopeKey,
    this.lockedVenueId,
    this.lockedVenueName,
    this.lockedVenueSlug,
    this.title,
    this.defaultSort,
    this.showDatePresets = true,
    this.basePath = '/events',
  });

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Initialize locked venue filter if provided
    if (widget.lockedVenueId != null && widget.lockedVenueName != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(eventsFilterProvider(widget.scopeKey).notifier)
            .setVenueFilter(widget.lockedVenueId, widget.lockedVenueName, slug: widget.lockedVenueSlug);
      });
    }

    // Initialize default sort and date preset if provided
    if (widget.defaultSort != null || !widget.showDatePresets) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final notifier = ref.read(eventsFilterProvider(widget.scopeKey).notifier);
        if (widget.defaultSort != null) {
          notifier.setSort(widget.defaultSort);
        }
        if (!widget.showDatePresets) {
          notifier.setDatePreset(DatePreset.all);
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Check if we're near the bottom of the list to trigger pagination
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final notifier = ref.read(eventsProvider(widget.scopeKey).notifier);
      final state = ref.read(eventsProvider(widget.scopeKey));
      state.whenData((uiState) {
        if (uiState.hasMorePages && !uiState.isLoading && !uiState.isLoadingMore) {
          notifier.loadNextPage(widget.scopeKey);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsyncValue = ref.watch(eventsProvider(widget.scopeKey));
    final filter = ref.watch(eventsFilterProvider(widget.scopeKey));

    // Show error snackbar if there's a soft error
    ref.listen(eventsProvider(widget.scopeKey), (previous, next) {
      next.whenData((uiState) {
        if (uiState.error != null && uiState.hasData) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${uiState.error}'),
              action: SnackBarAction(
                label: 'Retry',
                onPressed: () {
                  ref
                      .read(eventsProvider(widget.scopeKey).notifier)
                      .refresh(widget.scopeKey);
                },
              ),
            ),
          );
        }
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'Events'),
        elevation: 0,
      ),
      body: eventsAsyncValue.when(
        loading: () => const LoadingState(),
        error: (error, stack) => ErrorState(
          message: error.toString(),
          onRetry: () {
            ref.read(eventsProvider(widget.scopeKey).notifier).refresh(widget.scopeKey);
          },
        ),
        data: (uiState) => _buildEventsList(context, uiState, filter),
      ),
    );
  }

  /// Build the main events list with filters and pull-to-refresh
  Widget _buildEventsList(
    BuildContext context,
    EventsUiState uiState,
    EventsFilterState filter,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(eventsProvider(widget.scopeKey).notifier)
            .refresh(widget.scopeKey);
      },
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Date preset chips (hidden for custom sort views like Just Announced)
          if (widget.showDatePresets)
            SliverToBoxAdapter(
              child: _buildDatePresetChips(context, filter),
            ),
          // Filter chips
          SliverToBoxAdapter(
            child: _buildFilterChips(context, filter),
          ),
          // Events list or empty state
          if (uiState.isEmpty)
            SliverFillRemaining(
              child: EmptyState(
                message: 'No events found',
                icon: Icons.event_busy,
              ),
            )
          else if (uiState.hasData)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final event = uiState.events[index];
                  return _EventCardWithVenue(
                    event: event,
                    basePath: widget.basePath,
                  );
                },
                childCount: uiState.events.length,
              ),
            ),
          // Loading indicator at bottom when loading more
          if (uiState.isLoadingMore)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Build the date preset chip row
  Widget _buildDatePresetChips(
    BuildContext context,
    EventsFilterState filter,
  ) {
    final presetLabels = {
      DatePreset.today: 'Today',
      DatePreset.thisWeek: 'This Week',
      DatePreset.thisWeekend: 'This Weekend',
      DatePreset.all: 'All',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          for (final preset in DatePreset.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(presetLabels[preset]!),
                selected: filter.datePreset == preset,
                onSelected: (_) {
                  ref
                      .read(eventsFilterProvider(widget.scopeKey).notifier)
                      .setDatePreset(preset);
                },
              ),
            ),
        ],
      ),
    );
  }

  /// Build filter chip row (venue, genre)
  Widget _buildFilterChips(
    BuildContext context,
    EventsFilterState filter,
  ) {
    final venuesAsync = ref.watch(_watchVenuesProvider);
    final genresAsync = ref.watch(_watchGenresProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 8,
        children: [
          // Venue filter chip
          FilterChip(
            label: Text(filter.selectedVenueName ?? 'Venue'),
            selected: filter.selectedVenueId != null,
            onSelected: widget.lockedVenueId == null
                ? (_) => _showVenueFilter(context, filter, venuesAsync)
                : null,
          ),
          // Genre filter chip
          FilterChip(
            label: Text(filter.selectedGenre ?? 'Genre'),
            selected: filter.selectedGenre != null,
            onSelected: (_) => _showGenreFilter(context, filter, genresAsync),
          ),
        ],
      ),
    );
  }

  /// Show venue filter bottom sheet
  void _showVenueFilter(
    BuildContext context,
    EventsFilterState filter,
    AsyncValue<List<VenuesTableData>> venuesAsync,
  ) {
    venuesAsync.whenData((venues) {
      if (!context.mounted) return;

      final keyValuePairs = venues
          .map((v) => (key: v.id, value: v.name))
          .toList();

      showModalBottomSheet(
        context: context,
        builder: (_) => FilterBottomSheet.keyValue(
          title: 'Select Venue',
          items: keyValuePairs,
          selectedKey: filter.selectedVenueId,
          onSelected: (venueId) {
            if (venueId != null) {
              final venue = venues.firstWhere((v) => v.id == venueId);
              ref
                  .read(eventsFilterProvider(widget.scopeKey).notifier)
                  .setVenueFilter(venueId, venue.name, slug: venue.slug);
            } else {
              ref
                  .read(eventsFilterProvider(widget.scopeKey).notifier)
                  .setVenueFilter(null, null);
            }
          },
        ),
      );
    });
  }

  /// Show genre filter bottom sheet
  void _showGenreFilter(
    BuildContext context,
    EventsFilterState filter,
    AsyncValue<List<String>> genresAsync,
  ) {
    genresAsync.whenData((genres) {
      if (!context.mounted) return;

      showModalBottomSheet(
        context: context,
        builder: (_) => FilterBottomSheet.simple(
          title: 'Select Genre',
          items: genres,
          selectedKey: filter.selectedGenre,
          onSelected: (genre) {
            ref
                .read(eventsFilterProvider(widget.scopeKey).notifier)
                .setGenreFilter(genre);
          },
        ),
      );
    });
  }

}

/// Widget that loads venue info and renders EventCard
class _EventCardWithVenue extends ConsumerWidget {
  final EventsTableData event;
  final String basePath;

  const _EventCardWithVenue({
    required this.event,
    this.basePath = '/events',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final database = ref.watch(appDatabaseProvider);

    return FutureBuilder<VenuesTableData?>(
      future: event.venueId != null
          ? database.venueDao.getVenueById(event.venueId!)
          : Future.value(null),
      builder: (context, snapshot) {
        final venue = snapshot.data;
        return EventCard(
          event: event,
          startTime: event.startTime,
          doorsTime: event.doorsTime,
          title: event.title,
          minPrice: event.minPrice,
          maxPrice: event.maxPrice,
          priceTier: event.priceTier,
          imageUrl: event.imageUrl,
          ageRestriction: event.ageRestriction,
          venueName: venue?.name,
          neighborhood: venue?.neighborhood,
          onTap: () => context.go('$basePath/${event.id}'),
        );
      },
    );
  }
}

/// Providers for watching distinct filter options
final _watchVenuesProvider =
    StreamProvider<List<VenuesTableData>>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return database.venueDao.watchVenues();
});

final _watchGenresProvider = StreamProvider<List<String>>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return database.eventDao.watchDistinctGenres();
});

