import 'package:flutter_test/flutter_test.dart';
import 'package:district_live/features/events/domain/event.dart';
import 'package:district_live/features/events/domain/artist.dart';
import 'package:district_live/features/events/domain/enums.dart';
import 'package:district_live/features/venues/domain/venue.dart';
import 'package:district_live/features/featured/domain/event_scoring.dart';

void main() {
  group('Event Scoring', () {
    group('scoreEvent()', () {
      final baseEvent = Event(
        id: 'test-1',
        title: 'Test Event',
        slug: 'test-event',
        startTime: DateTime.parse('2026-03-15T20:00:00Z'),
      );

      test('Event with no optional fields scores 0', () {
        expect(scoreEvent(baseEvent), equals(0));
      });

      test('Event with all fields populated scores 10', () {
        final venue = const Venue(
          id: 'venue-1',
          name: 'The Anthem',
          slug: 'the-anthem',
          neighborhood: 'Southwest DC',
        );

        final artist = const Artist(
          id: 'artist-1',
          name: 'The National',
          slug: 'the-national',
        );

        final fullEvent = Event(
          id: 'event-1',
          title: 'Full Event',
          slug: 'full-event',
          startTime: DateTime.parse('2026-03-15T20:00:00Z'),
          imageUrl: 'https://example.com/image.jpg',
          description: 'A great event',
          venue: venue,
          artists: [artist],
          minPrice: 50.0,
          ticketUrl: 'https://example.com/tickets',
        );

        expect(scoreEvent(fullEvent), equals(10));
      });

      test('imageUrl presence adds 3 points', () {
        final eventWithImage = baseEvent.copyWith(
          imageUrl: 'https://example.com/image.jpg',
        );
        expect(scoreEvent(eventWithImage), equals(3));
      });

      test('description presence adds 2 points', () {
        final eventWithDesc = baseEvent.copyWith(
          description: 'A great event',
        );
        expect(scoreEvent(eventWithDesc), equals(2));
      });

      test('venue presence adds 1 point', () {
        final venue = const Venue(
          id: 'venue-1',
          name: 'The Anthem',
          slug: 'the-anthem',
        );
        final eventWithVenue = baseEvent.copyWith(venue: venue);
        expect(scoreEvent(eventWithVenue), equals(1));
      });

      test('venue with neighborhood adds 2 points total', () {
        final venue = const Venue(
          id: 'venue-1',
          name: 'The Anthem',
          slug: 'the-anthem',
          neighborhood: 'Southwest DC',
        );
        final eventWithVenue = baseEvent.copyWith(venue: venue);
        expect(scoreEvent(eventWithVenue), equals(2));
      });

      test('minPrice presence adds 1 point', () {
        final eventWithMinPrice = baseEvent.copyWith(minPrice: 50.0);
        expect(scoreEvent(eventWithMinPrice), equals(1));
      });

      test('priceTier presence adds 1 point', () {
        final eventWithPriceTier = baseEvent.copyWith(
          priceTier: PriceTier.PRICE_15_TO_30,
        );
        expect(scoreEvent(eventWithPriceTier), equals(1));
      });

      test('ticketUrl presence adds 1 point', () {
        final eventWithTicket = baseEvent.copyWith(
          ticketUrl: 'https://example.com/tickets',
        );
        expect(scoreEvent(eventWithTicket), equals(1));
      });

      test('artists presence adds 1 point', () {
        final artist = const Artist(
          id: 'artist-1',
          name: 'The National',
          slug: 'the-national',
        );
        final eventWithArtists = baseEvent.copyWith(artists: [artist]);
        expect(scoreEvent(eventWithArtists), equals(1));
      });

      test('empty artists list does not add points', () {
        final eventWithEmptyArtists = baseEvent.copyWith(artists: []);
        expect(scoreEvent(eventWithEmptyArtists), equals(0));
      });
    });

    group('pickFallbackHero()', () {
      test('empty list returns null', () {
        expect(pickFallbackHero([]), isNull);
      });

      test('single event list returns that event', () {
        final baseEvent = Event(
          id: 'test-1',
          title: 'Test Event',
          slug: 'test-event',
          startTime: DateTime.parse('2026-03-15T20:00:00Z'),
        );

        final result = pickFallbackHero([baseEvent]);
        expect(result, equals(baseEvent));
      });

      test('single highest-scored event returns that event', () {
        final venue = const Venue(
          id: 'venue-1',
          name: 'The Anthem',
          slug: 'the-anthem',
          neighborhood: 'Southwest DC',
        );

        final highScoredEvent = Event(
          id: 'event-high',
          title: 'High Scored Event',
          slug: 'high-scored-event',
          startTime: DateTime.parse('2026-03-15T20:00:00Z'),
          imageUrl: 'https://example.com/image.jpg',
          description: 'A great event',
          venue: venue,
        );

        final lowScoredEvent = Event(
          id: 'event-low',
          title: 'Low Scored Event',
          slug: 'low-scored-event',
          startTime: DateTime.parse('2026-03-16T20:00:00Z'),
        );

        final result = pickFallbackHero([lowScoredEvent, highScoredEvent]);
        expect(result, equals(highScoredEvent));
      });

      test('two events with same score returns second', () {
        final venue1 = const Venue(
          id: 'venue-1',
          name: 'The Anthem',
          slug: 'the-anthem',
        );

        final venue2 = const Venue(
          id: 'venue-2',
          name: 'Black Cat',
          slug: 'black-cat',
        );

        // Both events score 1 (venue presence only)
        final event1 = Event(
          id: 'event-1',
          title: 'Event 1',
          slug: 'event-1',
          startTime: DateTime.parse('2026-03-15T20:00:00Z'),
          venue: venue1,
        );

        final event2 = Event(
          id: 'event-2',
          title: 'Event 2',
          slug: 'event-2',
          startTime: DateTime.parse('2026-03-15T20:00:00Z'),
          venue: venue2,
        );

        expect(scoreEvent(event1), equals(scoreEvent(event2)));
        expect(scoreEvent(event1), equals(1));

        final result = pickFallbackHero([event1, event2]);
        expect(result, equals(event2));
      });

      test('multiple events with equal top score returns second', () {
        final venue = const Venue(
          id: 'venue-1',
          name: 'The Anthem',
          slug: 'the-anthem',
          neighborhood: 'Southwest DC',
        );

        // All score 2 (venue + neighborhood)
        final event1 = Event(
          id: 'event-1',
          title: 'Event 1',
          slug: 'event-1',
          startTime: DateTime.parse('2026-03-15T20:00:00Z'),
          venue: venue,
        );

        final event2 = Event(
          id: 'event-2',
          title: 'Event 2',
          slug: 'event-2',
          startTime: DateTime.parse('2026-03-15T20:00:00Z'),
          venue: venue,
        );

        final event3 = Event(
          id: 'event-3',
          title: 'Event 3',
          slug: 'event-3',
          startTime: DateTime.parse('2026-03-15T20:00:00Z'),
          venue: venue,
        );

        expect(scoreEvent(event1), equals(2));
        expect(scoreEvent(event2), equals(2));
        expect(scoreEvent(event3), equals(2));

        final result = pickFallbackHero([event1, event2, event3]);
        expect(result, equals(event2));
      });

      test('different scores returns highest', () {
        final venue = const Venue(
          id: 'venue-1',
          name: 'The Anthem',
          slug: 'the-anthem',
          neighborhood: 'Southwest DC',
        );

        // Score 2
        final event1 = Event(
          id: 'event-1',
          title: 'Event 1',
          slug: 'event-1',
          startTime: DateTime.parse('2026-03-15T20:00:00Z'),
          venue: venue,
        );

        // Score 3
        final event2 = Event(
          id: 'event-2',
          title: 'Event 2',
          slug: 'event-2',
          startTime: DateTime.parse('2026-03-15T20:00:00Z'),
          imageUrl: 'https://example.com/image.jpg',
          venue: venue,
        );

        // Score 1
        final event3 = Event(
          id: 'event-3',
          title: 'Event 3',
          slug: 'event-3',
          startTime: DateTime.parse('2026-03-15T20:00:00Z'),
        );

        final result = pickFallbackHero([event3, event1, event2]);
        expect(result, equals(event2));
      });

      test('stability: maintains order when all scores identical', () {
        // Create 3 events with identical structure (all score 0)
        final events = List.generate(
          3,
          (i) => Event(
            id: 'event-$i',
            title: 'Event $i',
            slug: 'event-$i',
            startTime: DateTime.parse('2026-03-15T20:00:00Z'),
          ),
        );

        final result = pickFallbackHero(events);
        // Should return second (index 1)
        expect(result?.id, equals('event-1'));
      });
    });
  });
}
