import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:district_live/features/events/domain/enums.dart';
import 'package:district_live/features/events/presentation/event_format_utils.dart';

void main() {
  setUpAll(() => tz.initializeTimeZones());

  group('formatEventDateTime', () {
    test('formats date and time with doors time', () {
      // 2025-03-15 10:00 AM EDT (doors) = 14:00 UTC
      final doorsTime = DateTime.utc(2025, 3, 15, 14, 0, 0);
      // 2025-03-15 10:30 PM EDT (show) = 2025-03-16 02:30 UTC
      final startTime = DateTime.utc(2025, 3, 16, 2, 30, 0);

      final result = formatEventDateTime(startTime, doorsTime);

      expect(result, contains('Sat, Mar 15'));
      expect(result, contains('Doors 10:00am'));
      expect(result, contains('Show 10:30pm'));
    });

    test('formats without doors time', () {
      // 2025-03-15 10:00 PM EDT = 2025-03-16 02:00 UTC
      final startTime = DateTime.utc(2025, 3, 16, 2, 0, 0);

      final result = formatEventDateTime(startTime, null);

      expect(result, contains('Sat, Mar 15'));
      expect(result, contains('Show 10:00pm'));
      expect(result, isNot(contains('Doors')));
    });

    test('formats midnight show correctly', () {
      // 2025-03-15 00:00 ET = 05:00 UTC (during EDT)
      final startTime = DateTime.utc(2025, 3, 15, 4, 0, 0);

      final result = formatEventDateTime(startTime, null);

      expect(result, contains('12:00am'));
    });

    test('UTC midnight converts to previous day in Eastern time', () {
      // 2026-04-26 00:00 UTC = 2026-04-25 8:00 PM EDT
      // This is the Garofalo bug: event on 4/25 at 8pm stored as 4/26 midnight UTC
      final startTime = DateTime.utc(2026, 4, 26, 0, 0, 0);

      final result = formatEventDateTime(startTime, null);

      expect(result, contains('Sat, Apr 25'));
      expect(result, contains('Show 8:00pm'));
    });
  });

  group('formatPrice', () {
    test('FREE tier returns "Free"', () {
      final result = formatPrice(null, null, PriceTier.FREE);
      expect(result, 'Free');
    });

    test('single price formatted with dollar sign', () {
      final result = formatPrice(25, null, null);
      expect(result, '\$25');
    });

    test('single price from min when max equals min', () {
      final result = formatPrice(25, 25, null);
      expect(result, '\$25');
    });

    test('price range formatted as "min-max"', () {
      final result = formatPrice(25, 50, null);
      expect(result, '\$25-\$50');
    });

    test('no price data returns empty string', () {
      final result = formatPrice(null, null, null);
      expect(result, '');
    });

    test('zero price formatted correctly', () {
      final result = formatPrice(0, null, null);
      expect(result, '\$0');
    });

    test('decimal prices rounded to integer', () {
      final result = formatPrice(25.99, 50.50, null);
      expect(result, '\$26-\$51'); // Rounded up
    });

    test('FREE tier takes precedence over price data', () {
      final result = formatPrice(25, 50, PriceTier.FREE);
      expect(result, 'Free');
    });
  });

  group('formatAge', () {
    test('EIGHTEEN_PLUS formatted as "18+"', () {
      final result = formatAge(AgeRestriction.EIGHTEEN_PLUS);
      expect(result, '18+');
    });

    test('TWENTY_ONE_PLUS formatted as "21+"', () {
      final result = formatAge(AgeRestriction.TWENTY_ONE_PLUS);
      expect(result, '21+');
    });

    test('ALL_AGES returns empty string', () {
      final result = formatAge(AgeRestriction.ALL_AGES);
      expect(result, '');
    });
  });

  group('formatVenueWithNeighborhood', () {
    test('venue and neighborhood formatted with separator', () {
      final result = formatVenueWithNeighborhood('The Kennedy Center', 'Downtown');
      expect(result, 'The Kennedy Center · Downtown');
    });

    test('venue only returns venue name', () {
      final result = formatVenueWithNeighborhood('The Kennedy Center', null);
      expect(result, 'The Kennedy Center');
    });

    test('venue with empty neighborhood returns venue name', () {
      final result = formatVenueWithNeighborhood('The Kennedy Center', '');
      expect(result, 'The Kennedy Center');
    });

    test('null venue returns empty string', () {
      final result = formatVenueWithNeighborhood(null, 'Downtown');
      expect(result, '');
    });

    test('empty venue name returns empty string', () {
      final result = formatVenueWithNeighborhood('', 'Downtown');
      expect(result, '');
    });

    test('both null returns empty string', () {
      final result = formatVenueWithNeighborhood(null, null);
      expect(result, '');
    });
  });
}
