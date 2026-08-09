// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'featured_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FeaturedEvent {

 String get id; EventDetail get event; String get blurb; DateTime get createdAt; String get createdBy;
/// Create a copy of FeaturedEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FeaturedEventCopyWith<FeaturedEvent> get copyWith => _$FeaturedEventCopyWithImpl<FeaturedEvent>(this as FeaturedEvent, _$identity);

  /// Serializes this FeaturedEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FeaturedEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.event, event) || other.event == event)&&(identical(other.blurb, blurb) || other.blurb == blurb)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,event,blurb,createdAt,createdBy);

@override
String toString() {
  return 'FeaturedEvent(id: $id, event: $event, blurb: $blurb, createdAt: $createdAt, createdBy: $createdBy)';
}


}

/// @nodoc
abstract mixin class $FeaturedEventCopyWith<$Res>  {
  factory $FeaturedEventCopyWith(FeaturedEvent value, $Res Function(FeaturedEvent) _then) = _$FeaturedEventCopyWithImpl;
@useResult
$Res call({
 String id, EventDetail event, String blurb, DateTime createdAt, String createdBy
});


$EventDetailCopyWith<$Res> get event;

}
/// @nodoc
class _$FeaturedEventCopyWithImpl<$Res>
    implements $FeaturedEventCopyWith<$Res> {
  _$FeaturedEventCopyWithImpl(this._self, this._then);

  final FeaturedEvent _self;
  final $Res Function(FeaturedEvent) _then;

/// Create a copy of FeaturedEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? event = null,Object? blurb = null,Object? createdAt = null,Object? createdBy = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,event: null == event ? _self.event : event // ignore: cast_nullable_to_non_nullable
as EventDetail,blurb: null == blurb ? _self.blurb : blurb // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of FeaturedEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EventDetailCopyWith<$Res> get event {
  
  return $EventDetailCopyWith<$Res>(_self.event, (value) {
    return _then(_self.copyWith(event: value));
  });
}
}


/// Adds pattern-matching-related methods to [FeaturedEvent].
extension FeaturedEventPatterns on FeaturedEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FeaturedEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FeaturedEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FeaturedEvent value)  $default,){
final _that = this;
switch (_that) {
case _FeaturedEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FeaturedEvent value)?  $default,){
final _that = this;
switch (_that) {
case _FeaturedEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  EventDetail event,  String blurb,  DateTime createdAt,  String createdBy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FeaturedEvent() when $default != null:
return $default(_that.id,_that.event,_that.blurb,_that.createdAt,_that.createdBy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  EventDetail event,  String blurb,  DateTime createdAt,  String createdBy)  $default,) {final _that = this;
switch (_that) {
case _FeaturedEvent():
return $default(_that.id,_that.event,_that.blurb,_that.createdAt,_that.createdBy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  EventDetail event,  String blurb,  DateTime createdAt,  String createdBy)?  $default,) {final _that = this;
switch (_that) {
case _FeaturedEvent() when $default != null:
return $default(_that.id,_that.event,_that.blurb,_that.createdAt,_that.createdBy);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FeaturedEvent implements FeaturedEvent {
  const _FeaturedEvent({required this.id, required this.event, required this.blurb, required this.createdAt, required this.createdBy});
  factory _FeaturedEvent.fromJson(Map<String, dynamic> json) => _$FeaturedEventFromJson(json);

@override final  String id;
@override final  EventDetail event;
@override final  String blurb;
@override final  DateTime createdAt;
@override final  String createdBy;

/// Create a copy of FeaturedEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FeaturedEventCopyWith<_FeaturedEvent> get copyWith => __$FeaturedEventCopyWithImpl<_FeaturedEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FeaturedEventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FeaturedEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.event, event) || other.event == event)&&(identical(other.blurb, blurb) || other.blurb == blurb)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,event,blurb,createdAt,createdBy);

@override
String toString() {
  return 'FeaturedEvent(id: $id, event: $event, blurb: $blurb, createdAt: $createdAt, createdBy: $createdBy)';
}


}

/// @nodoc
abstract mixin class _$FeaturedEventCopyWith<$Res> implements $FeaturedEventCopyWith<$Res> {
  factory _$FeaturedEventCopyWith(_FeaturedEvent value, $Res Function(_FeaturedEvent) _then) = __$FeaturedEventCopyWithImpl;
@override @useResult
$Res call({
 String id, EventDetail event, String blurb, DateTime createdAt, String createdBy
});


@override $EventDetailCopyWith<$Res> get event;

}
/// @nodoc
class __$FeaturedEventCopyWithImpl<$Res>
    implements _$FeaturedEventCopyWith<$Res> {
  __$FeaturedEventCopyWithImpl(this._self, this._then);

  final _FeaturedEvent _self;
  final $Res Function(_FeaturedEvent) _then;

/// Create a copy of FeaturedEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? event = null,Object? blurb = null,Object? createdAt = null,Object? createdBy = null,}) {
  return _then(_FeaturedEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,event: null == event ? _self.event : event // ignore: cast_nullable_to_non_nullable
as EventDetail,blurb: null == blurb ? _self.blurb : blurb // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of FeaturedEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EventDetailCopyWith<$Res> get event {
  
  return $EventDetailCopyWith<$Res>(_self.event, (value) {
    return _then(_self.copyWith(event: value));
  });
}
}

// dart format on
