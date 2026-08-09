import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:district_live/features/events/domain/enums.dart';

/// All events are in the DC area — display times in Eastern.
final _eastern = tz.getLocation('America/New_York');

/// Converts a (typically UTC) DateTime to Eastern time.
DateTime _toEastern(DateTime dt) =>
    tz.TZDateTime.from(dt, _eastern);

/// Formats an event's date and time information for display.
///
/// Returns a string in the format:
/// "EEE, MMM d · Doors 7:30pm · Show 8:00pm"
/// or if no doors time:
/// "EEE, MMM d · Show 8:00pm"
///
/// Input times are converted from UTC to America/New_York for display.
String formatEventDateTime(DateTime startTime, DateTime? doorsTime) {
  final easternStart = _toEastern(startTime);

  // Format: "Fri, Mar 15"
  final dateFormat = DateFormat('EEE, MMM d');
  final datePart = dateFormat.format(easternStart);

  // Format times: "7:30pm", "8:00pm"
  final timeFormat = DateFormat('h:mma');
  final startTimePart = timeFormat.format(easternStart).toLowerCase();

  if (doorsTime != null) {
    final easternDoors = _toEastern(doorsTime);
    final doorsTimePart = timeFormat.format(easternDoors).toLowerCase();
    return '$datePart · Doors $doorsTimePart · Show $startTimePart';
  } else {
    return '$datePart · Show $startTimePart';
  }
}

/// Formats price information for display.
///
/// Returns:
/// - "Free" for FREE tier
/// - "$25" for single price
/// - "$25-$50" for price range
/// - "" (empty string) if no price data
String formatPrice(double? minPrice, double? maxPrice, PriceTier? priceTier) {
  // If price tier is explicitly FREE, return "Free"
  if (priceTier == PriceTier.FREE) {
    return 'Free';
  }

  // If no price data available, return empty string
  if (minPrice == null && maxPrice == null) {
    return '';
  }

  // If maxPrice is null or prices are equal, show single price
  if (maxPrice == null || minPrice == maxPrice) {
    return '\$${minPrice?.toStringAsFixed(0) ?? '0'}';
  }

  // Both prices exist and differ, show range
  // minPrice must be not null (because if both were null we'd have returned above,
  // and if minPrice was null but maxPrice wasn't, we'd have returned above too)
  return '\$${minPrice!.toStringAsFixed(0)}-\$${maxPrice.toStringAsFixed(0)}';
}

/// Formats age restriction information for display.
///
/// Returns:
/// - "18+" for EIGHTEEN_PLUS
/// - "21+" for TWENTY_ONE_PLUS
/// - "" (empty string) for ALL_AGES
String formatAge(AgeRestriction ageRestriction) {
  switch (ageRestriction) {
    case AgeRestriction.EIGHTEEN_PLUS:
      return '18+';
    case AgeRestriction.TWENTY_ONE_PLUS:
      return '21+';
    case AgeRestriction.ALL_AGES:
      return '';
  }
}

/// Formats venue name with neighborhood for display.
///
/// Returns:
/// - "Venue Name · Neighborhood" if both provided
/// - "Venue Name" if only venue provided
/// - "" (empty string) if venue is null
String formatVenueWithNeighborhood(String? venueName, String? neighborhood) {
  if (venueName == null || venueName.isEmpty) {
    return '';
  }

  if (neighborhood != null && neighborhood.isNotEmpty) {
    return '$venueName · $neighborhood';
  }

  return venueName;
}
