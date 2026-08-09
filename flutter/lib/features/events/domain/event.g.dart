// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Event _$EventFromJson(Map<String, dynamic> json) => _Event(
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
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$EventToJson(_Event instance) => <String, dynamic>{
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
  'createdAt': instance.createdAt?.toIso8601String(),
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
