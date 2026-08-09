// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'featured_api.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(featuredApi)
final featuredApiProvider = FeaturedApiProvider._();

final class FeaturedApiProvider
    extends $FunctionalProvider<FeaturedApi, FeaturedApi, FeaturedApi>
    with $Provider<FeaturedApi> {
  FeaturedApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'featuredApiProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$featuredApiHash();

  @$internal
  @override
  $ProviderElement<FeaturedApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FeaturedApi create(Ref ref) {
    return featuredApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FeaturedApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FeaturedApi>(value),
    );
  }
}

String _$featuredApiHash() => r'f010866eea3009b8470064603793a014462b09ce';
