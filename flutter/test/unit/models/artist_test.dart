import 'package:flutter_test/flutter_test.dart';
import 'package:district_live/features/events/domain/artist.dart';

void main() {
  group('Artist JSON serialization', () {
    final testArtist = const Artist(
      id: 'artist-1',
      name: 'The National',
      slug: 'the-national',
      genres: ['Rock', 'Indie', 'Alternative'],
      isLocal: false,
      spotifyUrl: 'https://open.spotify.com/artist/123',
      bandcampUrl: 'https://theational.bandcamp.com',
      instagramUrl: 'https://instagram.com/thenational',
      canonicalName: 'The National',
      imageUrl: 'https://example.com/artist.jpg',
    );

    test('Artist round-trip: full object', () {
      final json = testArtist.toJson();
      final reconstructed = Artist.fromJson(json);

      expect(reconstructed, equals(testArtist));
    });

    test('Artist round-trip: minimal object', () {
      final minimal = const Artist(
        id: 'artist-2',
        name: 'Local Band',
        slug: 'local-band',
      );

      final json = minimal.toJson();
      final reconstructed = Artist.fromJson(json);

      expect(reconstructed.id, equals('artist-2'));
      expect(reconstructed.name, equals('Local Band'));
      expect(reconstructed.genres, isEmpty);
      expect(reconstructed.isLocal, isFalse);
      expect(reconstructed.spotifyUrl, isNull);
    });

    test('Artist round-trip: null optional fields', () {
      final withNulls = const Artist(
        id: 'artist-3',
        name: 'Artist with Nulls',
        slug: 'artist-with-nulls',
        genres: [],
        isLocal: true,
        spotifyUrl: null,
        bandcampUrl: null,
        instagramUrl: null,
        canonicalName: null,
        imageUrl: null,
      );

      final json = withNulls.toJson();
      final reconstructed = Artist.fromJson(json);

      expect(reconstructed.spotifyUrl, isNull);
      expect(reconstructed.bandcampUrl, isNull);
      expect(reconstructed.instagramUrl, isNull);
      expect(reconstructed.canonicalName, isNull);
      expect(reconstructed.imageUrl, isNull);
      expect(reconstructed.isLocal, isTrue);
    });

    test('Artist genres list serialization', () {
      final json = testArtist.toJson();
      expect(json['genres'], equals(['Rock', 'Indie', 'Alternative']));

      final reconstructed = Artist.fromJson(json);
      expect(reconstructed.genres, equals(['Rock', 'Indie', 'Alternative']));
    });

    test('Artist with empty genres', () {
      final noGenres = const Artist(
        id: 'artist-4',
        name: 'No Genre Artist',
        slug: 'no-genre',
        genres: [],
      );

      final json = noGenres.toJson();
      final reconstructed = Artist.fromJson(json);

      expect(reconstructed.genres, isEmpty);
    });

    test('Artist isLocal boolean serialization', () {
      final local = const Artist(
        id: 'local-artist',
        name: 'DC Local',
        slug: 'dc-local',
        isLocal: true,
      );

      final json = local.toJson();
      expect(json['isLocal'], isTrue);

      final reconstructed = Artist.fromJson(json);
      expect(reconstructed.isLocal, isTrue);
    });
  });
}
