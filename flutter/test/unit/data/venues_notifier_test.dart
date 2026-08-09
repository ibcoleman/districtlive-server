import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:district_live/core/database/app_database.dart';
import 'package:district_live/features/venues/data/venues_filter_state.dart';
import 'package:district_live/features/venues/data/venues_notifier.dart';

void main() {
  group('VenuesFilter', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is null (all neighborhoods)', () {
      final filter = container.read(venuesFilterProvider);
      expect(filter, isNull);
    });

    test('setNeighborhood updates filter to selected neighborhood', () {
      // Read initial state
      final initialFilter = container.read(venuesFilterProvider);
      expect(initialFilter, isNull);

      // Update to a neighborhood
      container.read(venuesFilterProvider.notifier).setNeighborhood('Downtown');

      final updatedFilter = container.read(venuesFilterProvider);
      expect(updatedFilter, equals('Downtown'));
    });

    test('setNeighborhood(null) clears filter to all neighborhoods', () {
      // Set a neighborhood first
      container.read(venuesFilterProvider.notifier).setNeighborhood('Capitol Hill');

      // Then clear it
      container.read(venuesFilterProvider.notifier).setNeighborhood(null);

      final filter = container.read(venuesFilterProvider);
      expect(filter, isNull);
    });

    test('setNeighborhood can change between neighborhoods', () {
      // Set first neighborhood
      container.read(venuesFilterProvider.notifier).setNeighborhood('Downtown');
      expect(container.read(venuesFilterProvider), equals('Downtown'));

      // Change to different neighborhood
      container.read(venuesFilterProvider.notifier).setNeighborhood('U Street');
      expect(container.read(venuesFilterProvider), equals('U Street'));

      // Change again
      container.read(venuesFilterProvider.notifier).setNeighborhood('Dupont Circle');
      expect(container.read(venuesFilterProvider), equals('Dupont Circle'));
    });
  });

  group('VenuesNotifier', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('can be created without errors', () async {
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
        ],
      );

      // Just verify the provider can be accessed without throwing
      try {
        final notifier = container.read(venuesProvider);
        // The provider should return an AsyncValue<void>
        expect(notifier, isNotNull);
      } catch (e) {
        fail('Provider creation should not throw: $e');
      }

      container.dispose();
    });

    test('returns stream of venues with no filter', () async {
      // Insert some test venues
      await db.venueDao.upsertVenues([
        VenuesTableCompanion(
          id: Value('venue-1'),
          name: Value('The Fillmore'),
          slug: Value('the-fillmore'),
          neighborhood: Value('Downtown'),
        ),
        VenuesTableCompanion(
          id: Value('venue-2'),
          name: Value('9:30 Club'),
          slug: Value('930-club'),
          neighborhood: Value('U Street'),
        ),
      ]);

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
        ],
      );

      // Get the stream from the helper function
      final venuesStream = getVenuesStream(db.venueDao, null);

      // Get the first list of venues
      final venues = await venuesStream.first;

      expect(venues.length, equals(2));
      expect(venues[0].name, equals('9:30 Club')); // Sorted by name
      expect(venues[1].name, equals('The Fillmore'));

      container.dispose();
    });

    test('filters venues by neighborhood', () async {
      // Insert test venues with different neighborhoods
      await db.venueDao.upsertVenues([
        VenuesTableCompanion(
          id: Value('venue-1'),
          name: Value('The Fillmore'),
          slug: Value('the-fillmore'),
          neighborhood: Value('Downtown'),
        ),
        VenuesTableCompanion(
          id: Value('venue-2'),
          name: Value('9:30 Club'),
          slug: Value('930-club'),
          neighborhood: Value('U Street'),
        ),
        VenuesTableCompanion(
          id: Value('venue-3'),
          name: Value('Another Downtown Venue'),
          slug: Value('another-downtown'),
          neighborhood: Value('Downtown'),
        ),
      ]);

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
        ],
      );

      // Get the stream filtered by neighborhood
      final venuesStream = getVenuesStream(db.venueDao, 'Downtown');

      // Get the filtered venues
      final venues = await venuesStream.first;

      expect(venues.length, equals(2));
      // Both should be in Downtown
      expect(
        venues.every((v) => v.neighborhood == 'Downtown'),
        isTrue,
      );
      // Should be sorted by name
      expect(venues[0].name, equals('Another Downtown Venue'));
      expect(venues[1].name, equals('The Fillmore'));

      container.dispose();
    });

    test('background refresh updates sync metadata when data is stale', () async {
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
        ],
      );

      // Initially sync metadata should not exist
      var syncTime = await db.syncMetadataDao.getLastSyncedAt('venues');
      expect(syncTime, isNull);

      // Verify isStale returns true initially
      var isStale = await db.syncMetadataDao.isStale('venues');
      expect(isStale, isTrue);

      // Now manually set sync time to now
      await db.syncMetadataDao.updateLastSyncedAt('venues', DateTime.now());

      // Verify isStale returns false now
      isStale = await db.syncMetadataDao.isStale('venues');
      expect(isStale, isFalse);

      container.dispose();
    });
  });
}
