import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:district_live/features/events/data/events_api.dart';
import 'package:district_live/features/featured/data/featured_api.dart';
import 'package:district_live/features/featured/domain/featured_ui_state.dart';
import 'package:district_live/features/featured/domain/event_scoring.dart';
import 'package:district_live/features/events/domain/date_preset.dart';

part 'featured_notifier.g.dart';

@riverpod
class FeaturedNotifier extends _$FeaturedNotifier {
  @override
  Future<FeaturedUiState> build() async {
    return _loadFeatured();
  }

  Future<FeaturedUiState> _loadFeatured() async {
    final featuredApi = ref.read(featuredApiProvider);
    final eventsApi = ref.read(eventsApiProvider);

    // Step 1: Try admin-curated featured event
    try {
      final curated = await featuredApi.getCurrentFeatured();
      if (curated != null) {
        return FeaturedUiState.curated(featuredEvent: curated);
      }
    } catch (e) {
      // If featured API fails, continue to cascade to events
    }

    // Step 2: Try tonight's events
    try {
      final todayRange = DatePreset.today.getRange();
      final todayResponse = await eventsApi.getEvents(
        dateFrom: todayRange.dateFrom,
        dateTo: todayRange.dateTo,
        size: 50,
      );

      if (todayResponse.content.isNotEmpty) {
        final hero = pickFallbackHero(todayResponse.content);
        return FeaturedUiState.fallbackHero(event: hero);
      }
    } catch (e) {
      // If today's events fail, proceed to step 3
    }

    // Step 3: Try this weekend's events
    try {
      final weekendRange = DatePreset.thisWeekend.getRange();
      final weekendResponse = await eventsApi.getEvents(
        dateFrom: weekendRange.dateFrom,
        dateTo: weekendRange.dateTo,
        size: 50,
      );

      if (weekendResponse.content.isNotEmpty) {
        final hero = pickFallbackHero(weekendResponse.content);
        return FeaturedUiState.fallbackHero(event: hero);
      }
    } catch (e) {
      // If weekend events fail, return empty fallback
    }

    // Step 4: No events at all
    return const FeaturedUiState.fallbackHero();
  }

  Future<void> refresh() async {
    // Set refreshing state on current value
    FeaturedUiState? current;
    state.whenData((data) {
      current = data;
    });

    if (current != null) {
      state = AsyncValue.data(current!.map(
        loading: (_) => current!,
        curated: (c) => c.copyWith(isRefreshing: true),
        fallbackHero: (f) => f.copyWith(isRefreshing: true),
        error: (_) => current!,
      ));
    }

    try {
      final result = await _loadFeatured();
      state = AsyncValue.data(result);
    } catch (e, st) {
      // If we have a displayable cached state, keep it instead of replacing with error
      if (current != null &&
          (current is FeaturedCurated ||
           (current is FeaturedFallbackHero && (current as FeaturedFallbackHero).event != null))) {
        // Restore the previous state to keep the UI showing the last known good event
        state = AsyncValue.data(current!);
      } else if (current != null) {
        // Only show error if current state is not displayable
        state = AsyncValue.data(FeaturedUiState.error(message: e.toString()));
      } else {
        state = AsyncValue.error(e, st);
      }
    }
  }
}
