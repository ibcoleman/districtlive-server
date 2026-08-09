import 'package:freezed_annotation/freezed_annotation.dart';
import 'artist.dart';
import 'enums.dart';
import 'event.dart';
import 'event_source.dart';
import '../../../features/venues/domain/venue.dart';

part 'event_detail.freezed.dart';
part 'event_detail.g.dart';

@freezed
abstract class EventDetail with _$EventDetail {
  const factory EventDetail({
    required String id,
    required String title,
    required String slug,
    required DateTime startTime,
    DateTime? doorsTime,
    Venue? venue,
    @Default([]) List<Artist> artists,
    double? minPrice,
    double? maxPrice,
    PriceTier? priceTier,
    String? ticketUrl,
    @Default(false) bool soldOut,
    String? imageUrl,
    @Default(AgeRestriction.ALL_AGES) AgeRestriction ageRestriction,
    @Default(EventStatus.ACTIVE) EventStatus status,
    String? description,
    DateTime? endTime,
    DateTime? onSaleDate,
    String? ticketPlatform,
    @Default([]) List<EventSource> sources,
    @Default([]) List<Event> relatedEvents,
  }) = _EventDetail;

  factory EventDetail.fromJson(Map<String, dynamic> json) =>
      _$EventDetailFromJson(json);
}
