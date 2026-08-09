// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'featured_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FeaturedEvent _$FeaturedEventFromJson(Map<String, dynamic> json) =>
    _FeaturedEvent(
      id: json['id'] as String,
      event: EventDetail.fromJson(json['event'] as Map<String, dynamic>),
      blurb: json['blurb'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      createdBy: json['createdBy'] as String,
    );

Map<String, dynamic> _$FeaturedEventToJson(_FeaturedEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'event': instance.event.toJson(),
      'blurb': instance.blurb,
      'createdAt': instance.createdAt.toIso8601String(),
      'createdBy': instance.createdBy,
    };
