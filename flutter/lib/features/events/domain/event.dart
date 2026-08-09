import 'package:freezed_annotation/freezed_annotation.dart';
import 'artist.dart';
import 'enums.dart';
import '../../../features/venues/domain/venue.dart';

part 'event.freezed.dart';
part 'event.g.dart';

@freezed
abstract class Event with _$Event {
  const factory Event({
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
    DateTime? createdAt,
  }) = _Event;

  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);
}
