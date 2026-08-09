import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:district_live/features/events/domain/date_preset.dart';

part 'events_filter_state.freezed.dart';

/// Holds the current filter selections for an events list.
/// This state is scoped by a String key to support multiple independent
/// event lists (e.g., main Events tab vs VenueEventsScreen).
@freezed
abstract class EventsFilterState with _$EventsFilterState {
  const factory EventsFilterState({
    @Default(DatePreset.thisWeek) DatePreset datePreset,
    String? selectedVenueId,
    String? selectedVenueName,
    String? selectedVenueSlug,
    String? selectedGenre,
    String? sort,
  }) = _EventsFilterState;
}
