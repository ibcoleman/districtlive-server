import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../features/events/domain/event_detail.dart';

part 'featured_event.freezed.dart';
part 'featured_event.g.dart';

@freezed
abstract class FeaturedEvent with _$FeaturedEvent {
  const factory FeaturedEvent({
    required String id,
    required EventDetail event,
    required String blurb,
    required DateTime createdAt,
    required String createdBy,
  }) = _FeaturedEvent;

  factory FeaturedEvent.fromJson(Map<String, dynamic> json) =>
      _$FeaturedEventFromJson(json);
}
