import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:district_live/features/events/domain/event.dart';

String buildShareText(Event event) {
  final buffer = StringBuffer();
  buffer.writeln(event.title);

  // Date formatted in Eastern timezone
  final eastern = tz.getLocation('America/New_York');
  final tzDateTime = tz.TZDateTime.from(event.startTime, eastern);
  final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(tzDateTime);
  buffer.writeln(dateStr);

  if (event.venue != null) {
    buffer.writeln('at ${event.venue!.name}');
  }
  if (event.ticketUrl != null) {
    buffer.writeln(event.ticketUrl);
  }

  return buffer.toString().trimRight();
}
