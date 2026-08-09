// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'venues_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Venues notifier that provides cache-first loading with background refresh.
/// Watches neighborhood filter and schedules background refresh on build.
/// Provides a manual refresh() method for pull-to-refresh functionality.

@ProviderFor(VenuesNotifier)
final venuesProvider = VenuesNotifierProvider._();

/// Venues notifier that provides cache-first loading with background refresh.
/// Watches neighborhood filter and schedules background refresh on build.
/// Provides a manual refresh() method for pull-to-refresh functionality.
final class VenuesNotifierProvider
    extends $AsyncNotifierProvider<VenuesNotifier, void> {
  /// Venues notifier that provides cache-first loading with background refresh.
  /// Watches neighborhood filter and schedules background refresh on build.
  /// Provides a manual refresh() method for pull-to-refresh functionality.
  VenuesNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'venuesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$venuesNotifierHash();

  @$internal
  @override
  VenuesNotifier create() => VenuesNotifier();
}

String _$venuesNotifierHash() => r'7b134f27d18751f1d0938d13c860d625df2182f8';

/// Venues notifier that provides cache-first loading with background refresh.
/// Watches neighborhood filter and schedules background refresh on build.
/// Provides a manual refresh() method for pull-to-refresh functionality.

abstract class _$VenuesNotifier extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
