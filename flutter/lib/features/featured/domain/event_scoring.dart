import 'package:district_live/features/events/domain/event.dart';

int scoreEvent(Event event) {
  var score = 0;
  if (event.imageUrl != null) score += 3;
  if (event.description != null) score += 2;
  if (event.venue != null) score += 1;
  if (event.venue?.neighborhood != null) score += 1;
  if (event.minPrice != null || event.priceTier != null) score += 1;
  if (event.ticketUrl != null) score += 1;
  if (event.artists.isNotEmpty) score += 1;
  return score;
}

Event? pickFallbackHero(List<Event> events) {
  if (events.isEmpty) return null;
  final sorted = List<Event>.from(events)
    ..sort((a, b) => scoreEvent(b).compareTo(scoreEvent(a)));
  if (sorted.length >= 2 && scoreEvent(sorted[0]) == scoreEvent(sorted[1])) {
    return sorted[1];
  }
  return sorted[0];
}
