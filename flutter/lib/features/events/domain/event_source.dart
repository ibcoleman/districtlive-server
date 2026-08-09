import 'package:freezed_annotation/freezed_annotation.dart';
import 'enums.dart';

part 'event_source.freezed.dart';
part 'event_source.g.dart';

@freezed
abstract class EventSource with _$EventSource {
  const factory EventSource({
    required SourceType sourceType,
    DateTime? lastScrapedAt,
  }) = _EventSource;

  factory EventSource.fromJson(Map<String, dynamic> json) =>
      _$EventSourceFromJson(json);
}
