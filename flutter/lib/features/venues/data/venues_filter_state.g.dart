// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'venues_filter_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Neighborhood filter state for venues list.
/// null = all neighborhoods (no filter applied)

@ProviderFor(VenuesFilter)
final venuesFilterProvider = VenuesFilterProvider._();

/// Neighborhood filter state for venues list.
/// null = all neighborhoods (no filter applied)
final class VenuesFilterProvider
    extends $NotifierProvider<VenuesFilter, String?> {
  /// Neighborhood filter state for venues list.
  /// null = all neighborhoods (no filter applied)
  VenuesFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'venuesFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$venuesFilterHash();

  @$internal
  @override
  VenuesFilter create() => VenuesFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$venuesFilterHash() => r'0c3f814e2a71bd29d654a36181b8a3339070cddf';

/// Neighborhood filter state for venues list.
/// null = all neighborhoods (no filter applied)

abstract class _$VenuesFilter extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
