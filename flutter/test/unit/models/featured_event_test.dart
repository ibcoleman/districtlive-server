import 'package:flutter_test/flutter_test.dart';
import 'package:district_live/features/featured/domain/featured_event.dart';
import 'package:district_live/features/events/domain/event_detail.dart';
import 'package:district_live/features/events/domain/enums.dart';

void main() {
  group('FeaturedEvent JSON serialization', () {
    final testEventDetail = EventDetail(
      id: 'event-1',
      title: 'The National Live',
      slug: 'the-national-live',
      startTime: DateTime.parse('2026-03-15T20:00:00Z'),
      description: 'An amazing performance',
    );

    final testFeaturedEvent = FeaturedEvent(
      id: 'featured-1',
      event: testEventDetail,
      blurb: "Don't miss this incredible show!",
      createdAt: DateTime.parse('2026-01-01T10:00:00Z'),
      createdBy: 'admin@example.com',
    );

    test('FeaturedEvent round-trip: full object', () {
      final json = testFeaturedEvent.toJson();
      final reconstructed = FeaturedEvent.fromJson(json);

      expect(reconstructed, equals(testFeaturedEvent));
    });

    test('FeaturedEvent round-trip: minimal object', () {
      final minimal = FeaturedEvent(
        id: 'featured-2',
        event: EventDetail(
          id: 'event-2',
          title: 'Minimal Event',
          slug: 'minimal',
          startTime: DateTime.parse('2026-03-15T20:00:00Z'),
        ),
        blurb: 'Check this out',
        createdAt: DateTime.parse('2026-01-01T10:00:00Z'),
        createdBy: 'user',
      );

      final json = minimal.toJson();
      final reconstructed = FeaturedEvent.fromJson(json);

      expect(reconstructed.id, equals('featured-2'));
      expect(reconstructed.blurb, equals('Check this out'));
      expect(reconstructed.createdBy, equals('user'));
    });

    test('FeaturedEvent nested EventDetail serialization', () {
      final json = testFeaturedEvent.toJson();

      expect(json['event'], isNotNull);
      expect(json['event']['id'], equals('event-1'));
      expect(json['event']['title'], equals('The National Live'));
    });

    test('FeaturedEvent datetime fields', () {
      final json = testFeaturedEvent.toJson();

      expect(json['createdAt'], equals('2026-01-01T10:00:00.000Z'));

      final reconstructed = FeaturedEvent.fromJson(json);
      expect(
          reconstructed.createdAt,
          equals(DateTime.parse('2026-01-01T10:00:00Z')));
    });

    test('FeaturedEvent blurb and createdBy strings', () {
      final json = testFeaturedEvent.toJson();

      expect(json['blurb'], equals("Don't miss this incredible show!"));
      expect(json['createdBy'], equals('admin@example.com'));

      final reconstructed = FeaturedEvent.fromJson(json);
      expect(reconstructed.blurb, equals("Don't miss this incredible show!"));
      expect(reconstructed.createdBy, equals('admin@example.com'));
    });

    test('FeaturedEvent event field contains full EventDetail', () {
      final json = testFeaturedEvent.toJson();
      final reconstructed = FeaturedEvent.fromJson(json);

      expect(reconstructed.event.id, equals('event-1'));
      expect(reconstructed.event.title, equals('The National Live'));
      expect(reconstructed.event.description,
          equals('An amazing performance'));
      expect(reconstructed.event.status, equals(EventStatus.ACTIVE));
    });
  });
}
