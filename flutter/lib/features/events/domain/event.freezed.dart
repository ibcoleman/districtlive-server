// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Event {

 String get id; String get title; String get slug; DateTime get startTime; DateTime? get doorsTime; Venue? get venue; List<Artist> get artists; double? get minPrice; double? get maxPrice; PriceTier? get priceTier; String? get ticketUrl; bool get soldOut; String? get imageUrl; AgeRestriction get ageRestriction; EventStatus get status; String? get description; DateTime? get createdAt;
/// Create a copy of Event
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EventCopyWith<Event> get copyWith => _$EventCopyWithImpl<Event>(this as Event, _$identity);

  /// Serializes this Event to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Event&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.doorsTime, doorsTime) || other.doorsTime == doorsTime)&&(identical(other.venue, venue) || other.venue == venue)&&const DeepCollectionEquality().equals(other.artists, artists)&&(identical(other.minPrice, minPrice) || other.minPrice == minPrice)&&(identical(other.maxPrice, maxPrice) || other.maxPrice == maxPrice)&&(identical(other.priceTier, priceTier) || other.priceTier == priceTier)&&(identical(other.ticketUrl, ticketUrl) || other.ticketUrl == ticketUrl)&&(identical(other.soldOut, soldOut) || other.soldOut == soldOut)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.ageRestriction, ageRestriction) || other.ageRestriction == ageRestriction)&&(identical(other.status, status) || other.status == status)&&(identical(other.description, description) || other.description == description)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,slug,startTime,doorsTime,venue,const DeepCollectionEquality().hash(artists),minPrice,maxPrice,priceTier,ticketUrl,soldOut,imageUrl,ageRestriction,status,description,createdAt);

@override
String toString() {
  return 'Event(id: $id, title: $title, slug: $slug, startTime: $startTime, doorsTime: $doorsTime, venue: $venue, artists: $artists, minPrice: $minPrice, maxPrice: $maxPrice, priceTier: $priceTier, ticketUrl: $ticketUrl, soldOut: $soldOut, imageUrl: $imageUrl, ageRestriction: $ageRestriction, status: $status, description: $description, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $EventCopyWith<$Res>  {
  factory $EventCopyWith(Event value, $Res Function(Event) _then) = _$EventCopyWithImpl;
@useResult
$Res call({
 String id, String title, String slug, DateTime startTime, DateTime? doorsTime, Venue? venue, List<Artist> artists, double? minPrice, double? maxPrice, PriceTier? priceTier, String? ticketUrl, bool soldOut, String? imageUrl, AgeRestriction ageRestriction, EventStatus status, String? description, DateTime? createdAt
});


$VenueCopyWith<$Res>? get venue;

}
/// @nodoc
class _$EventCopyWithImpl<$Res>
    implements $EventCopyWith<$Res> {
  _$EventCopyWithImpl(this._self, this._then);

  final Event _self;
  final $Res Function(Event) _then;

/// Create a copy of Event
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? slug = null,Object? startTime = null,Object? doorsTime = freezed,Object? venue = freezed,Object? artists = null,Object? minPrice = freezed,Object? maxPrice = freezed,Object? priceTier = freezed,Object? ticketUrl = freezed,Object? soldOut = null,Object? imageUrl = freezed,Object? ageRestriction = null,Object? status = null,Object? description = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as DateTime,doorsTime: freezed == doorsTime ? _self.doorsTime : doorsTime // ignore: cast_nullable_to_non_nullable
as DateTime?,venue: freezed == venue ? _self.venue : venue // ignore: cast_nullable_to_non_nullable
as Venue?,artists: null == artists ? _self.artists : artists // ignore: cast_nullable_to_non_nullable
as List<Artist>,minPrice: freezed == minPrice ? _self.minPrice : minPrice // ignore: cast_nullable_to_non_nullable
as double?,maxPrice: freezed == maxPrice ? _self.maxPrice : maxPrice // ignore: cast_nullable_to_non_nullable
as double?,priceTier: freezed == priceTier ? _self.priceTier : priceTier // ignore: cast_nullable_to_non_nullable
as PriceTier?,ticketUrl: freezed == ticketUrl ? _self.ticketUrl : ticketUrl // ignore: cast_nullable_to_non_nullable
as String?,soldOut: null == soldOut ? _self.soldOut : soldOut // ignore: cast_nullable_to_non_nullable
as bool,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,ageRestriction: null == ageRestriction ? _self.ageRestriction : ageRestriction // ignore: cast_nullable_to_non_nullable
as AgeRestriction,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as EventStatus,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of Event
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VenueCopyWith<$Res>? get venue {
    if (_self.venue == null) {
    return null;
  }

  return $VenueCopyWith<$Res>(_self.venue!, (value) {
    return _then(_self.copyWith(venue: value));
  });
}
}


/// Adds pattern-matching-related methods to [Event].
extension EventPatterns on Event {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Event value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Event() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Event value)  $default,){
final _that = this;
switch (_that) {
case _Event():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Event value)?  $default,){
final _that = this;
switch (_that) {
case _Event() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String slug,  DateTime startTime,  DateTime? doorsTime,  Venue? venue,  List<Artist> artists,  double? minPrice,  double? maxPrice,  PriceTier? priceTier,  String? ticketUrl,  bool soldOut,  String? imageUrl,  AgeRestriction ageRestriction,  EventStatus status,  String? description,  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Event() when $default != null:
return $default(_that.id,_that.title,_that.slug,_that.startTime,_that.doorsTime,_that.venue,_that.artists,_that.minPrice,_that.maxPrice,_that.priceTier,_that.ticketUrl,_that.soldOut,_that.imageUrl,_that.ageRestriction,_that.status,_that.description,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String slug,  DateTime startTime,  DateTime? doorsTime,  Venue? venue,  List<Artist> artists,  double? minPrice,  double? maxPrice,  PriceTier? priceTier,  String? ticketUrl,  bool soldOut,  String? imageUrl,  AgeRestriction ageRestriction,  EventStatus status,  String? description,  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _Event():
return $default(_that.id,_that.title,_that.slug,_that.startTime,_that.doorsTime,_that.venue,_that.artists,_that.minPrice,_that.maxPrice,_that.priceTier,_that.ticketUrl,_that.soldOut,_that.imageUrl,_that.ageRestriction,_that.status,_that.description,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String slug,  DateTime startTime,  DateTime? doorsTime,  Venue? venue,  List<Artist> artists,  double? minPrice,  double? maxPrice,  PriceTier? priceTier,  String? ticketUrl,  bool soldOut,  String? imageUrl,  AgeRestriction ageRestriction,  EventStatus status,  String? description,  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Event() when $default != null:
return $default(_that.id,_that.title,_that.slug,_that.startTime,_that.doorsTime,_that.venue,_that.artists,_that.minPrice,_that.maxPrice,_that.priceTier,_that.ticketUrl,_that.soldOut,_that.imageUrl,_that.ageRestriction,_that.status,_that.description,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Event implements Event {
  const _Event({required this.id, required this.title, required this.slug, required this.startTime, this.doorsTime, this.venue, final  List<Artist> artists = const [], this.minPrice, this.maxPrice, this.priceTier, this.ticketUrl, this.soldOut = false, this.imageUrl, this.ageRestriction = AgeRestriction.ALL_AGES, this.status = EventStatus.ACTIVE, this.description, this.createdAt}): _artists = artists;
  factory _Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);

@override final  String id;
@override final  String title;
@override final  String slug;
@override final  DateTime startTime;
@override final  DateTime? doorsTime;
@override final  Venue? venue;
 final  List<Artist> _artists;
@override@JsonKey() List<Artist> get artists {
  if (_artists is EqualUnmodifiableListView) return _artists;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_artists);
}

@override final  double? minPrice;
@override final  double? maxPrice;
@override final  PriceTier? priceTier;
@override final  String? ticketUrl;
@override@JsonKey() final  bool soldOut;
@override final  String? imageUrl;
@override@JsonKey() final  AgeRestriction ageRestriction;
@override@JsonKey() final  EventStatus status;
@override final  String? description;
@override final  DateTime? createdAt;

/// Create a copy of Event
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EventCopyWith<_Event> get copyWith => __$EventCopyWithImpl<_Event>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Event&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.doorsTime, doorsTime) || other.doorsTime == doorsTime)&&(identical(other.venue, venue) || other.venue == venue)&&const DeepCollectionEquality().equals(other._artists, _artists)&&(identical(other.minPrice, minPrice) || other.minPrice == minPrice)&&(identical(other.maxPrice, maxPrice) || other.maxPrice == maxPrice)&&(identical(other.priceTier, priceTier) || other.priceTier == priceTier)&&(identical(other.ticketUrl, ticketUrl) || other.ticketUrl == ticketUrl)&&(identical(other.soldOut, soldOut) || other.soldOut == soldOut)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.ageRestriction, ageRestriction) || other.ageRestriction == ageRestriction)&&(identical(other.status, status) || other.status == status)&&(identical(other.description, description) || other.description == description)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,slug,startTime,doorsTime,venue,const DeepCollectionEquality().hash(_artists),minPrice,maxPrice,priceTier,ticketUrl,soldOut,imageUrl,ageRestriction,status,description,createdAt);

@override
String toString() {
  return 'Event(id: $id, title: $title, slug: $slug, startTime: $startTime, doorsTime: $doorsTime, venue: $venue, artists: $artists, minPrice: $minPrice, maxPrice: $maxPrice, priceTier: $priceTier, ticketUrl: $ticketUrl, soldOut: $soldOut, imageUrl: $imageUrl, ageRestriction: $ageRestriction, status: $status, description: $description, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$EventCopyWith<$Res> implements $EventCopyWith<$Res> {
  factory _$EventCopyWith(_Event value, $Res Function(_Event) _then) = __$EventCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String slug, DateTime startTime, DateTime? doorsTime, Venue? venue, List<Artist> artists, double? minPrice, double? maxPrice, PriceTier? priceTier, String? ticketUrl, bool soldOut, String? imageUrl, AgeRestriction ageRestriction, EventStatus status, String? description, DateTime? createdAt
});


@override $VenueCopyWith<$Res>? get venue;

}
/// @nodoc
class __$EventCopyWithImpl<$Res>
    implements _$EventCopyWith<$Res> {
  __$EventCopyWithImpl(this._self, this._then);

  final _Event _self;
  final $Res Function(_Event) _then;

/// Create a copy of Event
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? slug = null,Object? startTime = null,Object? doorsTime = freezed,Object? venue = freezed,Object? artists = null,Object? minPrice = freezed,Object? maxPrice = freezed,Object? priceTier = freezed,Object? ticketUrl = freezed,Object? soldOut = null,Object? imageUrl = freezed,Object? ageRestriction = null,Object? status = null,Object? description = freezed,Object? createdAt = freezed,}) {
  return _then(_Event(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as DateTime,doorsTime: freezed == doorsTime ? _self.doorsTime : doorsTime // ignore: cast_nullable_to_non_nullable
as DateTime?,venue: freezed == venue ? _self.venue : venue // ignore: cast_nullable_to_non_nullable
as Venue?,artists: null == artists ? _self._artists : artists // ignore: cast_nullable_to_non_nullable
as List<Artist>,minPrice: freezed == minPrice ? _self.minPrice : minPrice // ignore: cast_nullable_to_non_nullable
as double?,maxPrice: freezed == maxPrice ? _self.maxPrice : maxPrice // ignore: cast_nullable_to_non_nullable
as double?,priceTier: freezed == priceTier ? _self.priceTier : priceTier // ignore: cast_nullable_to_non_nullable
as PriceTier?,ticketUrl: freezed == ticketUrl ? _self.ticketUrl : ticketUrl // ignore: cast_nullable_to_non_nullable
as String?,soldOut: null == soldOut ? _self.soldOut : soldOut // ignore: cast_nullable_to_non_nullable
as bool,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,ageRestriction: null == ageRestriction ? _self.ageRestriction : ageRestriction // ignore: cast_nullable_to_non_nullable
as AgeRestriction,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as EventStatus,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of Event
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VenueCopyWith<$Res>? get venue {
    if (_self.venue == null) {
    return null;
  }

  return $VenueCopyWith<$Res>(_self.venue!, (value) {
    return _then(_self.copyWith(venue: value));
  });
}
}

// dart format on
