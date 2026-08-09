// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'artist.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Artist _$ArtistFromJson(Map<String, dynamic> json) => _Artist(
  id: json['id'] as String,
  name: json['name'] as String,
  slug: json['slug'] as String,
  genres:
      (json['genres'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  isLocal: json['isLocal'] as bool? ?? false,
  spotifyUrl: json['spotifyUrl'] as String?,
  bandcampUrl: json['bandcampUrl'] as String?,
  instagramUrl: json['instagramUrl'] as String?,
  canonicalName: json['canonicalName'] as String?,
  imageUrl: json['imageUrl'] as String?,
);

Map<String, dynamic> _$ArtistToJson(_Artist instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'slug': instance.slug,
  'genres': instance.genres,
  'isLocal': instance.isLocal,
  'spotifyUrl': instance.spotifyUrl,
  'bandcampUrl': instance.bandcampUrl,
  'instagramUrl': instance.instagramUrl,
  'canonicalName': instance.canonicalName,
  'imageUrl': instance.imageUrl,
};
