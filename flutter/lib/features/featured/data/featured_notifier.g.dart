// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'featured_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FeaturedNotifier)
final featuredProvider = FeaturedNotifierProvider._();

final class FeaturedNotifierProvider
    extends $AsyncNotifierProvider<FeaturedNotifier, FeaturedUiState> {
  FeaturedNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'featuredProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$featuredNotifierHash();

  @$internal
  @override
  FeaturedNotifier create() => FeaturedNotifier();
}

String _$featuredNotifierHash() => r'3a737df094b26fcf08d2caaf4b0a354e561a1609';

abstract class _$FeaturedNotifier extends $AsyncNotifier<FeaturedUiState> {
  FutureOr<FeaturedUiState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<FeaturedUiState>, FeaturedUiState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<FeaturedUiState>, FeaturedUiState>,
              AsyncValue<FeaturedUiState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
