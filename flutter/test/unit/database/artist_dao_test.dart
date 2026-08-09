import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:district_live/core/database/app_database.dart';

void main() {
  group('ArtistDao', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('upsertArtists inserts artists', () async {
      final artists = [
        ArtistsTableCompanion(
          id: Value('artist-1'),
          name: Value('The Beatles'),
          slug: Value('the-beatles'),
          genres: Value('Rock|||Pop'),
        ),
        ArtistsTableCompanion(
          id: Value('artist-2'),
          name: Value('Miles Davis'),
          slug: Value('miles-davis'),
          genres: Value('Jazz'),
        ),
      ];

      await db.artistDao.upsertArtists(artists);

      final result = await db.select(db.artistsTable).get();
      expect(result.length, 2);
      expect(result[0].name, 'The Beatles');
      expect(result[1].name, 'Miles Davis');
    });

    test('upsertArtists updates existing artist', () async {
      final artist = ArtistsTableCompanion(
        id: Value('artist-1'),
        name: Value('Original Name'),
        slug: Value('original-name'),
      );

      await db.artistDao.upsertArtists([artist]);

      final updated = ArtistsTableCompanion(
        id: Value('artist-1'),
        name: Value('Updated Name'),
        slug: Value('updated-name'),
        genres: Value('Rock|||Soul'),
      );

      await db.artistDao.upsertArtists([updated]);

      final result = await db.select(db.artistsTable).get();
      expect(result.length, 1);
      expect(result[0].name, 'Updated Name');
      expect(result[0].genres, 'Rock|||Soul');
    });

    test('getArtistById returns single artist', () async {
      final artist = ArtistsTableCompanion(
        id: Value('artist-1'),
        name: Value('The Beatles'),
        slug: Value('the-beatles'),
        genres: Value('Rock'),
      );

      await db.artistDao.upsertArtists([artist]);

      final result = await db.artistDao.getArtistById('artist-1');
      expect(result, isNotNull);
      expect(result?.name, 'The Beatles');
      expect(result?.genres, 'Rock');
    });

    test('getArtistById returns null for non-existent artist', () async {
      final result = await db.artistDao.getArtistById('non-existent');
      expect(result, isNull);
    });

    test('watchArtists returns stream of artists', () async {
      final artists = [
        ArtistsTableCompanion(
          id: Value('artist-1'),
          name: Value('The Beatles'),
          slug: Value('the-beatles'),
        ),
        ArtistsTableCompanion(
          id: Value('artist-2'),
          name: Value('Miles Davis'),
          slug: Value('miles-davis'),
        ),
      ];

      await db.artistDao.upsertArtists(artists);

      final result = await db.artistDao.watchArtists().first;
      expect(result.length, 2);
      // Should be sorted by name
      expect(result[0].name, 'Miles Davis');
      expect(result[1].name, 'The Beatles');
    });

    test('watchArtists returns empty list initially', () async {
      final result = await db.artistDao.watchArtists().first;
      expect(result.length, 0);
    });
  });
}
