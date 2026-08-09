// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'featured_ui_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FeaturedUiState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FeaturedUiState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'FeaturedUiState()';
}


}

/// @nodoc
class $FeaturedUiStateCopyWith<$Res>  {
$FeaturedUiStateCopyWith(FeaturedUiState _, $Res Function(FeaturedUiState) __);
}


/// Adds pattern-matching-related methods to [FeaturedUiState].
extension FeaturedUiStatePatterns on FeaturedUiState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( FeaturedLoading value)?  loading,TResult Function( FeaturedCurated value)?  curated,TResult Function( FeaturedFallbackHero value)?  fallbackHero,TResult Function( FeaturedError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case FeaturedLoading() when loading != null:
return loading(_that);case FeaturedCurated() when curated != null:
return curated(_that);case FeaturedFallbackHero() when fallbackHero != null:
return fallbackHero(_that);case FeaturedError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( FeaturedLoading value)  loading,required TResult Function( FeaturedCurated value)  curated,required TResult Function( FeaturedFallbackHero value)  fallbackHero,required TResult Function( FeaturedError value)  error,}){
final _that = this;
switch (_that) {
case FeaturedLoading():
return loading(_that);case FeaturedCurated():
return curated(_that);case FeaturedFallbackHero():
return fallbackHero(_that);case FeaturedError():
return error(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( FeaturedLoading value)?  loading,TResult? Function( FeaturedCurated value)?  curated,TResult? Function( FeaturedFallbackHero value)?  fallbackHero,TResult? Function( FeaturedError value)?  error,}){
final _that = this;
switch (_that) {
case FeaturedLoading() when loading != null:
return loading(_that);case FeaturedCurated() when curated != null:
return curated(_that);case FeaturedFallbackHero() when fallbackHero != null:
return fallbackHero(_that);case FeaturedError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( FeaturedEvent featuredEvent,  bool isRefreshing)?  curated,TResult Function( Event? event,  bool isRefreshing)?  fallbackHero,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case FeaturedLoading() when loading != null:
return loading();case FeaturedCurated() when curated != null:
return curated(_that.featuredEvent,_that.isRefreshing);case FeaturedFallbackHero() when fallbackHero != null:
return fallbackHero(_that.event,_that.isRefreshing);case FeaturedError() when error != null:
return error(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( FeaturedEvent featuredEvent,  bool isRefreshing)  curated,required TResult Function( Event? event,  bool isRefreshing)  fallbackHero,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case FeaturedLoading():
return loading();case FeaturedCurated():
return curated(_that.featuredEvent,_that.isRefreshing);case FeaturedFallbackHero():
return fallbackHero(_that.event,_that.isRefreshing);case FeaturedError():
return error(_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( FeaturedEvent featuredEvent,  bool isRefreshing)?  curated,TResult? Function( Event? event,  bool isRefreshing)?  fallbackHero,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case FeaturedLoading() when loading != null:
return loading();case FeaturedCurated() when curated != null:
return curated(_that.featuredEvent,_that.isRefreshing);case FeaturedFallbackHero() when fallbackHero != null:
return fallbackHero(_that.event,_that.isRefreshing);case FeaturedError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class FeaturedLoading implements FeaturedUiState {
  const FeaturedLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FeaturedLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'FeaturedUiState.loading()';
}


}




/// @nodoc


class FeaturedCurated implements FeaturedUiState {
  const FeaturedCurated({required this.featuredEvent, this.isRefreshing = false});
  

 final  FeaturedEvent featuredEvent;
@JsonKey() final  bool isRefreshing;

/// Create a copy of FeaturedUiState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FeaturedCuratedCopyWith<FeaturedCurated> get copyWith => _$FeaturedCuratedCopyWithImpl<FeaturedCurated>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FeaturedCurated&&(identical(other.featuredEvent, featuredEvent) || other.featuredEvent == featuredEvent)&&(identical(other.isRefreshing, isRefreshing) || other.isRefreshing == isRefreshing));
}


@override
int get hashCode => Object.hash(runtimeType,featuredEvent,isRefreshing);

@override
String toString() {
  return 'FeaturedUiState.curated(featuredEvent: $featuredEvent, isRefreshing: $isRefreshing)';
}


}

/// @nodoc
abstract mixin class $FeaturedCuratedCopyWith<$Res> implements $FeaturedUiStateCopyWith<$Res> {
  factory $FeaturedCuratedCopyWith(FeaturedCurated value, $Res Function(FeaturedCurated) _then) = _$FeaturedCuratedCopyWithImpl;
@useResult
$Res call({
 FeaturedEvent featuredEvent, bool isRefreshing
});


$FeaturedEventCopyWith<$Res> get featuredEvent;

}
/// @nodoc
class _$FeaturedCuratedCopyWithImpl<$Res>
    implements $FeaturedCuratedCopyWith<$Res> {
  _$FeaturedCuratedCopyWithImpl(this._self, this._then);

  final FeaturedCurated _self;
  final $Res Function(FeaturedCurated) _then;

/// Create a copy of FeaturedUiState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? featuredEvent = null,Object? isRefreshing = null,}) {
  return _then(FeaturedCurated(
featuredEvent: null == featuredEvent ? _self.featuredEvent : featuredEvent // ignore: cast_nullable_to_non_nullable
as FeaturedEvent,isRefreshing: null == isRefreshing ? _self.isRefreshing : isRefreshing // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of FeaturedUiState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FeaturedEventCopyWith<$Res> get featuredEvent {
  
  return $FeaturedEventCopyWith<$Res>(_self.featuredEvent, (value) {
    return _then(_self.copyWith(featuredEvent: value));
  });
}
}

/// @nodoc


class FeaturedFallbackHero implements FeaturedUiState {
  const FeaturedFallbackHero({this.event, this.isRefreshing = false});
  

 final  Event? event;
@JsonKey() final  bool isRefreshing;

/// Create a copy of FeaturedUiState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FeaturedFallbackHeroCopyWith<FeaturedFallbackHero> get copyWith => _$FeaturedFallbackHeroCopyWithImpl<FeaturedFallbackHero>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FeaturedFallbackHero&&(identical(other.event, event) || other.event == event)&&(identical(other.isRefreshing, isRefreshing) || other.isRefreshing == isRefreshing));
}


@override
int get hashCode => Object.hash(runtimeType,event,isRefreshing);

@override
String toString() {
  return 'FeaturedUiState.fallbackHero(event: $event, isRefreshing: $isRefreshing)';
}


}

/// @nodoc
abstract mixin class $FeaturedFallbackHeroCopyWith<$Res> implements $FeaturedUiStateCopyWith<$Res> {
  factory $FeaturedFallbackHeroCopyWith(FeaturedFallbackHero value, $Res Function(FeaturedFallbackHero) _then) = _$FeaturedFallbackHeroCopyWithImpl;
@useResult
$Res call({
 Event? event, bool isRefreshing
});


$EventCopyWith<$Res>? get event;

}
/// @nodoc
class _$FeaturedFallbackHeroCopyWithImpl<$Res>
    implements $FeaturedFallbackHeroCopyWith<$Res> {
  _$FeaturedFallbackHeroCopyWithImpl(this._self, this._then);

  final FeaturedFallbackHero _self;
  final $Res Function(FeaturedFallbackHero) _then;

/// Create a copy of FeaturedUiState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? event = freezed,Object? isRefreshing = null,}) {
  return _then(FeaturedFallbackHero(
event: freezed == event ? _self.event : event // ignore: cast_nullable_to_non_nullable
as Event?,isRefreshing: null == isRefreshing ? _self.isRefreshing : isRefreshing // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of FeaturedUiState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EventCopyWith<$Res>? get event {
    if (_self.event == null) {
    return null;
  }

  return $EventCopyWith<$Res>(_self.event!, (value) {
    return _then(_self.copyWith(event: value));
  });
}
}

/// @nodoc


class FeaturedError implements FeaturedUiState {
  const FeaturedError({required this.message});
  

 final  String message;

/// Create a copy of FeaturedUiState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FeaturedErrorCopyWith<FeaturedError> get copyWith => _$FeaturedErrorCopyWithImpl<FeaturedError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FeaturedError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'FeaturedUiState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $FeaturedErrorCopyWith<$Res> implements $FeaturedUiStateCopyWith<$Res> {
  factory $FeaturedErrorCopyWith(FeaturedError value, $Res Function(FeaturedError) _then) = _$FeaturedErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$FeaturedErrorCopyWithImpl<$Res>
    implements $FeaturedErrorCopyWith<$Res> {
  _$FeaturedErrorCopyWithImpl(this._self, this._then);

  final FeaturedError _self;
  final $Res Function(FeaturedError) _then;

/// Create a copy of FeaturedUiState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(FeaturedError(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
