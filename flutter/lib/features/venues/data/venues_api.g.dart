// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'venues_api.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(venuesApi)
final venuesApiProvider = VenuesApiProvider._();

final class VenuesApiProvider
    extends $FunctionalProvider<VenuesApi, VenuesApi, VenuesApi>
    with $Provider<VenuesApi> {
  VenuesApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'venuesApiProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$venuesApiHash();

  @$internal
  @override
  $ProviderElement<VenuesApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  VenuesApi create(Ref ref) {
    return venuesApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VenuesApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VenuesApi>(value),
    );
  }
}

String _$venuesApiHash() => r'c0f9712719a69103c0acd523bc5f67d66a6f9da2';
