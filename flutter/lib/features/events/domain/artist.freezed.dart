// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'artist.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Artist {

 String get id; String get name; String get slug; List<String> get genres; bool get isLocal; String? get spotifyUrl; String? get bandcampUrl; String? get instagramUrl; String? get canonicalName; String? get imageUrl;
/// Create a copy of Artist
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArtistCopyWith<Artist> get copyWith => _$ArtistCopyWithImpl<Artist>(this as Artist, _$identity);

  /// Serializes this Artist to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Artist&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.slug, slug) || other.slug == slug)&&const DeepCollectionEquality().equals(other.genres, genres)&&(identical(other.isLocal, isLocal) || other.isLocal == isLocal)&&(identical(other.spotifyUrl, spotifyUrl) || other.spotifyUrl == spotifyUrl)&&(identical(other.bandcampUrl, bandcampUrl) || other.bandcampUrl == bandcampUrl)&&(identical(other.instagramUrl, instagramUrl) || other.instagramUrl == instagramUrl)&&(identical(other.canonicalName, canonicalName) || other.canonicalName == canonicalName)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,slug,const DeepCollectionEquality().hash(genres),isLocal,spotifyUrl,bandcampUrl,instagramUrl,canonicalName,imageUrl);

@override
String toString() {
  return 'Artist(id: $id, name: $name, slug: $slug, genres: $genres, isLocal: $isLocal, spotifyUrl: $spotifyUrl, bandcampUrl: $bandcampUrl, instagramUrl: $instagramUrl, canonicalName: $canonicalName, imageUrl: $imageUrl)';
}


}

/// @nodoc
abstract mixin class $ArtistCopyWith<$Res>  {
  factory $ArtistCopyWith(Artist value, $Res Function(Artist) _then) = _$ArtistCopyWithImpl;
@useResult
$Res call({
 String id, String name, String slug, List<String> genres, bool isLocal, String? spotifyUrl, String? bandcampUrl, String? instagramUrl, String? canonicalName, String? imageUrl
});




}
/// @nodoc
class _$ArtistCopyWithImpl<$Res>
    implements $ArtistCopyWith<$Res> {
  _$ArtistCopyWithImpl(this._self, this._then);

  final Artist _self;
  final $Res Function(Artist) _then;

/// Create a copy of Artist
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? slug = null,Object? genres = null,Object? isLocal = null,Object? spotifyUrl = freezed,Object? bandcampUrl = freezed,Object? instagramUrl = freezed,Object? canonicalName = freezed,Object? imageUrl = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,genres: null == genres ? _self.genres : genres // ignore: cast_nullable_to_non_nullable
as List<String>,isLocal: null == isLocal ? _self.isLocal : isLocal // ignore: cast_nullable_to_non_nullable
as bool,spotifyUrl: freezed == spotifyUrl ? _self.spotifyUrl : spotifyUrl // ignore: cast_nullable_to_non_nullable
as String?,bandcampUrl: freezed == bandcampUrl ? _self.bandcampUrl : bandcampUrl // ignore: cast_nullable_to_non_nullable
as String?,instagramUrl: freezed == instagramUrl ? _self.instagramUrl : instagramUrl // ignore: cast_nullable_to_non_nullable
as String?,canonicalName: freezed == canonicalName ? _self.canonicalName : canonicalName // ignore: cast_nullable_to_non_nullable
as String?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Artist].
extension ArtistPatterns on Artist {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Artist value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Artist() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Artist value)  $default,){
final _that = this;
switch (_that) {
case _Artist():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Artist value)?  $default,){
final _that = this;
switch (_that) {
case _Artist() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String slug,  List<String> genres,  bool isLocal,  String? spotifyUrl,  String? bandcampUrl,  String? instagramUrl,  String? canonicalName,  String? imageUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Artist() when $default != null:
return $default(_that.id,_that.name,_that.slug,_that.genres,_that.isLocal,_that.spotifyUrl,_that.bandcampUrl,_that.instagramUrl,_that.canonicalName,_that.imageUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String slug,  List<String> genres,  bool isLocal,  String? spotifyUrl,  String? bandcampUrl,  String? instagramUrl,  String? canonicalName,  String? imageUrl)  $default,) {final _that = this;
switch (_that) {
case _Artist():
return $default(_that.id,_that.name,_that.slug,_that.genres,_that.isLocal,_that.spotifyUrl,_that.bandcampUrl,_that.instagramUrl,_that.canonicalName,_that.imageUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String slug,  List<String> genres,  bool isLocal,  String? spotifyUrl,  String? bandcampUrl,  String? instagramUrl,  String? canonicalName,  String? imageUrl)?  $default,) {final _that = this;
switch (_that) {
case _Artist() when $default != null:
return $default(_that.id,_that.name,_that.slug,_that.genres,_that.isLocal,_that.spotifyUrl,_that.bandcampUrl,_that.instagramUrl,_that.canonicalName,_that.imageUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Artist implements Artist {
  const _Artist({required this.id, required this.name, required this.slug, final  List<String> genres = const [], this.isLocal = false, this.spotifyUrl, this.bandcampUrl, this.instagramUrl, this.canonicalName, this.imageUrl}): _genres = genres;
  factory _Artist.fromJson(Map<String, dynamic> json) => _$ArtistFromJson(json);

@override final  String id;
@override final  String name;
@override final  String slug;
 final  List<String> _genres;
@override@JsonKey() List<String> get genres {
  if (_genres is EqualUnmodifiableListView) return _genres;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_genres);
}

@override@JsonKey() final  bool isLocal;
@override final  String? spotifyUrl;
@override final  String? bandcampUrl;
@override final  String? instagramUrl;
@override final  String? canonicalName;
@override final  String? imageUrl;

/// Create a copy of Artist
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArtistCopyWith<_Artist> get copyWith => __$ArtistCopyWithImpl<_Artist>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ArtistToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Artist&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.slug, slug) || other.slug == slug)&&const DeepCollectionEquality().equals(other._genres, _genres)&&(identical(other.isLocal, isLocal) || other.isLocal == isLocal)&&(identical(other.spotifyUrl, spotifyUrl) || other.spotifyUrl == spotifyUrl)&&(identical(other.bandcampUrl, bandcampUrl) || other.bandcampUrl == bandcampUrl)&&(identical(other.instagramUrl, instagramUrl) || other.instagramUrl == instagramUrl)&&(identical(other.canonicalName, canonicalName) || other.canonicalName == canonicalName)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,slug,const DeepCollectionEquality().hash(_genres),isLocal,spotifyUrl,bandcampUrl,instagramUrl,canonicalName,imageUrl);

@override
String toString() {
  return 'Artist(id: $id, name: $name, slug: $slug, genres: $genres, isLocal: $isLocal, spotifyUrl: $spotifyUrl, bandcampUrl: $bandcampUrl, instagramUrl: $instagramUrl, canonicalName: $canonicalName, imageUrl: $imageUrl)';
}


}

/// @nodoc
abstract mixin class _$ArtistCopyWith<$Res> implements $ArtistCopyWith<$Res> {
  factory _$ArtistCopyWith(_Artist value, $Res Function(_Artist) _then) = __$ArtistCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String slug, List<String> genres, bool isLocal, String? spotifyUrl, String? bandcampUrl, String? instagramUrl, String? canonicalName, String? imageUrl
});




}
/// @nodoc
class __$ArtistCopyWithImpl<$Res>
    implements _$ArtistCopyWith<$Res> {
  __$ArtistCopyWithImpl(this._self, this._then);

  final _Artist _self;
  final $Res Function(_Artist) _then;

/// Create a copy of Artist
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? slug = null,Object? genres = null,Object? isLocal = null,Object? spotifyUrl = freezed,Object? bandcampUrl = freezed,Object? instagramUrl = freezed,Object? canonicalName = freezed,Object? imageUrl = freezed,}) {
  return _then(_Artist(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,genres: null == genres ? _self._genres : genres // ignore: cast_nullable_to_non_nullable
as List<String>,isLocal: null == isLocal ? _self.isLocal : isLocal // ignore: cast_nullable_to_non_nullable
as bool,spotifyUrl: freezed == spotifyUrl ? _self.spotifyUrl : spotifyUrl // ignore: cast_nullable_to_non_nullable
as String?,bandcampUrl: freezed == bandcampUrl ? _self.bandcampUrl : bandcampUrl // ignore: cast_nullable_to_non_nullable
as String?,instagramUrl: freezed == instagramUrl ? _self.instagramUrl : instagramUrl // ignore: cast_nullable_to_non_nullable
as String?,canonicalName: freezed == canonicalName ? _self.canonicalName : canonicalName // ignore: cast_nullable_to_non_nullable
as String?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
