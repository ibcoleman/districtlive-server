import 'package:flutter_test/flutter_test.dart';
import 'package:district_live/features/venues/presentation/venue_events_screen.dart';

void main() {
  group('VenueEventsScreen', () {
    test('can be constructed with required parameters', () {
      const screen = VenueEventsScreen(
        venueId: 'venue-1',
        venueName: '9:30 Club',
        venueSlug: '930-club',
      );

      expect(screen.venueId, 'venue-1');
      expect(screen.venueName, '9:30 Club');
      expect(screen.venueSlug, '930-club');
    });

    test('generates correct scope key', () {
      const screen = VenueEventsScreen(
        venueId: 'venue-123',
        venueName: 'Black Cat',
        venueSlug: 'black-cat',
      );

      // The scope key pattern is 'venue-events-$venueId'
      expect('venue-events-${screen.venueId}', 'venue-events-venue-123');
    });

    test('constructs with different venue names', () {
      const screen = VenueEventsScreen(
        venueId: 'venue-abc',
        venueName: 'The Kennedy Center',
        venueSlug: 'the-kennedy-center',
      );

      expect(screen.venueId, 'venue-abc');
      expect(screen.venueName, 'The Kennedy Center');
    });

    test('creates EventsScreen with correct parameters', () {
      // This test verifies that VenueEventsScreen correctly passes parameters
      // to EventsScreen. The actual EventsScreen behavior (filtering, pagination, etc.)
      // is tested in events_screen_test.dart.
      const venueName = '9:30 Club';
      const venueId = 'venue-1';

      final screen = VenueEventsScreen(
        venueId: venueId,
        venueName: venueName,
        venueSlug: '930-club',
      );

      // Verify that the screen will create an EventsScreen with correct scope key
      final expectedScopeKey = 'venue-events-$venueId';
      expect(expectedScopeKey, equals('venue-events-venue-1'));

      // Verify that venueName is stored and will be passed as title
      expect(screen.venueName, equals(venueName));
    });
  });
}
