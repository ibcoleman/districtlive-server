import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:district_live/core/database/app_database.dart';

void main() {
  group('EventDao', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('upsertEvents inserts and updates events', () async {
      final event1 = EventsTableCompanion(
        id: Value('event-1'),
        title: Value('Concert Night'),
        slug: Value('concert-night'),
        startTime: Value(DateTime(2026, 3, 15, 20, 0)),
      );

      final event2 = EventsTableCompanion(
        id: Value('event-2'),
        title: Value('Jazz Session'),
        slug: Value('jazz-session'),
        startTime: Value(DateTime(2026, 3, 16, 19, 0)),
      );

      await db.eventDao.upsertEvents([event1, event2]);

      final events = await db.select(db.eventsTable).get();
      expect(events.length, 2);
      expect(events[0].title, 'Concert Night');
      expect(events[1].title, 'Jazz Session');
    });

    test('upsertEvents updates existing event', () async {
      final event1 = EventsTableCompanion(
        id: Value('event-1'),
        title: Value('Original Title'),
        slug: Value('original-title'),
        startTime: Value(DateTime(2026, 3, 15, 20, 0)),
      );

      await db.eventDao.upsertEvents([event1]);

      final event1Updated = EventsTableCompanion(
        id: Value('event-1'),
        title: Value('Updated Title'),
        slug: Value('updated-title'),
        startTime: Value(DateTime(2026, 3, 15, 21, 0)),
      );

      await db.eventDao.upsertEvents([event1Updated]);

      final events = await db.select(db.eventsTable).get();
      expect(events.length, 1);
      expect(events[0].title, 'Updated Title');
    });

    test('watchEvents returns stream of events', () async {
      final event = EventsTableCompanion(
        id: Value('event-1'),
        title: Value('Concert'),
        slug: Value('concert'),
        startTime: Value(DateTime(2026, 3, 15, 20, 0)),
      );

      await db.eventDao.upsertEvents([event]);

      final eventStream = db.eventDao.watchEvents();
      expect(
        eventStream,
        emits(isA<List<EventsTableData>>().having(
          (list) => list.length,
          'length',
          1,
        )),
      );
    });

    test('watchEvents filters by venueId', () async {
      final event1 = EventsTableCompanion(
        id: Value('event-1'),
        title: Value('Concert 1'),
        slug: Value('concert-1'),
        startTime: Value(DateTime(2026, 3, 15, 20, 0)),
        venueId: Value('venue-1'),
      );

      final event2 = EventsTableCompanion(
        id: Value('event-2'),
        title: Value('Concert 2'),
        slug: Value('concert-2'),
        startTime: Value(DateTime(2026, 3, 16, 20, 0)),
        venueId: Value('venue-2'),
      );

      await db.eventDao.upsertEvents([event1, event2]);

      final filteredEvents =
          await db.eventDao.watchEvents(venueId: 'venue-1').first;
      expect(filteredEvents.length, 1);
      expect(filteredEvents[0].id, 'event-1');
    });

    test('watchEvents filters by date range', () async {
      final event1 = EventsTableCompanion(
        id: Value('event-1'),
        title: Value('Concert 1'),
        slug: Value('concert-1'),
        startTime: Value(DateTime(2026, 3, 10, 20, 0)),
      );

      final event2 = EventsTableCompanion(
        id: Value('event-2'),
        title: Value('Concert 2'),
        slug: Value('concert-2'),
        startTime: Value(DateTime(2026, 3, 15, 20, 0)),
      );

      final event3 = EventsTableCompanion(
        id: Value('event-3'),
        title: Value('Concert 3'),
        slug: Value('concert-3'),
        startTime: Value(DateTime(2026, 3, 20, 20, 0)),
      );

      await db.eventDao.upsertEvents([event1, event2, event3]);

      final filteredEvents = await db.eventDao
          .watchEvents(
            dateFrom: DateTime(2026, 3, 12),
            dateTo: DateTime(2026, 3, 18),
          )
          .first;

      expect(filteredEvents.length, 1);
      expect(filteredEvents[0].id, 'event-2');
    });

    test('watchEvents respects pagination', () async {
      final events = List.generate(
        25,
        (i) => EventsTableCompanion(
          id: Value('event-$i'),
          title: Value('Concert $i'),
          slug: Value('concert-$i'),
          startTime: Value(DateTime(2026, 3, i + 1, 20, 0)),
        ),
      );

      await db.eventDao.upsertEvents(events);

      final firstPage = await db.eventDao.watchEvents(limit: 10).first;
      expect(firstPage.length, 10);

      final secondPage =
          await db.eventDao.watchEvents(limit: 10, offset: 10).first;
      expect(secondPage.length, 10);
    });

    test('getEventById returns single event', () async {
      final event = EventsTableCompanion(
        id: Value('event-1'),
        title: Value('Concert'),
        slug: Value('concert'),
        startTime: Value(DateTime(2026, 3, 15, 20, 0)),
      );

      await db.eventDao.upsertEvents([event]);

      final result = await db.eventDao.getEventById('event-1');
      expect(result, isNotNull);
      expect(result?.title, 'Concert');
    });

    test('getEventById returns null for non-existent event', () async {
      final result = await db.eventDao.getEventById('non-existent');
      expect(result, isNull);
    });

    test('upsertEventArtists inserts associations', () async {
      await db.eventDao.upsertEventArtists('event-1', ['artist-1', 'artist-2']);

      final associations =
          await db.select(db.eventArtistsTable).get();
      expect(associations.length, 2);
      expect(associations[0].eventId, 'event-1');
      expect(associations[0].artistId, 'artist-1');
    });

    test('upsertEventArtists replaces existing associations', () async {
      await db.eventDao
          .upsertEventArtists('event-1', ['artist-1', 'artist-2']);

      var associations = await db.select(db.eventArtistsTable).get();
      expect(associations.length, 2);

      // Update with new artists
      await db.eventDao.upsertEventArtists('event-1', ['artist-3']);

      associations = await db.select(db.eventArtistsTable).get();
      expect(associations.length, 1);
      expect(associations[0].artistId, 'artist-3');
    });

    test('upsertEventArtists handles empty list', () async {
      await db.eventDao
          .upsertEventArtists('event-1', ['artist-1', 'artist-2']);

      var associations = await db.select(db.eventArtistsTable).get();
      expect(associations.length, 2);

      // Clear artists
      await db.eventDao.upsertEventArtists('event-1', []);

      associations = await db.select(db.eventArtistsTable).get();
      expect(associations.length, 0);
    });

    test('watchDistinctGenres returns sorted unique genres', () async {
      final artists = [
        ArtistsTableCompanion(
          id: Value('artist-1'),
          name: Value('Artist 1'),
          slug: Value('artist-1'),
          genres: Value('Rock|||Alternative|||Indie'),
        ),
        ArtistsTableCompanion(
          id: Value('artist-2'),
          name: Value('Artist 2'),
          slug: Value('artist-2'),
          genres: Value('Jazz|||Blues'),
        ),
        ArtistsTableCompanion(
          id: Value('artist-3'),
          name: Value('Artist 3'),
          slug: Value('artist-3'),
          genres: Value('Rock|||Soul'),
        ),
      ];

      await db.artistDao.upsertArtists(artists);

      final genres = await db.eventDao.watchDistinctGenres().first;
      expect(genres.length, 6);
      expect(genres, [
        'Alternative',
        'Blues',
        'Indie',
        'Jazz',
        'Rock',
        'Soul',
      ]);
    });

    test('watchDistinctGenres excludes empty genre strings', () async {
      final artists = [
        ArtistsTableCompanion(
          id: Value('artist-1'),
          name: Value('Artist 1'),
          slug: Value('artist-1'),
          genres: Value('Rock'),
        ),
        ArtistsTableCompanion(
          id: Value('artist-2'),
          name: Value('Artist 2'),
          slug: Value('artist-2'),
          genres: Value(''),
        ),
      ];

      await db.artistDao.upsertArtists(artists);

      final genres = await db.eventDao.watchDistinctGenres().first;
      expect(genres, ['Rock']);
    });

    test('watchEvents filters by genre', () async {
      final artists = [
        ArtistsTableCompanion(
          id: Value('artist-1'),
          name: Value('Artist 1'),
          slug: Value('artist-1'),
          genres: Value('Rock|||Alternative'),
        ),
        ArtistsTableCompanion(
          id: Value('artist-2'),
          name: Value('Artist 2'),
          slug: Value('artist-2'),
          genres: Value('Jazz|||Blues'),
        ),
      ];

      final events = [
        EventsTableCompanion(
          id: Value('event-1'),
          title: Value('Rock Concert'),
          slug: Value('rock-concert'),
          startTime: Value(DateTime(2026, 3, 15, 20, 0)),
        ),
        EventsTableCompanion(
          id: Value('event-2'),
          title: Value('Jazz Night'),
          slug: Value('jazz-night'),
          startTime: Value(DateTime(2026, 3, 16, 20, 0)),
        ),
      ];

      await db.artistDao.upsertArtists(artists);
      await db.eventDao.upsertEvents(events);
      await db.eventDao.upsertEventArtists('event-1', ['artist-1']);
      await db.eventDao.upsertEventArtists('event-2', ['artist-2']);

      final rockEvents = await db.eventDao.watchEvents(genre: 'Rock').first;
      expect(rockEvents.length, 1);
      expect(rockEvents[0].id, 'event-1');

      final jazzEvents = await db.eventDao.watchEvents(genre: 'Jazz').first;
      expect(jazzEvents.length, 1);
      expect(jazzEvents[0].id, 'event-2');
    });

    test('watchEvents genre filter with SQL injection attempt', () async {
      final artists = [
        ArtistsTableCompanion(
          id: Value('artist-1'),
          name: Value('Artist 1'),
          slug: Value('artist-1'),
          genres: Value("Rock|||O'Reilly"),
        ),
      ];

      final events = [
        EventsTableCompanion(
          id: Value('event-1'),
          title: Value('Test Concert'),
          slug: Value('test-concert'),
          startTime: Value(DateTime(2026, 3, 15, 20, 0)),
        ),
      ];

      await db.artistDao.upsertArtists(artists);
      await db.eventDao.upsertEvents(events);
      await db.eventDao.upsertEventArtists('event-1', ['artist-1']);

      // Test that genre with single quote is properly escaped and doesn't cause errors
      final results = await db.eventDao.watchEvents(genre: "O'Reilly").first;
      expect(results.length, 1);
      expect(results[0].id, 'event-1');
    });
  });
}
