import 'package:flutter_test/flutter_test.dart';
import 'package:district_live/features/events/domain/event.dart';
import 'package:district_live/features/events/domain/artist.dart';
import 'package:district_live/features/events/domain/enums.dart';
import 'package:district_live/features/venues/domain/venue.dart';

void main() {
  group('Event JSON serialization', () {
    final testVenue = const Venue(
      id: 'venue-1',
      name: 'The Anthem',
      slug: 'the-anthem',
      neighborhood: 'Southwest DC',
      websiteUrl: 'https://www.theanthemdc.com',
      upcomingEventCount: 5,
    );

    final testArtist = const Artist(
      id: 'artist-1',
      name: 'The National',
      slug: 'the-national',
      genres: ['Rock', 'Alternative'],
      isLocal: false,
      spotifyUrl: 'https://open.spotify.com/artist/1',
      canonicalName: 'The National',
    );

    final testEvent = Event(
      id: 'event-1',
      title: 'The National Live',
      slug: 'the-national-live',
      startTime: DateTime.parse('2026-03-15T20:00:00Z'),
      doorsTime: DateTime.parse('2026-03-15T19:00:00Z'),
      venue: testVenue,
      artists: [testArtist],
      minPrice: 50.0,
      maxPrice: 75.0,
      priceTier: PriceTier.PRICE_15_TO_30,
      ticketUrl: 'https://example.com/tickets',
      soldOut: false,
      imageUrl: 'https://example.com/image.jpg',
      ageRestriction: AgeRestriction.EIGHTEEN_PLUS,
      status: EventStatus.ACTIVE,
      description: 'An amazing live performance',
    );

    test('Event round-trip: full object with all fields', () {
      final json = testEvent.toJson();
      final reconstructed = Event.fromJson(json);

      expect(reconstructed, equals(testEvent));
    });

    test('Event round-trip: minimal object with defaults', () {
      final minimal = Event(
        id: 'minimal-1',
        title: 'Minimal Event',
        slug: 'minimal-event',
        startTime: DateTime.parse('2026-03-20T19:00:00Z'),
      );

      final json = minimal.toJson();
      final reconstructed = Event.fromJson(json);

      expect(reconstructed.id, equals('minimal-1'));
      expect(reconstructed.title, equals('Minimal Event'));
      expect(reconstructed.startTime, equals(DateTime.parse('2026-03-20T19:00:00Z')));
      expect(reconstructed.artists, isEmpty);
      expect(reconstructed.soldOut, isFalse);
      expect(reconstructed.ageRestriction, equals(AgeRestriction.ALL_AGES));
      expect(reconstructed.status, equals(EventStatus.ACTIVE));
    });

    test('Event round-trip: null optional fields', () {
      final withNulls = Event(
        id: 'event-2',
        title: 'Event with Nulls',
        slug: 'event-with-nulls',
        startTime: DateTime.parse('2026-03-15T20:00:00Z'),
        doorsTime: null,
        venue: null,
        artists: [],
        minPrice: null,
        maxPrice: null,
        ticketUrl: null,
        imageUrl: null,
        description: null,
      );

      final json = withNulls.toJson();
      final reconstructed = Event.fromJson(json);

      expect(reconstructed.doorsTime, isNull);
      expect(reconstructed.venue, isNull);
      expect(reconstructed.minPrice, isNull);
      expect(reconstructed.maxPrice, isNull);
      expect(reconstructed.ticketUrl, isNull);
      expect(reconstructed.imageUrl, isNull);
      expect(reconstructed.description, isNull);
    });

    test('Event includes description field', () {
      final json = testEvent.toJson();
      expect(json['description'], equals('An amazing live performance'));

      final reconstructed = Event.fromJson(json);
      expect(reconstructed.description, equals('An amazing live performance'));
    });

    test('Event description can be null', () {
      final eventNoDesc = Event(
        id: 'event-3',
        title: 'No Description',
        slug: 'no-description',
        startTime: DateTime.parse('2026-03-15T20:00:00Z'),
        description: null,
      );

      final json = eventNoDesc.toJson();
      final reconstructed = Event.fromJson(json);

      expect(reconstructed.description, isNull);
    });

    test('DateTime ISO 8601 round-trip', () {
      final isoString = '2026-03-15T20:30:45Z';
      final dateTime = DateTime.parse(isoString);

      final event = Event(
        id: 'event-4',
        title: 'DateTime Test',
        slug: 'datetime-test',
        startTime: dateTime,
      );

      final json = event.toJson();
      // Drift serializes DateTime with milliseconds (.000Z)
      expect(json['startTime'], equals('2026-03-15T20:30:45.000Z'));

      final reconstructed = Event.fromJson(json);
      expect(reconstructed.startTime, equals(dateTime));
    });

    test('Enum serialization', () {
      final json = testEvent.toJson();

      expect(json['priceTier'], equals('PRICE_15_TO_30'));
      expect(json['ageRestriction'], equals('EIGHTEEN_PLUS'));
      expect(json['status'], equals('ACTIVE'));

      final reconstructed = Event.fromJson(json);
      expect(reconstructed.priceTier, equals(PriceTier.PRICE_15_TO_30));
      expect(reconstructed.ageRestriction, equals(AgeRestriction.EIGHTEEN_PLUS));
      expect(reconstructed.status, equals(EventStatus.ACTIVE));
    });

    test('Nested Artist and Venue serialization', () {
      final json = testEvent.toJson();

      expect(json['venue'], isNotNull);
      expect(json['artists'], isNotEmpty);

      final reconstructed = Event.fromJson(json);
      expect(reconstructed.venue, isNotNull);
      expect(reconstructed.venue!.name, equals('The Anthem'));
      expect(reconstructed.artists, isNotEmpty);
      expect(reconstructed.artists.first.name, equals('The National'));
    });
  });
}
