import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:district_live/features/events/domain/event.dart';
import 'package:district_live/features/venues/domain/venue.dart';
import 'package:district_live/features/events/presentation/share_utils.dart';

void main() {
  setUpAll(() {
    tz.initializeTimeZones();
  });

  group('buildShareText', () {
    test('full event with venue and ticket URL', () {
      final venue = const Venue(
        id: 'venue-1',
        name: 'The Kennedy Center',
        slug: 'the-kennedy-center',
      );
      final event = Event(
        id: 'event-1',
        title: 'Concert Night',
        slug: 'concert-night',
        startTime: DateTime.utc(2026, 3, 15, 19, 0), // Sunday 3 PM Eastern
        venue: venue,
        ticketUrl: 'https://tickets.com',
      );

      final result = buildShareText(event);

      expect(result, contains('Concert Night'));
      expect(result, contains('Sunday, March 15, 2026'));
      expect(result, contains('at The Kennedy Center'));
      expect(result, contains('https://tickets.com'));
    });

    test('event without venue', () {
      final event = Event(
        id: 'event-1',
        title: 'Concert Night',
        slug: 'concert-night',
        startTime: DateTime.utc(2026, 3, 15, 19, 0),
        ticketUrl: 'https://tickets.com',
      );

      final result = buildShareText(event);

      expect(result, contains('Concert Night'));
      expect(result, contains('Sunday, March 15, 2026'));
      expect(result, isNot(contains('at ')));
      expect(result, contains('https://tickets.com'));
    });

    test('event without ticket URL', () {
      final venue = const Venue(
        id: 'venue-1',
        name: 'The Kennedy Center',
        slug: 'the-kennedy-center',
      );
      final event = Event(
        id: 'event-1',
        title: 'Concert Night',
        slug: 'concert-night',
        startTime: DateTime.utc(2026, 3, 15, 19, 0),
        venue: venue,
      );

      final result = buildShareText(event);

      expect(result, contains('Concert Night'));
      expect(result, contains('Sunday, March 15, 2026'));
      expect(result, contains('at The Kennedy Center'));
      expect(result, isNot(contains('http')));
    });

    test('event without venue or ticket URL', () {
      final event = Event(
        id: 'event-1',
        title: 'Concert Night',
        slug: 'concert-night',
        startTime: DateTime.utc(2026, 3, 15, 19, 0),
      );

      final result = buildShareText(event);

      expect(result, contains('Concert Night'));
      expect(result, contains('Sunday, March 15, 2026'));
      expect(result, isNot(contains('at ')));
      expect(result, isNot(contains('http')));
    });

    test('text is properly formatted with newlines', () {
      final venue = const Venue(
        id: 'venue-1',
        name: 'The Kennedy Center',
        slug: 'the-kennedy-center',
      );
      final event = Event(
        id: 'event-1',
        title: 'Concert Night',
        slug: 'concert-night',
        startTime: DateTime.utc(2026, 3, 15, 19, 0),
        venue: venue,
        ticketUrl: 'https://tickets.com',
      );

      final result = buildShareText(event);

      // Split by newlines and verify structure
      final lines = result.split('\n');
      expect(lines[0], 'Concert Night');
      expect(lines[1], 'Sunday, March 15, 2026');
      expect(lines[2], 'at The Kennedy Center');
      expect(lines[3], 'https://tickets.com');
      expect(lines.length, 4); // No trailing newlines
    });
  });
}
