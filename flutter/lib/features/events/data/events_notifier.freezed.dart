// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'events_notifier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EventsUiState {

 List<EventsTableData> get events; bool get isLoading; bool get isRefreshing; bool get isLoadingMore; Object? get error; int get currentPage; bool get hasMorePages;
/// Create a copy of EventsUiState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EventsUiStateCopyWith<EventsUiState> get copyWith => _$EventsUiStateCopyWithImpl<EventsUiState>(this as EventsUiState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EventsUiState&&const DeepCollectionEquality().equals(other.events, events)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isRefreshing, isRefreshing) || other.isRefreshing == isRefreshing)&&(identical(other.isLoadingMore, isLoadingMore) || other.isLoadingMore == isLoadingMore)&&const DeepCollectionEquality().equals(other.error, error)&&(identical(other.currentPage, currentPage) || other.currentPage == currentPage)&&(identical(other.hasMorePages, hasMorePages) || other.hasMorePages == hasMorePages));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(events),isLoading,isRefreshing,isLoadingMore,const DeepCollectionEquality().hash(error),currentPage,hasMorePages);

@override
String toString() {
  return 'EventsUiState(events: $events, isLoading: $isLoading, isRefreshing: $isRefreshing, isLoadingMore: $isLoadingMore, error: $error, currentPage: $currentPage, hasMorePages: $hasMorePages)';
}


}

/// @nodoc
abstract mixin class $EventsUiStateCopyWith<$Res>  {
  factory $EventsUiStateCopyWith(EventsUiState value, $Res Function(EventsUiState) _then) = _$EventsUiStateCopyWithImpl;
@useResult
$Res call({
 List<EventsTableData> events, bool isLoading, bool isRefreshing, bool isLoadingMore, Object? error, int currentPage, bool hasMorePages
});




}
/// @nodoc
class _$EventsUiStateCopyWithImpl<$Res>
    implements $EventsUiStateCopyWith<$Res> {
  _$EventsUiStateCopyWithImpl(this._self, this._then);

  final EventsUiState _self;
  final $Res Function(EventsUiState) _then;

/// Create a copy of EventsUiState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? events = null,Object? isLoading = null,Object? isRefreshing = null,Object? isLoadingMore = null,Object? error = freezed,Object? currentPage = null,Object? hasMorePages = null,}) {
  return _then(_self.copyWith(
events: null == events ? _self.events : events // ignore: cast_nullable_to_non_nullable
as List<EventsTableData>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isRefreshing: null == isRefreshing ? _self.isRefreshing : isRefreshing // ignore: cast_nullable_to_non_nullable
as bool,isLoadingMore: null == isLoadingMore ? _self.isLoadingMore : isLoadingMore // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error ,currentPage: null == currentPage ? _self.currentPage : currentPage // ignore: cast_nullable_to_non_nullable
as int,hasMorePages: null == hasMorePages ? _self.hasMorePages : hasMorePages // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [EventsUiState].
extension EventsUiStatePatterns on EventsUiState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EventsUiState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EventsUiState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EventsUiState value)  $default,){
final _that = this;
switch (_that) {
case _EventsUiState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EventsUiState value)?  $default,){
final _that = this;
switch (_that) {
case _EventsUiState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<EventsTableData> events,  bool isLoading,  bool isRefreshing,  bool isLoadingMore,  Object? error,  int currentPage,  bool hasMorePages)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EventsUiState() when $default != null:
return $default(_that.events,_that.isLoading,_that.isRefreshing,_that.isLoadingMore,_that.error,_that.currentPage,_that.hasMorePages);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<EventsTableData> events,  bool isLoading,  bool isRefreshing,  bool isLoadingMore,  Object? error,  int currentPage,  bool hasMorePages)  $default,) {final _that = this;
switch (_that) {
case _EventsUiState():
return $default(_that.events,_that.isLoading,_that.isRefreshing,_that.isLoadingMore,_that.error,_that.currentPage,_that.hasMorePages);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<EventsTableData> events,  bool isLoading,  bool isRefreshing,  bool isLoadingMore,  Object? error,  int currentPage,  bool hasMorePages)?  $default,) {final _that = this;
switch (_that) {
case _EventsUiState() when $default != null:
return $default(_that.events,_that.isLoading,_that.isRefreshing,_that.isLoadingMore,_that.error,_that.currentPage,_that.hasMorePages);case _:
  return null;

}
}

}

/// @nodoc


class _EventsUiState extends EventsUiState {
  const _EventsUiState({required final  List<EventsTableData> events, required this.isLoading, required this.isRefreshing, this.isLoadingMore = false, this.error, required this.currentPage, required this.hasMorePages}): _events = events,super._();
  

 final  List<EventsTableData> _events;
@override List<EventsTableData> get events {
  if (_events is EqualUnmodifiableListView) return _events;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_events);
}

@override final  bool isLoading;
@override final  bool isRefreshing;
@override@JsonKey() final  bool isLoadingMore;
@override final  Object? error;
@override final  int currentPage;
@override final  bool hasMorePages;

/// Create a copy of EventsUiState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EventsUiStateCopyWith<_EventsUiState> get copyWith => __$EventsUiStateCopyWithImpl<_EventsUiState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EventsUiState&&const DeepCollectionEquality().equals(other._events, _events)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isRefreshing, isRefreshing) || other.isRefreshing == isRefreshing)&&(identical(other.isLoadingMore, isLoadingMore) || other.isLoadingMore == isLoadingMore)&&const DeepCollectionEquality().equals(other.error, error)&&(identical(other.currentPage, currentPage) || other.currentPage == currentPage)&&(identical(other.hasMorePages, hasMorePages) || other.hasMorePages == hasMorePages));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_events),isLoading,isRefreshing,isLoadingMore,const DeepCollectionEquality().hash(error),currentPage,hasMorePages);

@override
String toString() {
  return 'EventsUiState(events: $events, isLoading: $isLoading, isRefreshing: $isRefreshing, isLoadingMore: $isLoadingMore, error: $error, currentPage: $currentPage, hasMorePages: $hasMorePages)';
}


}

/// @nodoc
abstract mixin class _$EventsUiStateCopyWith<$Res> implements $EventsUiStateCopyWith<$Res> {
  factory _$EventsUiStateCopyWith(_EventsUiState value, $Res Function(_EventsUiState) _then) = __$EventsUiStateCopyWithImpl;
@override @useResult
$Res call({
 List<EventsTableData> events, bool isLoading, bool isRefreshing, bool isLoadingMore, Object? error, int currentPage, bool hasMorePages
});




}
/// @nodoc
class __$EventsUiStateCopyWithImpl<$Res>
    implements _$EventsUiStateCopyWith<$Res> {
  __$EventsUiStateCopyWithImpl(this._self, this._then);

  final _EventsUiState _self;
  final $Res Function(_EventsUiState) _then;

/// Create a copy of EventsUiState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? events = null,Object? isLoading = null,Object? isRefreshing = null,Object? isLoadingMore = null,Object? error = freezed,Object? currentPage = null,Object? hasMorePages = null,}) {
  return _then(_EventsUiState(
events: null == events ? _self._events : events // ignore: cast_nullable_to_non_nullable
as List<EventsTableData>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isRefreshing: null == isRefreshing ? _self.isRefreshing : isRefreshing // ignore: cast_nullable_to_non_nullable
as bool,isLoadingMore: null == isLoadingMore ? _self.isLoadingMore : isLoadingMore // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error ,currentPage: null == currentPage ? _self.currentPage : currentPage // ignore: cast_nullable_to_non_nullable
as int,hasMorePages: null == hasMorePages ? _self.hasMorePages : hasMorePages // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
