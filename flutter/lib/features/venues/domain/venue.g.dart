// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'venue.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Venue _$VenueFromJson(Map<String, dynamic> json) => _Venue(
  id: json['id'] as String,
  name: json['name'] as String,
  slug: json['slug'] as String,
  neighborhood: json['neighborhood'] as String?,
  websiteUrl: json['websiteUrl'] as String?,
  upcomingEventCount: (json['upcomingEventCount'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$VenueToJson(_Venue instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'slug': instance.slug,
  'neighborhood': instance.neighborhood,
  'websiteUrl': instance.websiteUrl,
  'upcomingEventCount': instance.upcomingEventCount,
};
