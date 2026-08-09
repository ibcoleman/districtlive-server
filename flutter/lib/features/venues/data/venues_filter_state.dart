import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'venues_filter_state.g.dart';

/// Neighborhood filter state for venues list.
/// null = all neighborhoods (no filter applied)
@riverpod
class VenuesFilter extends _$VenuesFilter {
  @override
  String? build() => null;

  void setNeighborhood(String? neighborhood) {
    state = neighborhood;
  }
}
