import 'package:flutter_test/flutter_test.dart';
import 'package:district_live/features/events/domain/date_preset.dart';

void main() {
  group('DatePreset', () {
    group('today preset', () {
      test('on Wednesday returns single-day range', () {
        // 2025-03-05 is a Wednesday at 10:00 AM
        final testDate = DateTime(2025, 3, 5, 10, 0, 0);
        final range = DatePreset.today.getRange(today: testDate);

        // Expected: midnight Wed UTC → midnight Thu UTC
        final expectedFrom = DateTime.utc(2025, 3, 5);
        final expectedTo = DateTime.utc(2025, 3, 6);

        expect(range.dateFrom, expectedFrom);
        expect(range.dateTo, expectedTo);
        expect(range.dateTo.difference(range.dateFrom).inDays, 1);
      });

      test('on midnight returns correct range', () {
        final testDate = DateTime(2025, 3, 5, 0, 0, 0);
        final range = DatePreset.today.getRange(today: testDate);

        final expectedFrom = DateTime.utc(2025, 3, 5);
        final expectedTo = DateTime.utc(2025, 3, 6);

        expect(range.dateFrom, expectedFrom);
        expect(range.dateTo, expectedTo);
      });
    });

    group('thisWeek preset', () {
      test('on Wednesday returns 7-day range starting today', () {
        // 2025-03-05 is a Wednesday
        final testDate = DateTime(2025, 3, 5, 10, 0, 0);
        final range = DatePreset.thisWeek.getRange(today: testDate);

        final expectedFrom = DateTime.utc(2025, 3, 5);
        final expectedTo = DateTime.utc(2025, 3, 12);

        expect(range.dateFrom, expectedFrom);
        expect(range.dateTo, expectedTo);
        expect(range.dateTo.difference(range.dateFrom).inDays, 7);
      });

      test('on Monday returns 7-day range', () {
        // 2025-03-03 is a Monday
        final testDate = DateTime(2025, 3, 3, 10, 0, 0);
        final range = DatePreset.thisWeek.getRange(today: testDate);

        final expectedFrom = DateTime.utc(2025, 3, 3);
        final expectedTo = DateTime.utc(2025, 3, 10);

        expect(range.dateFrom, expectedFrom);
        expect(range.dateTo, expectedTo);
        expect(range.dateTo.difference(range.dateFrom).inDays, 7);
      });
    });

    group('thisWeekend preset', () {
      test('on Wednesday returns Friday through Monday', () {
        // 2025-03-05 is a Wednesday
        final testDate = DateTime(2025, 3, 5, 10, 0, 0);
        final range = DatePreset.thisWeekend.getRange(today: testDate);

        final expectedFrom = DateTime.utc(2025, 3, 7); // Friday
        final expectedTo = DateTime.utc(2025, 3, 10);  // Monday

        expect(range.dateFrom, expectedFrom);
        expect(range.dateTo, expectedTo);
        expect(range.dateTo.difference(range.dateFrom).inDays, 3);
      });

      test('on Friday returns Friday through Monday', () {
        // 2025-03-07 is a Friday
        final testDate = DateTime(2025, 3, 7, 10, 0, 0);
        final range = DatePreset.thisWeekend.getRange(today: testDate);

        final expectedFrom = DateTime.utc(2025, 3, 7);  // Friday
        final expectedTo = DateTime.utc(2025, 3, 10);   // Monday

        expect(range.dateFrom, expectedFrom);
        expect(range.dateTo, expectedTo);
      });

      test('on Saturday returns Friday through Monday', () {
        // 2025-03-08 is a Saturday
        final testDate = DateTime(2025, 3, 8, 10, 0, 0);
        final range = DatePreset.thisWeekend.getRange(today: testDate);

        final expectedFrom = DateTime.utc(2025, 3, 7);  // Friday
        final expectedTo = DateTime.utc(2025, 3, 10);   // Monday

        expect(range.dateFrom, expectedFrom);
        expect(range.dateTo, expectedTo);
      });

      test('on Sunday returns Friday through Monday', () {
        // 2025-03-09 is a Sunday
        final testDate = DateTime(2025, 3, 9, 10, 0, 0);
        final range = DatePreset.thisWeekend.getRange(today: testDate);

        final expectedFrom = DateTime.utc(2025, 3, 7);  // Friday
        final expectedTo = DateTime.utc(2025, 3, 10);   // Monday

        expect(range.dateFrom, expectedFrom);
        expect(range.dateTo, expectedTo);
      });

      test('on Monday returns next Friday through Monday', () {
        // 2025-03-10 is a Monday
        final testDate = DateTime(2025, 3, 10, 10, 0, 0);
        final range = DatePreset.thisWeekend.getRange(today: testDate);

        final expectedFrom = DateTime.utc(2025, 3, 14); // Next Friday
        final expectedTo = DateTime.utc(2025, 3, 17);   // Following Monday

        expect(range.dateFrom, expectedFrom);
        expect(range.dateTo, expectedTo);
      });
    });

    group('all preset', () {
      test('returns 365-day range', () {
        // 2025-03-05 is a Wednesday
        final testDate = DateTime(2025, 3, 5, 10, 0, 0);
        final range = DatePreset.all.getRange(today: testDate);

        final expectedFrom = DateTime.utc(2025, 3, 5);
        final expectedTo = DateTime.utc(2026, 3, 5);

        expect(range.dateFrom, expectedFrom);
        expect(range.dateTo, expectedTo);
        expect(range.dateTo.difference(range.dateFrom).inDays, 365);
      });
    });
  });
}
