import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:district_live/core/database/app_database.dart';

void main() {
  group('VenueDao', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('upsertVenues inserts venues', () async {
      final venues = [
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
      ];

      await db.venueDao.upsertVenues(venues);

      final result = await db.select(db.venuesTable).get();
      expect(result.length, 2);
      expect(result[0].name, 'The Fillmore');
      expect(result[1].name, '9:30 Club');
    });

    test('upsertVenues updates existing venue', () async {
      final venue = VenuesTableCompanion(
        id: Value('venue-1'),
        name: Value('Original Name'),
        slug: Value('original-name'),
        neighborhood: Value('Downtown'),
      );

      await db.venueDao.upsertVenues([venue]);

      final updated = VenuesTableCompanion(
        id: Value('venue-1'),
        name: Value('Updated Name'),
        slug: Value('updated-name'),
        neighborhood: Value('Capitol Hill'),
        upcomingEventCount: Value(5),
      );

      await db.venueDao.upsertVenues([updated]);

      final result = await db.select(db.venuesTable).get();
      expect(result.length, 1);
      expect(result[0].name, 'Updated Name');
      expect(result[0].neighborhood, 'Capitol Hill');
      expect(result[0].upcomingEventCount, 5);
    });

    test('getVenueById returns single venue', () async {
      final venue = VenuesTableCompanion(
        id: Value('venue-1'),
        name: Value('The Fillmore'),
        slug: Value('the-fillmore'),
        neighborhood: Value('Downtown'),
      );

      await db.venueDao.upsertVenues([venue]);

      final result = await db.venueDao.getVenueById('venue-1');
      expect(result, isNotNull);
      expect(result?.name, 'The Fillmore');
      expect(result?.neighborhood, 'Downtown');
    });

    test('getVenueById returns null for non-existent venue', () async {
      final result = await db.venueDao.getVenueById('non-existent');
      expect(result, isNull);
    });

    test('watchVenues returns stream of all venues', () async {
      final venues = [
        VenuesTableCompanion(
          id: Value('venue-1'),
          name: Value('The Fillmore'),
          slug: Value('the-fillmore'),
        ),
        VenuesTableCompanion(
          id: Value('venue-2'),
          name: Value('9:30 Club'),
          slug: Value('930-club'),
        ),
      ];

      await db.venueDao.upsertVenues(venues);

      final result = await db.venueDao.watchVenues().first;
      expect(result.length, 2);
      // Should be sorted by name
      expect(result[0].name, '9:30 Club');
      expect(result[1].name, 'The Fillmore');
    });

    test('watchVenues filters by neighborhood', () async {
      final venues = [
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
      ];

      await db.venueDao.upsertVenues(venues);

      final result = await db.venueDao
          .watchVenues(neighborhood: 'Downtown')
          .first;
      expect(result.length, 2);
      expect(result[0].name, 'Another Downtown Venue');
      expect(result[1].name, 'The Fillmore');
    });

    test('watchDistinctNeighborhoods returns sorted neighborhoods', () async {
      final venues = [
        VenuesTableCompanion(
          id: Value('venue-1'),
          name: Value('Venue 1'),
          slug: Value('venue-1'),
          neighborhood: Value('Downtown'),
        ),
        VenuesTableCompanion(
          id: Value('venue-2'),
          name: Value('Venue 2'),
          slug: Value('venue-2'),
          neighborhood: Value('Capitol Hill'),
        ),
        VenuesTableCompanion(
          id: Value('venue-3'),
          name: Value('Venue 3'),
          slug: Value('venue-3'),
          neighborhood: Value('Dupont Circle'),
        ),
        VenuesTableCompanion(
          id: Value('venue-4'),
          name: Value('Venue 4'),
          slug: Value('venue-4'),
          neighborhood: Value('Downtown'),
        ),
      ];

      await db.venueDao.upsertVenues(venues);

      final result = await db.venueDao
          .watchDistinctNeighborhoods()
          .first;
      expect(result.length, 3);
      expect(result, [
        'Capitol Hill',
        'Downtown',
        'Dupont Circle',
      ]);
    });

    test('watchDistinctNeighborhoods excludes null neighborhoods', () async {
      final venues = [
        VenuesTableCompanion(
          id: Value('venue-1'),
          name: Value('Venue 1'),
          slug: Value('venue-1'),
          neighborhood: Value('Downtown'),
        ),
        VenuesTableCompanion(
          id: Value('venue-2'),
          name: Value('Venue 2'),
          slug: Value('venue-2'),
          // No neighborhood specified (null)
        ),
      ];

      await db.venueDao.upsertVenues(venues);

      final result = await db.venueDao
          .watchDistinctNeighborhoods()
          .first;
      expect(result.length, 1);
      expect(result[0], 'Downtown');
    });
  });
}
