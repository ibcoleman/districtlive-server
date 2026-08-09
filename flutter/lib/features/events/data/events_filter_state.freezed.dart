// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'events_filter_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EventsFilterState {

 DatePreset get datePreset; String? get selectedVenueId; String? get selectedVenueName; String? get selectedVenueSlug; String? get selectedGenre; String? get sort;
/// Create a copy of EventsFilterState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EventsFilterStateCopyWith<EventsFilterState> get copyWith => _$EventsFilterStateCopyWithImpl<EventsFilterState>(this as EventsFilterState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EventsFilterState&&(identical(other.datePreset, datePreset) || other.datePreset == datePreset)&&(identical(other.selectedVenueId, selectedVenueId) || other.selectedVenueId == selectedVenueId)&&(identical(other.selectedVenueName, selectedVenueName) || other.selectedVenueName == selectedVenueName)&&(identical(other.selectedVenueSlug, selectedVenueSlug) || other.selectedVenueSlug == selectedVenueSlug)&&(identical(other.selectedGenre, selectedGenre) || other.selectedGenre == selectedGenre)&&(identical(other.sort, sort) || other.sort == sort));
}


@override
int get hashCode => Object.hash(runtimeType,datePreset,selectedVenueId,selectedVenueName,selectedVenueSlug,selectedGenre,sort);

@override
String toString() {
  return 'EventsFilterState(datePreset: $datePreset, selectedVenueId: $selectedVenueId, selectedVenueName: $selectedVenueName, selectedVenueSlug: $selectedVenueSlug, selectedGenre: $selectedGenre, sort: $sort)';
}


}

/// @nodoc
abstract mixin class $EventsFilterStateCopyWith<$Res>  {
  factory $EventsFilterStateCopyWith(EventsFilterState value, $Res Function(EventsFilterState) _then) = _$EventsFilterStateCopyWithImpl;
@useResult
$Res call({
 DatePreset datePreset, String? selectedVenueId, String? selectedVenueName, String? selectedVenueSlug, String? selectedGenre, String? sort
});




}
/// @nodoc
class _$EventsFilterStateCopyWithImpl<$Res>
    implements $EventsFilterStateCopyWith<$Res> {
  _$EventsFilterStateCopyWithImpl(this._self, this._then);

  final EventsFilterState _self;
  final $Res Function(EventsFilterState) _then;

/// Create a copy of EventsFilterState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? datePreset = null,Object? selectedVenueId = freezed,Object? selectedVenueName = freezed,Object? selectedVenueSlug = freezed,Object? selectedGenre = freezed,Object? sort = freezed,}) {
  return _then(_self.copyWith(
datePreset: null == datePreset ? _self.datePreset : datePreset // ignore: cast_nullable_to_non_nullable
as DatePreset,selectedVenueId: freezed == selectedVenueId ? _self.selectedVenueId : selectedVenueId // ignore: cast_nullable_to_non_nullable
as String?,selectedVenueName: freezed == selectedVenueName ? _self.selectedVenueName : selectedVenueName // ignore: cast_nullable_to_non_nullable
as String?,selectedVenueSlug: freezed == selectedVenueSlug ? _self.selectedVenueSlug : selectedVenueSlug // ignore: cast_nullable_to_non_nullable
as String?,selectedGenre: freezed == selectedGenre ? _self.selectedGenre : selectedGenre // ignore: cast_nullable_to_non_nullable
as String?,sort: freezed == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [EventsFilterState].
extension EventsFilterStatePatterns on EventsFilterState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EventsFilterState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EventsFilterState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EventsFilterState value)  $default,){
final _that = this;
switch (_that) {
case _EventsFilterState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EventsFilterState value)?  $default,){
final _that = this;
switch (_that) {
case _EventsFilterState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DatePreset datePreset,  String? selectedVenueId,  String? selectedVenueName,  String? selectedVenueSlug,  String? selectedGenre,  String? sort)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EventsFilterState() when $default != null:
return $default(_that.datePreset,_that.selectedVenueId,_that.selectedVenueName,_that.selectedVenueSlug,_that.selectedGenre,_that.sort);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DatePreset datePreset,  String? selectedVenueId,  String? selectedVenueName,  String? selectedVenueSlug,  String? selectedGenre,  String? sort)  $default,) {final _that = this;
switch (_that) {
case _EventsFilterState():
return $default(_that.datePreset,_that.selectedVenueId,_that.selectedVenueName,_that.selectedVenueSlug,_that.selectedGenre,_that.sort);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DatePreset datePreset,  String? selectedVenueId,  String? selectedVenueName,  String? selectedVenueSlug,  String? selectedGenre,  String? sort)?  $default,) {final _that = this;
switch (_that) {
case _EventsFilterState() when $default != null:
return $default(_that.datePreset,_that.selectedVenueId,_that.selectedVenueName,_that.selectedVenueSlug,_that.selectedGenre,_that.sort);case _:
  return null;

}
}

}

/// @nodoc


class _EventsFilterState implements EventsFilterState {
  const _EventsFilterState({this.datePreset = DatePreset.thisWeek, this.selectedVenueId, this.selectedVenueName, this.selectedVenueSlug, this.selectedGenre, this.sort});
  

@override@JsonKey() final  DatePreset datePreset;
@override final  String? selectedVenueId;
@override final  String? selectedVenueName;
@override final  String? selectedVenueSlug;
@override final  String? selectedGenre;
@override final  String? sort;

/// Create a copy of EventsFilterState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EventsFilterStateCopyWith<_EventsFilterState> get copyWith => __$EventsFilterStateCopyWithImpl<_EventsFilterState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EventsFilterState&&(identical(other.datePreset, datePreset) || other.datePreset == datePreset)&&(identical(other.selectedVenueId, selectedVenueId) || other.selectedVenueId == selectedVenueId)&&(identical(other.selectedVenueName, selectedVenueName) || other.selectedVenueName == selectedVenueName)&&(identical(other.selectedVenueSlug, selectedVenueSlug) || other.selectedVenueSlug == selectedVenueSlug)&&(identical(other.selectedGenre, selectedGenre) || other.selectedGenre == selectedGenre)&&(identical(other.sort, sort) || other.sort == sort));
}


@override
int get hashCode => Object.hash(runtimeType,datePreset,selectedVenueId,selectedVenueName,selectedVenueSlug,selectedGenre,sort);

@override
String toString() {
  return 'EventsFilterState(datePreset: $datePreset, selectedVenueId: $selectedVenueId, selectedVenueName: $selectedVenueName, selectedVenueSlug: $selectedVenueSlug, selectedGenre: $selectedGenre, sort: $sort)';
}


}

/// @nodoc
abstract mixin class _$EventsFilterStateCopyWith<$Res> implements $EventsFilterStateCopyWith<$Res> {
  factory _$EventsFilterStateCopyWith(_EventsFilterState value, $Res Function(_EventsFilterState) _then) = __$EventsFilterStateCopyWithImpl;
@override @useResult
$Res call({
 DatePreset datePreset, String? selectedVenueId, String? selectedVenueName, String? selectedVenueSlug, String? selectedGenre, String? sort
});




}
/// @nodoc
class __$EventsFilterStateCopyWithImpl<$Res>
    implements _$EventsFilterStateCopyWith<$Res> {
  __$EventsFilterStateCopyWithImpl(this._self, this._then);

  final _EventsFilterState _self;
  final $Res Function(_EventsFilterState) _then;

/// Create a copy of EventsFilterState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? datePreset = null,Object? selectedVenueId = freezed,Object? selectedVenueName = freezed,Object? selectedVenueSlug = freezed,Object? selectedGenre = freezed,Object? sort = freezed,}) {
  return _then(_EventsFilterState(
datePreset: null == datePreset ? _self.datePreset : datePreset // ignore: cast_nullable_to_non_nullable
as DatePreset,selectedVenueId: freezed == selectedVenueId ? _self.selectedVenueId : selectedVenueId // ignore: cast_nullable_to_non_nullable
as String?,selectedVenueName: freezed == selectedVenueName ? _self.selectedVenueName : selectedVenueName // ignore: cast_nullable_to_non_nullable
as String?,selectedVenueSlug: freezed == selectedVenueSlug ? _self.selectedVenueSlug : selectedVenueSlug // ignore: cast_nullable_to_non_nullable
as String?,selectedGenre: freezed == selectedGenre ? _self.selectedGenre : selectedGenre // ignore: cast_nullable_to_non_nullable
as String?,sort: freezed == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
