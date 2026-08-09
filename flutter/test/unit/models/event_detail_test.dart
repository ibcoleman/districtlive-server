import 'package:flutter_test/flutter_test.dart';
import 'package:district_live/features/events/domain/event_detail.dart';
import 'package:district_live/features/events/domain/event.dart';
import 'package:district_live/features/events/domain/event_source.dart';
import 'package:district_live/features/events/domain/artist.dart';
import 'package:district_live/features/events/domain/enums.dart';
import 'package:district_live/features/venues/domain/venue.dart';

void main() {
  group('EventDetail JSON serialization', () {
    final testVenue = const Venue(
      id: 'venue-1',
      name: 'The Anthem',
      slug: 'the-anthem',
      neighborhood: 'Southwest DC',
    );

    final testArtist = const Artist(
      id: 'artist-1',
      name: 'The National',
      slug: 'the-national',
    );

    final testSource = const EventSource(
      sourceType: SourceType.TICKETMASTER_API,
      lastScrapedAt: null,
    );

    final relatedEvent = Event(
      id: 'related-1',
      title: 'Related Concert',
      slug: 'related-concert',
      startTime: DateTime.parse('2026-03-20T20:00:00Z'),
    );

    final testEventDetail = EventDetail(
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
      endTime: DateTime.parse('2026-03-15T23:00:00Z'),
      onSaleDate: DateTime.parse('2026-01-01T00:00:00Z'),
      ticketPlatform: 'Ticketmaster',
      sources: [testSource],
      relatedEvents: [relatedEvent],
    );

    test('EventDetail round-trip: full object', () {
      final json = testEventDetail.toJson();
      final reconstructed = EventDetail.fromJson(json);

      expect(reconstructed, equals(testEventDetail));
    });

    test('EventDetail round-trip: minimal object', () {
      final minimal = EventDetail(
        id: 'event-2',
        title: 'Minimal Event',
        slug: 'minimal',
        startTime: DateTime.parse('2026-03-15T20:00:00Z'),
      );

      final json = minimal.toJson();
      final reconstructed = EventDetail.fromJson(json);

      expect(reconstructed.id, equals('event-2'));
      expect(reconstructed.title, equals('Minimal Event'));
      expect(reconstructed.endTime, isNull);
      expect(reconstructed.onSaleDate, isNull);
      expect(reconstructed.ticketPlatform, isNull);
      expect(reconstructed.sources, isEmpty);
      expect(reconstructed.relatedEvents, isEmpty);
    });

    test('EventDetail includes all Event fields', () {
      final json = testEventDetail.toJson();

      expect(json['id'], equals('event-1'));
      expect(json['title'], equals('The National Live'));
      expect(json['description'], equals('An amazing live performance'));
      expect(json['startTime'], equals('2026-03-15T20:00:00.000Z'));
    });

    test('EventDetail-specific fields', () {
      final json = testEventDetail.toJson();

      expect(json['endTime'], equals('2026-03-15T23:00:00.000Z'));
      expect(json['onSaleDate'], equals('2026-01-01T00:00:00.000Z'));
      expect(json['ticketPlatform'], equals('Ticketmaster'));
      expect(json['sources'], isNotEmpty);
      expect(json['relatedEvents'], isNotEmpty);
    });

    test('EventDetail sources list serialization', () {
      final json = testEventDetail.toJson();
      final sourcesList = json['sources'] as List;

      expect(sourcesList, isNotEmpty);
      expect(sourcesList.first['sourceType'], equals('TICKETMASTER_API'));
    });

    test('EventDetail relatedEvents list serialization', () {
      final json = testEventDetail.toJson();
      final relatedList = json['relatedEvents'] as List;

      expect(relatedList, isNotEmpty);
      expect(relatedList.first['title'], equals('Related Concert'));
    });

    test('EventDetail with null detail-specific fields', () {
      final withNulls = EventDetail(
        id: 'event-3',
        title: 'Event with Nulls',
        slug: 'event-with-nulls',
        startTime: DateTime.parse('2026-03-15T20:00:00Z'),
        endTime: null,
        onSaleDate: null,
        ticketPlatform: null,
        sources: [],
        relatedEvents: [],
      );

      final json = withNulls.toJson();
      final reconstructed = EventDetail.fromJson(json);

      expect(reconstructed.endTime, isNull);
      expect(reconstructed.onSaleDate, isNull);
      expect(reconstructed.ticketPlatform, isNull);
      expect(reconstructed.sources, isEmpty);
      expect(reconstructed.relatedEvents, isEmpty);
    });

    test('EventDetail datetime fields round-trip', () {
      final json = testEventDetail.toJson();

      expect(json['startTime'], equals('2026-03-15T20:00:00.000Z'));
      expect(json['endTime'], equals('2026-03-15T23:00:00.000Z'));
      expect(json['onSaleDate'], equals('2026-01-01T00:00:00.000Z'));

      final reconstructed = EventDetail.fromJson(json);
      expect(reconstructed.startTime,
          equals(DateTime.parse('2026-03-15T20:00:00Z')));
      expect(reconstructed.endTime,
          equals(DateTime.parse('2026-03-15T23:00:00Z')));
      expect(reconstructed.onSaleDate,
          equals(DateTime.parse('2026-01-01T00:00:00Z')));
    });
  });
}
