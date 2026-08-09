// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'event_detail.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EventDetail {

 String get id; String get title; String get slug; DateTime get startTime; DateTime? get doorsTime; Venue? get venue; List<Artist> get artists; double? get minPrice; double? get maxPrice; PriceTier? get priceTier; String? get ticketUrl; bool get soldOut; String? get imageUrl; AgeRestriction get ageRestriction; EventStatus get status; String? get description; DateTime? get endTime; DateTime? get onSaleDate; String? get ticketPlatform; List<EventSource> get sources; List<Event> get relatedEvents;
/// Create a copy of EventDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EventDetailCopyWith<EventDetail> get copyWith => _$EventDetailCopyWithImpl<EventDetail>(this as EventDetail, _$identity);

  /// Serializes this EventDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EventDetail&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.doorsTime, doorsTime) || other.doorsTime == doorsTime)&&(identical(other.venue, venue) || other.venue == venue)&&const DeepCollectionEquality().equals(other.artists, artists)&&(identical(other.minPrice, minPrice) || other.minPrice == minPrice)&&(identical(other.maxPrice, maxPrice) || other.maxPrice == maxPrice)&&(identical(other.priceTier, priceTier) || other.priceTier == priceTier)&&(identical(other.ticketUrl, ticketUrl) || other.ticketUrl == ticketUrl)&&(identical(other.soldOut, soldOut) || other.soldOut == soldOut)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.ageRestriction, ageRestriction) || other.ageRestriction == ageRestriction)&&(identical(other.status, status) || other.status == status)&&(identical(other.description, description) || other.description == description)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.onSaleDate, onSaleDate) || other.onSaleDate == onSaleDate)&&(identical(other.ticketPlatform, ticketPlatform) || other.ticketPlatform == ticketPlatform)&&const DeepCollectionEquality().equals(other.sources, sources)&&const DeepCollectionEquality().equals(other.relatedEvents, relatedEvents));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,title,slug,startTime,doorsTime,venue,const DeepCollectionEquality().hash(artists),minPrice,maxPrice,priceTier,ticketUrl,soldOut,imageUrl,ageRestriction,status,description,endTime,onSaleDate,ticketPlatform,const DeepCollectionEquality().hash(sources),const DeepCollectionEquality().hash(relatedEvents)]);

@override
String toString() {
  return 'EventDetail(id: $id, title: $title, slug: $slug, startTime: $startTime, doorsTime: $doorsTime, venue: $venue, artists: $artists, minPrice: $minPrice, maxPrice: $maxPrice, priceTier: $priceTier, ticketUrl: $ticketUrl, soldOut: $soldOut, imageUrl: $imageUrl, ageRestriction: $ageRestriction, status: $status, description: $description, endTime: $endTime, onSaleDate: $onSaleDate, ticketPlatform: $ticketPlatform, sources: $sources, relatedEvents: $relatedEvents)';
}


}

/// @nodoc
abstract mixin class $EventDetailCopyWith<$Res>  {
  factory $EventDetailCopyWith(EventDetail value, $Res Function(EventDetail) _then) = _$EventDetailCopyWithImpl;
@useResult
$Res call({
 String id, String title, String slug, DateTime startTime, DateTime? doorsTime, Venue? venue, List<Artist> artists, double? minPrice, double? maxPrice, PriceTier? priceTier, String? ticketUrl, bool soldOut, String? imageUrl, AgeRestriction ageRestriction, EventStatus status, String? description, DateTime? endTime, DateTime? onSaleDate, String? ticketPlatform, List<EventSource> sources, List<Event> relatedEvents
});


$VenueCopyWith<$Res>? get venue;

}
/// @nodoc
class _$EventDetailCopyWithImpl<$Res>
    implements $EventDetailCopyWith<$Res> {
  _$EventDetailCopyWithImpl(this._self, this._then);

  final EventDetail _self;
  final $Res Function(EventDetail) _then;

/// Create a copy of EventDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? slug = null,Object? startTime = null,Object? doorsTime = freezed,Object? venue = freezed,Object? artists = null,Object? minPrice = freezed,Object? maxPrice = freezed,Object? priceTier = freezed,Object? ticketUrl = freezed,Object? soldOut = null,Object? imageUrl = freezed,Object? ageRestriction = null,Object? status = null,Object? description = freezed,Object? endTime = freezed,Object? onSaleDate = freezed,Object? ticketPlatform = freezed,Object? sources = null,Object? relatedEvents = null,}) {
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
as String?,endTime: freezed == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as DateTime?,onSaleDate: freezed == onSaleDate ? _self.onSaleDate : onSaleDate // ignore: cast_nullable_to_non_nullable
as DateTime?,ticketPlatform: freezed == ticketPlatform ? _self.ticketPlatform : ticketPlatform // ignore: cast_nullable_to_non_nullable
as String?,sources: null == sources ? _self.sources : sources // ignore: cast_nullable_to_non_nullable
as List<EventSource>,relatedEvents: null == relatedEvents ? _self.relatedEvents : relatedEvents // ignore: cast_nullable_to_non_nullable
as List<Event>,
  ));
}
/// Create a copy of EventDetail
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


/// Adds pattern-matching-related methods to [EventDetail].
extension EventDetailPatterns on EventDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EventDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EventDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EventDetail value)  $default,){
final _that = this;
switch (_that) {
case _EventDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EventDetail value)?  $default,){
final _that = this;
switch (_that) {
case _EventDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String slug,  DateTime startTime,  DateTime? doorsTime,  Venue? venue,  List<Artist> artists,  double? minPrice,  double? maxPrice,  PriceTier? priceTier,  String? ticketUrl,  bool soldOut,  String? imageUrl,  AgeRestriction ageRestriction,  EventStatus status,  String? description,  DateTime? endTime,  DateTime? onSaleDate,  String? ticketPlatform,  List<EventSource> sources,  List<Event> relatedEvents)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EventDetail() when $default != null:
return $default(_that.id,_that.title,_that.slug,_that.startTime,_that.doorsTime,_that.venue,_that.artists,_that.minPrice,_that.maxPrice,_that.priceTier,_that.ticketUrl,_that.soldOut,_that.imageUrl,_that.ageRestriction,_that.status,_that.description,_that.endTime,_that.onSaleDate,_that.ticketPlatform,_that.sources,_that.relatedEvents);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String slug,  DateTime startTime,  DateTime? doorsTime,  Venue? venue,  List<Artist> artists,  double? minPrice,  double? maxPrice,  PriceTier? priceTier,  String? ticketUrl,  bool soldOut,  String? imageUrl,  AgeRestriction ageRestriction,  EventStatus status,  String? description,  DateTime? endTime,  DateTime? onSaleDate,  String? ticketPlatform,  List<EventSource> sources,  List<Event> relatedEvents)  $default,) {final _that = this;
switch (_that) {
case _EventDetail():
return $default(_that.id,_that.title,_that.slug,_that.startTime,_that.doorsTime,_that.venue,_that.artists,_that.minPrice,_that.maxPrice,_that.priceTier,_that.ticketUrl,_that.soldOut,_that.imageUrl,_that.ageRestriction,_that.status,_that.description,_that.endTime,_that.onSaleDate,_that.ticketPlatform,_that.sources,_that.relatedEvents);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String slug,  DateTime startTime,  DateTime? doorsTime,  Venue? venue,  List<Artist> artists,  double? minPrice,  double? maxPrice,  PriceTier? priceTier,  String? ticketUrl,  bool soldOut,  String? imageUrl,  AgeRestriction ageRestriction,  EventStatus status,  String? description,  DateTime? endTime,  DateTime? onSaleDate,  String? ticketPlatform,  List<EventSource> sources,  List<Event> relatedEvents)?  $default,) {final _that = this;
switch (_that) {
case _EventDetail() when $default != null:
return $default(_that.id,_that.title,_that.slug,_that.startTime,_that.doorsTime,_that.venue,_that.artists,_that.minPrice,_that.maxPrice,_that.priceTier,_that.ticketUrl,_that.soldOut,_that.imageUrl,_that.ageRestriction,_that.status,_that.description,_that.endTime,_that.onSaleDate,_that.ticketPlatform,_that.sources,_that.relatedEvents);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EventDetail implements EventDetail {
  const _EventDetail({required this.id, required this.title, required this.slug, required this.startTime, this.doorsTime, this.venue, final  List<Artist> artists = const [], this.minPrice, this.maxPrice, this.priceTier, this.ticketUrl, this.soldOut = false, this.imageUrl, this.ageRestriction = AgeRestriction.ALL_AGES, this.status = EventStatus.ACTIVE, this.description, this.endTime, this.onSaleDate, this.ticketPlatform, final  List<EventSource> sources = const [], final  List<Event> relatedEvents = const []}): _artists = artists,_sources = sources,_relatedEvents = relatedEvents;
  factory _EventDetail.fromJson(Map<String, dynamic> json) => _$EventDetailFromJson(json);

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
@override final  DateTime? endTime;
@override final  DateTime? onSaleDate;
@override final  String? ticketPlatform;
 final  List<EventSource> _sources;
@override@JsonKey() List<EventSource> get sources {
  if (_sources is EqualUnmodifiableListView) return _sources;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sources);
}

 final  List<Event> _relatedEvents;
@override@JsonKey() List<Event> get relatedEvents {
  if (_relatedEvents is EqualUnmodifiableListView) return _relatedEvents;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_relatedEvents);
}


/// Create a copy of EventDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EventDetailCopyWith<_EventDetail> get copyWith => __$EventDetailCopyWithImpl<_EventDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EventDetailToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EventDetail&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.doorsTime, doorsTime) || other.doorsTime == doorsTime)&&(identical(other.venue, venue) || other.venue == venue)&&const DeepCollectionEquality().equals(other._artists, _artists)&&(identical(other.minPrice, minPrice) || other.minPrice == minPrice)&&(identical(other.maxPrice, maxPrice) || other.maxPrice == maxPrice)&&(identical(other.priceTier, priceTier) || other.priceTier == priceTier)&&(identical(other.ticketUrl, ticketUrl) || other.ticketUrl == ticketUrl)&&(identical(other.soldOut, soldOut) || other.soldOut == soldOut)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.ageRestriction, ageRestriction) || other.ageRestriction == ageRestriction)&&(identical(other.status, status) || other.status == status)&&(identical(other.description, description) || other.description == description)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.onSaleDate, onSaleDate) || other.onSaleDate == onSaleDate)&&(identical(other.ticketPlatform, ticketPlatform) || other.ticketPlatform == ticketPlatform)&&const DeepCollectionEquality().equals(other._sources, _sources)&&const DeepCollectionEquality().equals(other._relatedEvents, _relatedEvents));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,title,slug,startTime,doorsTime,venue,const DeepCollectionEquality().hash(_artists),minPrice,maxPrice,priceTier,ticketUrl,soldOut,imageUrl,ageRestriction,status,description,endTime,onSaleDate,ticketPlatform,const DeepCollectionEquality().hash(_sources),const DeepCollectionEquality().hash(_relatedEvents)]);

@override
String toString() {
  return 'EventDetail(id: $id, title: $title, slug: $slug, startTime: $startTime, doorsTime: $doorsTime, venue: $venue, artists: $artists, minPrice: $minPrice, maxPrice: $maxPrice, priceTier: $priceTier, ticketUrl: $ticketUrl, soldOut: $soldOut, imageUrl: $imageUrl, ageRestriction: $ageRestriction, status: $status, description: $description, endTime: $endTime, onSaleDate: $onSaleDate, ticketPlatform: $ticketPlatform, sources: $sources, relatedEvents: $relatedEvents)';
}


}

/// @nodoc
abstract mixin class _$EventDetailCopyWith<$Res> implements $EventDetailCopyWith<$Res> {
  factory _$EventDetailCopyWith(_EventDetail value, $Res Function(_EventDetail) _then) = __$EventDetailCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String slug, DateTime startTime, DateTime? doorsTime, Venue? venue, List<Artist> artists, double? minPrice, double? maxPrice, PriceTier? priceTier, String? ticketUrl, bool soldOut, String? imageUrl, AgeRestriction ageRestriction, EventStatus status, String? description, DateTime? endTime, DateTime? onSaleDate, String? ticketPlatform, List<EventSource> sources, List<Event> relatedEvents
});


@override $VenueCopyWith<$Res>? get venue;

}
/// @nodoc
class __$EventDetailCopyWithImpl<$Res>
    implements _$EventDetailCopyWith<$Res> {
  __$EventDetailCopyWithImpl(this._self, this._then);

  final _EventDetail _self;
  final $Res Function(_EventDetail) _then;

/// Create a copy of EventDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? slug = null,Object? startTime = null,Object? doorsTime = freezed,Object? venue = freezed,Object? artists = null,Object? minPrice = freezed,Object? maxPrice = freezed,Object? priceTier = freezed,Object? ticketUrl = freezed,Object? soldOut = null,Object? imageUrl = freezed,Object? ageRestriction = null,Object? status = null,Object? description = freezed,Object? endTime = freezed,Object? onSaleDate = freezed,Object? ticketPlatform = freezed,Object? sources = null,Object? relatedEvents = null,}) {
  return _then(_EventDetail(
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
as String?,endTime: freezed == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as DateTime?,onSaleDate: freezed == onSaleDate ? _self.onSaleDate : onSaleDate // ignore: cast_nullable_to_non_nullable
as DateTime?,ticketPlatform: freezed == ticketPlatform ? _self.ticketPlatform : ticketPlatform // ignore: cast_nullable_to_non_nullable
as String?,sources: null == sources ? _self._sources : sources // ignore: cast_nullable_to_non_nullable
as List<EventSource>,relatedEvents: null == relatedEvents ? _self._relatedEvents : relatedEvents // ignore: cast_nullable_to_non_nullable
as List<Event>,
  ));
}

/// Create a copy of EventDetail
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
