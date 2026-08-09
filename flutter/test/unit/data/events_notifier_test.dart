import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:district_live/features/events/data/events_filter_state.dart';
import 'package:district_live/features/events/data/events_notifier.dart';
import 'package:district_live/features/events/domain/date_preset.dart';

void main() {
  group('EventsFilterState', () {
    test('has default thisWeek preset', () {
      final state = const EventsFilterState();
      expect(state.datePreset, DatePreset.thisWeek);
    });

    test('allows setting date preset', () {
      final state = const EventsFilterState();
      final updated = state.copyWith(datePreset: DatePreset.today);
      expect(updated.datePreset, DatePreset.today);
      expect(state.datePreset, DatePreset.thisWeek); // Original unchanged
    });

    test('allows setting venue filter', () {
      final state = const EventsFilterState();
      final updated = state.copyWith(
        selectedVenueId: 'venue-123',
        selectedVenueName: 'The Venue',
        selectedVenueSlug: 'the-venue',
      );
      expect(updated.selectedVenueId, 'venue-123');
      expect(updated.selectedVenueName, 'The Venue');
      expect(updated.selectedVenueSlug, 'the-venue');
    });

    test('allows setting genre filter', () {
      final state = const EventsFilterState();
      final updated = state.copyWith(selectedGenre: 'Rock');
      expect(updated.selectedGenre, 'Rock');
    });

    test('allows clearing filters', () {
      final cleared = const EventsFilterState();
      expect(cleared.datePreset, DatePreset.thisWeek);
      expect(cleared.selectedVenueId, isNull);
      expect(cleared.selectedVenueName, isNull);
      expect(cleared.selectedVenueSlug, isNull);
      expect(cleared.selectedGenre, isNull);
    });
  });

  group('EventsFilter provider', () {
    test('maintains independent state for different scope keys', () async {
      final container = ProviderContainer();

      // Set filter for scope 1
      container.read(eventsFilterProvider('scope-1').notifier).setDatePreset(DatePreset.today);
      container.read(eventsFilterProvider('scope-1').notifier).setGenreFilter('Jazz');

      // Set different filter for scope 2
      container.read(eventsFilterProvider('scope-2').notifier).setDatePreset(DatePreset.all);
      container.read(eventsFilterProvider('scope-2').notifier).setGenreFilter('Rock');

      // Verify isolation
      final scope1Filter = container.read(eventsFilterProvider('scope-1'));
      final scope2Filter = container.read(eventsFilterProvider('scope-2'));

      expect(scope1Filter.datePreset, DatePreset.today);
      expect(scope1Filter.selectedGenre, 'Jazz');
      expect(scope2Filter.datePreset, DatePreset.all);
      expect(scope2Filter.selectedGenre, 'Rock');
    });

    test('setDatePreset updates filter state', () async {
      final container = ProviderContainer();
      final notifier = container.read(eventsFilterProvider('test').notifier);

      notifier.setDatePreset(DatePreset.today);

      final state = container.read(eventsFilterProvider('test'));
      expect(state.datePreset, DatePreset.today);
    });

    test('setVenueFilter updates venue selection with slug', () async {
      final container = ProviderContainer();
      final notifier = container.read(eventsFilterProvider('test').notifier);

      notifier.setVenueFilter('venue-1', 'The Kennedy Center', slug: 'the-kennedy-center');

      final state = container.read(eventsFilterProvider('test'));
      expect(state.selectedVenueId, 'venue-1');
      expect(state.selectedVenueName, 'The Kennedy Center');
      expect(state.selectedVenueSlug, 'the-kennedy-center');
    });

    test('setVenueFilter with null clears venue selection', () async {
      final container = ProviderContainer();
      final notifier = container.read(eventsFilterProvider('test').notifier);

      notifier.setVenueFilter('venue-1', 'The Kennedy Center', slug: 'the-kennedy-center');
      notifier.setVenueFilter(null, null);

      final state = container.read(eventsFilterProvider('test'));
      expect(state.selectedVenueId, isNull);
      expect(state.selectedVenueName, isNull);
      expect(state.selectedVenueSlug, isNull);
    });

    test('setGenreFilter updates genre selection', () async {
      final container = ProviderContainer();
      final notifier = container.read(eventsFilterProvider('test').notifier);

      notifier.setGenreFilter('Indie');

      final state = container.read(eventsFilterProvider('test'));
      expect(state.selectedGenre, 'Indie');
    });

    test('setGenreFilter with null clears genre selection', () async {
      final container = ProviderContainer();
      final notifier = container.read(eventsFilterProvider('test').notifier);

      notifier.setGenreFilter('Indie');
      notifier.setGenreFilter(null);

      final state = container.read(eventsFilterProvider('test'));
      expect(state.selectedGenre, isNull);
    });

    test('clearAllFilters resets all filters to defaults', () async {
      final container = ProviderContainer();
      final notifier = container.read(eventsFilterProvider('test').notifier);

      // Set multiple filters
      notifier.setDatePreset(DatePreset.today);
      notifier.setVenueFilter('venue-1', 'The Venue', slug: 'the-venue');
      notifier.setGenreFilter('Jazz');

      // Clear all
      notifier.clearAllFilters();

      final state = container.read(eventsFilterProvider('test'));
      expect(state.datePreset, DatePreset.thisWeek); // Default
      expect(state.selectedVenueId, isNull);
      expect(state.selectedVenueName, isNull);
      expect(state.selectedVenueSlug, isNull);
      expect(state.selectedGenre, isNull);
    });

    test('multiple filters combine correctly', () async {
      final container = ProviderContainer();
      final notifier = container.read(eventsFilterProvider('test').notifier);

      notifier.setDatePreset(DatePreset.today);
      notifier.setVenueFilter('venue-1', 'The Venue', slug: 'the-venue');
      notifier.setGenreFilter('Rock');

      final state = container.read(eventsFilterProvider('test'));
      expect(state.datePreset, DatePreset.today);
      expect(state.selectedVenueId, 'venue-1');
      expect(state.selectedVenueName, 'The Venue');
      expect(state.selectedVenueSlug, 'the-venue');
      expect(state.selectedGenre, 'Rock');
    });
  });
}
