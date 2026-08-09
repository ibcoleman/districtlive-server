// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_detail_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(EventDetailNotifier)
final eventDetailProvider = EventDetailNotifierFamily._();

final class EventDetailNotifierProvider
    extends $AsyncNotifierProvider<EventDetailNotifier, EventDetail> {
  EventDetailNotifierProvider._({
    required EventDetailNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'eventDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$eventDetailNotifierHash();

  @override
  String toString() {
    return r'eventDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  EventDetailNotifier create() => EventDetailNotifier();

  @override
  bool operator ==(Object other) {
    return other is EventDetailNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$eventDetailNotifierHash() =>
    r'3ba4b79b38ddf0be3d46d4991c7f306f8f7e5954';

final class EventDetailNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          EventDetailNotifier,
          AsyncValue<EventDetail>,
          EventDetail,
          FutureOr<EventDetail>,
          String
        > {
  EventDetailNotifierFamily._()
    : super(
        retry: null,
        name: r'eventDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  EventDetailNotifierProvider call(String eventId) =>
      EventDetailNotifierProvider._(argument: eventId, from: this);

  @override
  String toString() => r'eventDetailProvider';
}

abstract class _$EventDetailNotifier extends $AsyncNotifier<EventDetail> {
  late final _$args = ref.$arg as String;
  String get eventId => _$args;

  FutureOr<EventDetail> build(String eventId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<EventDetail>, EventDetail>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<EventDetail>, EventDetail>,
              AsyncValue<EventDetail>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
