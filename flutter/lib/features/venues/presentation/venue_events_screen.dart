import 'package:flutter/material.dart';
import 'package:district_live/features/events/presentation/events_screen.dart';

/// VenueEventsScreen is a thin wrapper that renders the shared EventsScreen
/// with a locked venue filter.
///
/// This screen is used when navigating from a specific venue to view all events
/// at that venue. The EventsScreen handles all the event loading, filtering, and
/// pagination logic, while VenueEventsScreen just sets up the venue-specific scope
/// and locked venue parameters.
class VenueEventsScreen extends StatelessWidget {
  final String venueId;
  final String venueName;
  final String venueSlug;

  const VenueEventsScreen({
    super.key,
    required this.venueId,
    required this.venueName,
    required this.venueSlug,
  });

  @override
  Widget build(BuildContext context) {
    return EventsScreen(
      scopeKey: 'venue-events-$venueId',
      lockedVenueId: venueId,
      lockedVenueName: venueName,
      lockedVenueSlug: venueSlug,
      title: venueName,
      showDatePresets: false,
    );
  }
}
