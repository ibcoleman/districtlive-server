import 'package:flutter_test/flutter_test.dart';
import 'package:district_live/features/venues/domain/venue.dart';

void main() {
  group('Venue JSON serialization', () {
    final testVenue = const Venue(
      id: 'venue-1',
      name: 'The Anthem',
      slug: 'the-anthem',
      neighborhood: 'Southwest DC',
      websiteUrl: 'https://www.theanthemdc.com',
      upcomingEventCount: 12,
    );

    test('Venue round-trip: full object', () {
      final json = testVenue.toJson();
      final reconstructed = Venue.fromJson(json);

      expect(reconstructed, equals(testVenue));
    });

    test('Venue round-trip: minimal object', () {
      final minimal = const Venue(
        id: 'venue-2',
        name: 'Small Venue',
        slug: 'small-venue',
      );

      final json = minimal.toJson();
      final reconstructed = Venue.fromJson(json);

      expect(reconstructed.id, equals('venue-2'));
      expect(reconstructed.name, equals('Small Venue'));
      expect(reconstructed.slug, equals('small-venue'));
      expect(reconstructed.neighborhood, isNull);
      expect(reconstructed.websiteUrl, isNull);
      expect(reconstructed.upcomingEventCount, equals(0));
    });

    test('Venue round-trip: null neighborhood and website', () {
      final withNulls = const Venue(
        id: 'venue-3',
        name: 'Unnamed Venue',
        slug: 'unnamed',
        neighborhood: null,
        websiteUrl: null,
        upcomingEventCount: 3,
      );

      final json = withNulls.toJson();
      final reconstructed = Venue.fromJson(json);

      expect(reconstructed.neighborhood, isNull);
      expect(reconstructed.websiteUrl, isNull);
      expect(reconstructed.upcomingEventCount, equals(3));
    });

    test('Venue upcomingEventCount serialization', () {
      final json = testVenue.toJson();
      expect(json['upcomingEventCount'], equals(12));

      final reconstructed = Venue.fromJson(json);
      expect(reconstructed.upcomingEventCount, equals(12));
    });

    test('Venue zero upcomingEventCount', () {
      final noEvents = const Venue(
        id: 'venue-4',
        name: 'Quiet Venue',
        slug: 'quiet-venue',
        upcomingEventCount: 0,
      );

      final json = noEvents.toJson();
      final reconstructed = Venue.fromJson(json);

      expect(reconstructed.upcomingEventCount, equals(0));
    });

    test('Venue all fields present', () {
      final json = testVenue.toJson();

      expect(json['id'], equals('venue-1'));
      expect(json['name'], equals('The Anthem'));
      expect(json['slug'], equals('the-anthem'));
      expect(json['neighborhood'], equals('Southwest DC'));
      expect(json['websiteUrl'], equals('https://www.theanthemdc.com'));
      expect(json['upcomingEventCount'], equals(12));
    });
  });
}
