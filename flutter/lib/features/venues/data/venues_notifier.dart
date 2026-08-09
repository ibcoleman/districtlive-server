import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drift/drift.dart' show Value;
import 'package:district_live/core/database/app_database.dart';
import 'package:district_live/core/database/sync_metadata_dao.dart';
import 'package:district_live/features/venues/data/venues_api.dart';
import 'package:district_live/features/venues/data/venue_dao.dart';

part 'venues_notifier.g.dart';

/// Helper function to get the venues stream with the current neighborhood filter.
/// This directly accesses the DAO stream and will update when venues change in the cache.
Stream<List<VenuesTableData>> getVenuesStream(
  VenueDao venueDao,
  String? neighborhood,
) {
  return venueDao.watchVenues(neighborhood: neighborhood);
}

/// Helper function to create VenuesTableCompanion from API venue data.
/// Used by both background and explicit refresh operations.
List<VenuesTableCompanion> _createVenueCompanions(List<dynamic> apiVenues) {
  return apiVenues.map((venue) {
    return VenuesTableCompanion(
      id: Value(venue.id),
      name: Value(venue.name),
      slug: Value(venue.slug),
      neighborhood: Value(venue.neighborhood),
      upcomingEventCount: Value(venue.upcomingEventCount),
    );
  }).toList();
}

/// Helper function to refresh venues from the network if stale.
/// Performs cache-first background refresh.
Future<void> refreshVenuesInBackground(
  VenueDao venueDao,
  SyncMetadataDao syncMetadataDao,
  VenuesApi venuesApi,
) async {
  try {
    // Check staleness
    final isStale = await syncMetadataDao.isStale('venues');
    if (!isStale) {
      return; // Cache is fresh, skip refresh
    }

    // Fetch all venues from API (page 0, large size)
    final response = await venuesApi.getVenues(page: 0, size: 200);

    // Prepare companions for upsert
    final companions = _createVenueCompanions(response.content);

    // Upsert venues into Drift
    if (companions.isNotEmpty) {
      await venueDao.upsertVenues(companions);
    }

    // Update sync metadata
    await syncMetadataDao.updateLastSyncedAt('venues', DateTime.now());
  } catch (e) {
    // Silently fail on background refresh — cached data is still shown
    // This allows the UI to remain functional even if the network fails
  }
}

/// Venues notifier that provides cache-first loading with background refresh.
/// Watches neighborhood filter and schedules background refresh on build.
/// Provides a manual refresh() method for pull-to-refresh functionality.
@riverpod
class VenuesNotifier extends _$VenuesNotifier {
  late VenueDao _venueDao;
  late SyncMetadataDao _syncMetadataDao;
  late VenuesApi _venuesApi;

  @override
  Future<void> build() async {
    // Get DAOs and API from refs
    final database = ref.watch(appDatabaseProvider);
    _venueDao = database.venueDao;
    _syncMetadataDao = database.syncMetadataDao;
    _venuesApi = ref.watch(venuesApiProvider);

    // Schedule background refresh on build
    unawaited(Future.microtask(() => refreshVenuesInBackground(
      _venueDao,
      _syncMetadataDao,
      _venuesApi,
    )));
  }

  /// Manually refresh venues from API regardless of staleness.
  /// Can be called for pull-to-refresh or explicit refresh actions.
  Future<void> refresh() async {
    // Fetch all venues from API (page 0, large size)
    final response = await _venuesApi.getVenues(page: 0, size: 200);

    // Prepare companions for upsert
    final companions = _createVenueCompanions(response.content);

    // Upsert venues into Drift
    if (companions.isNotEmpty) {
      await _venueDao.upsertVenues(companions);
    }

    // Update sync metadata
    await _syncMetadataDao.updateLastSyncedAt('venues', DateTime.now());
  }
}
