import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:district_live/features/events/data/events_api.dart';
import 'package:district_live/features/events/domain/event_detail.dart';

part 'event_detail_notifier.g.dart';

@riverpod
class EventDetailNotifier extends _$EventDetailNotifier {
  @override
  Future<EventDetail> build(String eventId) async {
    final eventsApi = ref.read(eventsApiProvider);
    return eventsApi.getEventDetail(eventId);
  }
}
