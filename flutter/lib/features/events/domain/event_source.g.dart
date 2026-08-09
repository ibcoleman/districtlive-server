// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_source.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EventSource _$EventSourceFromJson(Map<String, dynamic> json) => _EventSource(
  sourceType: $enumDecode(_$SourceTypeEnumMap, json['sourceType']),
  lastScrapedAt: json['lastScrapedAt'] == null
      ? null
      : DateTime.parse(json['lastScrapedAt'] as String),
);

Map<String, dynamic> _$EventSourceToJson(_EventSource instance) =>
    <String, dynamic>{
      'sourceType': _$SourceTypeEnumMap[instance.sourceType]!,
      'lastScrapedAt': instance.lastScrapedAt?.toIso8601String(),
    };

const _$SourceTypeEnumMap = {
  SourceType.TICKETMASTER_API: 'TICKETMASTER_API',
  SourceType.BANDSINTOWN_API: 'BANDSINTOWN_API',
  SourceType.VENUE_SCRAPER: 'VENUE_SCRAPER',
  SourceType.MANUAL: 'MANUAL',
  SourceType.DICE_FM: 'DICE_FM',
};
