// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'events_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Filter state provider scoped by scopeKey to support multiple independent event lists.

@ProviderFor(EventsFilter)
final eventsFilterProvider = EventsFilterFamily._();

/// Filter state provider scoped by scopeKey to support multiple independent event lists.
final class EventsFilterProvider
    extends $NotifierProvider<EventsFilter, EventsFilterState> {
  /// Filter state provider scoped by scopeKey to support multiple independent event lists.
  EventsFilterProvider._({
    required EventsFilterFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'eventsFilterProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$eventsFilterHash();

  @override
  String toString() {
    return r'eventsFilterProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  EventsFilter create() => EventsFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EventsFilterState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EventsFilterState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is EventsFilterProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$eventsFilterHash() => r'91b6bf4b0bcce525732266e6721f60401f20e15d';

/// Filter state provider scoped by scopeKey to support multiple independent event lists.

final class EventsFilterFamily extends $Family
    with
        $ClassFamilyOverride<
          EventsFilter,
          EventsFilterState,
          EventsFilterState,
          EventsFilterState,
          String
        > {
  EventsFilterFamily._()
    : super(
        retry: null,
        name: r'eventsFilterProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Filter state provider scoped by scopeKey to support multiple independent event lists.

  EventsFilterProvider call(String scopeKey) =>
      EventsFilterProvider._(argument: scopeKey, from: this);

  @override
  String toString() => r'eventsFilterProvider';
}

/// Filter state provider scoped by scopeKey to support multiple independent event lists.

abstract class _$EventsFilter extends $Notifier<EventsFilterState> {
  late final _$args = ref.$arg as String;
  String get scopeKey => _$args;

  EventsFilterState build(String scopeKey);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<EventsFilterState, EventsFilterState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<EventsFilterState, EventsFilterState>,
              EventsFilterState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

/// Events notifier that implements cache-first loading with background refresh.
/// Family provider scoped by scopeKey to support multiple independent event lists.

@ProviderFor(EventsNotifier)
final eventsProvider = EventsNotifierFamily._();

/// Events notifier that implements cache-first loading with background refresh.
/// Family provider scoped by scopeKey to support multiple independent event lists.
final class EventsNotifierProvider
    extends $AsyncNotifierProvider<EventsNotifier, EventsUiState> {
  /// Events notifier that implements cache-first loading with background refresh.
  /// Family provider scoped by scopeKey to support multiple independent event lists.
  EventsNotifierProvider._({
    required EventsNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'eventsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$eventsNotifierHash();

  @override
  String toString() {
    return r'eventsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  EventsNotifier create() => EventsNotifier();

  @override
  bool operator ==(Object other) {
    return other is EventsNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$eventsNotifierHash() => r'9a6f79a2e27ebb96ca189377b7bd33c46e65a828';

/// Events notifier that implements cache-first loading with background refresh.
/// Family provider scoped by scopeKey to support multiple independent event lists.

final class EventsNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          EventsNotifier,
          AsyncValue<EventsUiState>,
          EventsUiState,
          FutureOr<EventsUiState>,
          String
        > {
  EventsNotifierFamily._()
    : super(
        retry: null,
        name: r'eventsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Events notifier that implements cache-first loading with background refresh.
  /// Family provider scoped by scopeKey to support multiple independent event lists.

  EventsNotifierProvider call(String scopeKey) =>
      EventsNotifierProvider._(argument: scopeKey, from: this);

  @override
  String toString() => r'eventsProvider';
}

/// Events notifier that implements cache-first loading with background refresh.
/// Family provider scoped by scopeKey to support multiple independent event lists.

abstract class _$EventsNotifier extends $AsyncNotifier<EventsUiState> {
  late final _$args = ref.$arg as String;
  String get scopeKey => _$args;

  FutureOr<EventsUiState> build(String scopeKey);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<EventsUiState>, EventsUiState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<EventsUiState>, EventsUiState>,
              AsyncValue<EventsUiState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
