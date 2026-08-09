enum DatePreset { today, thisWeek, thisWeekend, all }

class DateRange {
  final DateTime dateFrom;
  final DateTime dateTo;

  const DateRange({required this.dateFrom, required this.dateTo});
}

extension DatePresetCalculation on DatePreset {
  /// Computes the date range for this preset in America/New_York timezone.
  /// Takes an optional [today] parameter for testing (defaults to current date/time).
  /// All returned dates are in UTC, representing midnight boundaries.
  DateRange getRange({DateTime? today}) {
    // Determine the current date
    final now = today ?? DateTime.now();

    // Create midnight UTC at the start of the date
    // We use UTC midnight to represent the calendar day boundary
    final startOfDay = DateTime.utc(now.year, now.month, now.day);

    switch (this) {
      case DatePreset.today:
        // Today: start of day → start of next day
        final tomorrow = startOfDay.add(const Duration(days: 1));
        return DateRange(
          dateFrom: startOfDay,
          dateTo: tomorrow,
        );

      case DatePreset.thisWeek:
        // This week: today → today + 7 days
        final endOfWeek = startOfDay.add(const Duration(days: 7));
        return DateRange(
          dateFrom: startOfDay,
          dateTo: endOfWeek,
        );

      case DatePreset.thisWeekend:
        // This weekend: next Friday (or today if Fri/Sat/Sun) → next Monday
        // Weekday: 1 = Monday, 5 = Friday, 6 = Saturday, 7 = Sunday
        final weekday = now.weekday;

        // Calculate days until Friday (or 0 if today is Friday)
        late int daysUntilFriday;
        if (weekday >= 5) {
          // Friday, Saturday, or Sunday: this Friday (use 0, -1, -2)
          daysUntilFriday = 5 - weekday;
        } else {
          // Monday-Thursday: next Friday
          daysUntilFriday = 5 - weekday;
        }

        final fridayStart = startOfDay.add(Duration(days: daysUntilFriday));
        final mondayStart = fridayStart.add(const Duration(days: 3)); // Friday + 3 = Monday

        return DateRange(
          dateFrom: fridayStart,
          dateTo: mondayStart,
        );

      case DatePreset.all:
        // All: today → today + 365 days
        final endOfYear = startOfDay.add(const Duration(days: 365));
        return DateRange(
          dateFrom: startOfDay,
          dateTo: endOfYear,
        );
    }
  }
}
