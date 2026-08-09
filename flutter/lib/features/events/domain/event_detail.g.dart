// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EventDetail _$EventDetailFromJson(Map<String, dynamic> json) => _EventDetail(
  id: json['id'] as String,
  title: json['title'] as String,
  slug: json['slug'] as String,
  startTime: DateTime.parse(json['startTime'] as String),
  doorsTime: json['doorsTime'] == null
      ? null
      : DateTime.parse(json['doorsTime'] as String),
  venue: json['venue'] == null
      ? null
      : Venue.fromJson(json['venue'] as Map<String, dynamic>),
  artists:
      (json['artists'] as List<dynamic>?)
          ?.map((e) => Artist.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  minPrice: (json['minPrice'] as num?)?.toDouble(),
  maxPrice: (json['maxPrice'] as num?)?.toDouble(),
  priceTier: $enumDecodeNullable(_$PriceTierEnumMap, json['priceTier']),
  ticketUrl: json['ticketUrl'] as String?,
  soldOut: json['soldOut'] as bool? ?? false,
  imageUrl: json['imageUrl'] as String?,
  ageRestriction:
      $enumDecodeNullable(_$AgeRestrictionEnumMap, json['ageRestriction']) ??
      AgeRestriction.ALL_AGES,
  status:
      $enumDecodeNullable(_$EventStatusEnumMap, json['status']) ??
      EventStatus.ACTIVE,
  description: json['description'] as String?,
  endTime: json['endTime'] == null
      ? null
      : DateTime.parse(json['endTime'] as String),
  onSaleDate: json['onSaleDate'] == null
      ? null
      : DateTime.parse(json['onSaleDate'] as String),
  ticketPlatform: json['ticketPlatform'] as String?,
  sources:
      (json['sources'] as List<dynamic>?)
          ?.map((e) => EventSource.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  relatedEvents:
      (json['relatedEvents'] as List<dynamic>?)
          ?.map((e) => Event.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$EventDetailToJson(_EventDetail instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'slug': instance.slug,
      'startTime': instance.startTime.toIso8601String(),
      'doorsTime': instance.doorsTime?.toIso8601String(),
      'venue': instance.venue?.toJson(),
      'artists': instance.artists.map((e) => e.toJson()).toList(),
      'minPrice': instance.minPrice,
      'maxPrice': instance.maxPrice,
      'priceTier': _$PriceTierEnumMap[instance.priceTier],
      'ticketUrl': instance.ticketUrl,
      'soldOut': instance.soldOut,
      'imageUrl': instance.imageUrl,
      'ageRestriction': _$AgeRestrictionEnumMap[instance.ageRestriction]!,
      'status': _$EventStatusEnumMap[instance.status]!,
      'description': instance.description,
      'endTime': instance.endTime?.toIso8601String(),
      'onSaleDate': instance.onSaleDate?.toIso8601String(),
      'ticketPlatform': instance.ticketPlatform,
      'sources': instance.sources.map((e) => e.toJson()).toList(),
      'relatedEvents': instance.relatedEvents.map((e) => e.toJson()).toList(),
    };

const _$PriceTierEnumMap = {
  PriceTier.FREE: 'FREE',
  PriceTier.UNDER_15: 'UNDER_15',
  PriceTier.PRICE_15_TO_30: 'PRICE_15_TO_30',
  PriceTier.OVER_30: 'OVER_30',
};

const _$AgeRestrictionEnumMap = {
  AgeRestriction.ALL_AGES: 'ALL_AGES',
  AgeRestriction.EIGHTEEN_PLUS: 'EIGHTEEN_PLUS',
  AgeRestriction.TWENTY_ONE_PLUS: 'TWENTY_ONE_PLUS',
};

const _$EventStatusEnumMap = {
  EventStatus.ACTIVE: 'ACTIVE',
  EventStatus.CANCELLED: 'CANCELLED',
  EventStatus.POSTPONED: 'POSTPONED',
  EventStatus.RESCHEDULED: 'RESCHEDULED',
};
