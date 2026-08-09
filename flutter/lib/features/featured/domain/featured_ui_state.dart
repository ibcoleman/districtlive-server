import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:district_live/features/events/domain/event.dart';
import 'package:district_live/features/featured/domain/featured_event.dart';

part 'featured_ui_state.freezed.dart';

@freezed
sealed class FeaturedUiState with _$FeaturedUiState {
  const factory FeaturedUiState.loading() = FeaturedLoading;

  const factory FeaturedUiState.curated({
    required FeaturedEvent featuredEvent,
    @Default(false) bool isRefreshing,
  }) = FeaturedCurated;

  const factory FeaturedUiState.fallbackHero({
    Event? event,
    @Default(false) bool isRefreshing,
  }) = FeaturedFallbackHero;

  const factory FeaturedUiState.error({required String message}) =
      FeaturedError;
}
