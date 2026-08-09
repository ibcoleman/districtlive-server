import 'package:freezed_annotation/freezed_annotation.dart';

part 'venue.freezed.dart';
part 'venue.g.dart';

@freezed
abstract class Venue with _$Venue {
  const factory Venue({
    required String id,
    required String name,
    required String slug,
    String? neighborhood,
    String? websiteUrl,
    @Default(0) int upcomingEventCount,
  }) = _Venue;

  factory Venue.fromJson(Map<String, dynamic> json) => _$VenueFromJson(json);
}
