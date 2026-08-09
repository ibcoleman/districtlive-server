// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $EventsTableTable extends EventsTable
    with TableInfo<$EventsTableTable, EventsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _slugMeta = const VerificationMeta('slug');
  @override
  late final GeneratedColumn<String> slug = GeneratedColumn<String>(
    'slug',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<DateTime> startTime = GeneratedColumn<DateTime>(
    'start_time',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  @override
  late final GeneratedColumn<DateTime> endTime = GeneratedColumn<DateTime>(
    'end_time',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _doorsTimeMeta = const VerificationMeta(
    'doorsTime',
  );
  @override
  late final GeneratedColumn<DateTime> doorsTime = GeneratedColumn<DateTime>(
    'doors_time',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _onSaleDateMeta = const VerificationMeta(
    'onSaleDate',
  );
  @override
  late final GeneratedColumn<DateTime> onSaleDate = GeneratedColumn<DateTime>(
    'on_sale_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _venueIdMeta = const VerificationMeta(
    'venueId',
  );
  @override
  late final GeneratedColumn<String> venueId = GeneratedColumn<String>(
    'venue_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _minPriceMeta = const VerificationMeta(
    'minPrice',
  );
  @override
  late final GeneratedColumn<double> minPrice = GeneratedColumn<double>(
    'min_price',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _maxPriceMeta = const VerificationMeta(
    'maxPrice',
  );
  @override
  late final GeneratedColumn<double> maxPrice = GeneratedColumn<double>(
    'max_price',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priceTierMeta = const VerificationMeta(
    'priceTier',
  );
  @override
  late final GeneratedColumn<String> priceTier = GeneratedColumn<String>(
    'price_tier',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ticketUrlMeta = const VerificationMeta(
    'ticketUrl',
  );
  @override
  late final GeneratedColumn<String> ticketUrl = GeneratedColumn<String>(
    'ticket_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ticketPlatformMeta = const VerificationMeta(
    'ticketPlatform',
  );
  @override
  late final GeneratedColumn<String> ticketPlatform = GeneratedColumn<String>(
    'ticket_platform',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _soldOutMeta = const VerificationMeta(
    'soldOut',
  );
  @override
  late final GeneratedColumn<bool> soldOut = GeneratedColumn<bool>(
    'sold_out',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sold_out" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ageRestrictionMeta = const VerificationMeta(
    'ageRestriction',
  );
  @override
  late final GeneratedColumn<String> ageRestriction = GeneratedColumn<String>(
    'age_restriction',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('ALL_AGES'),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('ACTIVE'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    slug,
    description,
    startTime,
    endTime,
    doorsTime,
    onSaleDate,
    venueId,
    minPrice,
    maxPrice,
    priceTier,
    ticketUrl,
    ticketPlatform,
    soldOut,
    imageUrl,
    ageRestriction,
    status,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'events_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<EventsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('slug')) {
      context.handle(
        _slugMeta,
        slug.isAcceptableOrUnknown(data['slug']!, _slugMeta),
      );
    } else if (isInserting) {
      context.missing(_slugMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
      );
    }
    if (data.containsKey('doors_time')) {
      context.handle(
        _doorsTimeMeta,
        doorsTime.isAcceptableOrUnknown(data['doors_time']!, _doorsTimeMeta),
      );
    }
    if (data.containsKey('on_sale_date')) {
      context.handle(
        _onSaleDateMeta,
        onSaleDate.isAcceptableOrUnknown(
          data['on_sale_date']!,
          _onSaleDateMeta,
        ),
      );
    }
    if (data.containsKey('venue_id')) {
      context.handle(
        _venueIdMeta,
        venueId.isAcceptableOrUnknown(data['venue_id']!, _venueIdMeta),
      );
    }
    if (data.containsKey('min_price')) {
      context.handle(
        _minPriceMeta,
        minPrice.isAcceptableOrUnknown(data['min_price']!, _minPriceMeta),
      );
    }
    if (data.containsKey('max_price')) {
      context.handle(
        _maxPriceMeta,
        maxPrice.isAcceptableOrUnknown(data['max_price']!, _maxPriceMeta),
      );
    }
    if (data.containsKey('price_tier')) {
      context.handle(
        _priceTierMeta,
        priceTier.isAcceptableOrUnknown(data['price_tier']!, _priceTierMeta),
      );
    }
    if (data.containsKey('ticket_url')) {
      context.handle(
        _ticketUrlMeta,
        ticketUrl.isAcceptableOrUnknown(data['ticket_url']!, _ticketUrlMeta),
      );
    }
    if (data.containsKey('ticket_platform')) {
      context.handle(
        _ticketPlatformMeta,
        ticketPlatform.isAcceptableOrUnknown(
          data['ticket_platform']!,
          _ticketPlatformMeta,
        ),
      );
    }
    if (data.containsKey('sold_out')) {
      context.handle(
        _soldOutMeta,
        soldOut.isAcceptableOrUnknown(data['sold_out']!, _soldOutMeta),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('age_restriction')) {
      context.handle(
        _ageRestrictionMeta,
        ageRestriction.isAcceptableOrUnknown(
          data['age_restriction']!,
          _ageRestrictionMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EventsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EventsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      slug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slug'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_time'],
      )!,
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_time'],
      ),
      doorsTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}doors_time'],
      ),
      onSaleDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}on_sale_date'],
      ),
      venueId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}venue_id'],
      ),
      minPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}min_price'],
      ),
      maxPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}max_price'],
      ),
      priceTier: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}price_tier'],
      ),
      ticketUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ticket_url'],
      ),
      ticketPlatform: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ticket_platform'],
      ),
      soldOut: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sold_out'],
      )!,
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      ageRestriction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}age_restriction'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
    );
  }

  @override
  $EventsTableTable createAlias(String alias) {
    return $EventsTableTable(attachedDatabase, alias);
  }
}

class EventsTableData extends DataClass implements Insertable<EventsTableData> {
  final String id;
  final String title;
  final String slug;
  final String? description;
  final DateTime startTime;
  final DateTime? endTime;
  final DateTime? doorsTime;
  final DateTime? onSaleDate;
  final String? venueId;
  final double? minPrice;
  final double? maxPrice;
  final String? priceTier;
  final String? ticketUrl;
  final String? ticketPlatform;
  final bool soldOut;
  final String? imageUrl;
  final String ageRestriction;
  final String status;
  final DateTime? createdAt;
  const EventsTableData({
    required this.id,
    required this.title,
    required this.slug,
    this.description,
    required this.startTime,
    this.endTime,
    this.doorsTime,
    this.onSaleDate,
    this.venueId,
    this.minPrice,
    this.maxPrice,
    this.priceTier,
    this.ticketUrl,
    this.ticketPlatform,
    required this.soldOut,
    this.imageUrl,
    required this.ageRestriction,
    required this.status,
    this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['slug'] = Variable<String>(slug);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['start_time'] = Variable<DateTime>(startTime);
    if (!nullToAbsent || endTime != null) {
      map['end_time'] = Variable<DateTime>(endTime);
    }
    if (!nullToAbsent || doorsTime != null) {
      map['doors_time'] = Variable<DateTime>(doorsTime);
    }
    if (!nullToAbsent || onSaleDate != null) {
      map['on_sale_date'] = Variable<DateTime>(onSaleDate);
    }
    if (!nullToAbsent || venueId != null) {
      map['venue_id'] = Variable<String>(venueId);
    }
    if (!nullToAbsent || minPrice != null) {
      map['min_price'] = Variable<double>(minPrice);
    }
    if (!nullToAbsent || maxPrice != null) {
      map['max_price'] = Variable<double>(maxPrice);
    }
    if (!nullToAbsent || priceTier != null) {
      map['price_tier'] = Variable<String>(priceTier);
    }
    if (!nullToAbsent || ticketUrl != null) {
      map['ticket_url'] = Variable<String>(ticketUrl);
    }
    if (!nullToAbsent || ticketPlatform != null) {
      map['ticket_platform'] = Variable<String>(ticketPlatform);
    }
    map['sold_out'] = Variable<bool>(soldOut);
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    map['age_restriction'] = Variable<String>(ageRestriction);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    return map;
  }

  EventsTableCompanion toCompanion(bool nullToAbsent) {
    return EventsTableCompanion(
      id: Value(id),
      title: Value(title),
      slug: Value(slug),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      startTime: Value(startTime),
      endTime: endTime == null && nullToAbsent
          ? const Value.absent()
          : Value(endTime),
      doorsTime: doorsTime == null && nullToAbsent
          ? const Value.absent()
          : Value(doorsTime),
      onSaleDate: onSaleDate == null && nullToAbsent
          ? const Value.absent()
          : Value(onSaleDate),
      venueId: venueId == null && nullToAbsent
          ? const Value.absent()
          : Value(venueId),
      minPrice: minPrice == null && nullToAbsent
          ? const Value.absent()
          : Value(minPrice),
      maxPrice: maxPrice == null && nullToAbsent
          ? const Value.absent()
          : Value(maxPrice),
      priceTier: priceTier == null && nullToAbsent
          ? const Value.absent()
          : Value(priceTier),
      ticketUrl: ticketUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(ticketUrl),
      ticketPlatform: ticketPlatform == null && nullToAbsent
          ? const Value.absent()
          : Value(ticketPlatform),
      soldOut: Value(soldOut),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      ageRestriction: Value(ageRestriction),
      status: Value(status),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory EventsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EventsTableData(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      slug: serializer.fromJson<String>(json['slug']),
      description: serializer.fromJson<String?>(json['description']),
      startTime: serializer.fromJson<DateTime>(json['startTime']),
      endTime: serializer.fromJson<DateTime?>(json['endTime']),
      doorsTime: serializer.fromJson<DateTime?>(json['doorsTime']),
      onSaleDate: serializer.fromJson<DateTime?>(json['onSaleDate']),
      venueId: serializer.fromJson<String?>(json['venueId']),
      minPrice: serializer.fromJson<double?>(json['minPrice']),
      maxPrice: serializer.fromJson<double?>(json['maxPrice']),
      priceTier: serializer.fromJson<String?>(json['priceTier']),
      ticketUrl: serializer.fromJson<String?>(json['ticketUrl']),
      ticketPlatform: serializer.fromJson<String?>(json['ticketPlatform']),
      soldOut: serializer.fromJson<bool>(json['soldOut']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      ageRestriction: serializer.fromJson<String>(json['ageRestriction']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'slug': serializer.toJson<String>(slug),
      'description': serializer.toJson<String?>(description),
      'startTime': serializer.toJson<DateTime>(startTime),
      'endTime': serializer.toJson<DateTime?>(endTime),
      'doorsTime': serializer.toJson<DateTime?>(doorsTime),
      'onSaleDate': serializer.toJson<DateTime?>(onSaleDate),
      'venueId': serializer.toJson<String?>(venueId),
      'minPrice': serializer.toJson<double?>(minPrice),
      'maxPrice': serializer.toJson<double?>(maxPrice),
      'priceTier': serializer.toJson<String?>(priceTier),
      'ticketUrl': serializer.toJson<String?>(ticketUrl),
      'ticketPlatform': serializer.toJson<String?>(ticketPlatform),
      'soldOut': serializer.toJson<bool>(soldOut),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'ageRestriction': serializer.toJson<String>(ageRestriction),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
    };
  }

  EventsTableData copyWith({
    String? id,
    String? title,
    String? slug,
    Value<String?> description = const Value.absent(),
    DateTime? startTime,
    Value<DateTime?> endTime = const Value.absent(),
    Value<DateTime?> doorsTime = const Value.absent(),
    Value<DateTime?> onSaleDate = const Value.absent(),
    Value<String?> venueId = const Value.absent(),
    Value<double?> minPrice = const Value.absent(),
    Value<double?> maxPrice = const Value.absent(),
    Value<String?> priceTier = const Value.absent(),
    Value<String?> ticketUrl = const Value.absent(),
    Value<String?> ticketPlatform = const Value.absent(),
    bool? soldOut,
    Value<String?> imageUrl = const Value.absent(),
    String? ageRestriction,
    String? status,
    Value<DateTime?> createdAt = const Value.absent(),
  }) => EventsTableData(
    id: id ?? this.id,
    title: title ?? this.title,
    slug: slug ?? this.slug,
    description: description.present ? description.value : this.description,
    startTime: startTime ?? this.startTime,
    endTime: endTime.present ? endTime.value : this.endTime,
    doorsTime: doorsTime.present ? doorsTime.value : this.doorsTime,
    onSaleDate: onSaleDate.present ? onSaleDate.value : this.onSaleDate,
    venueId: venueId.present ? venueId.value : this.venueId,
    minPrice: minPrice.present ? minPrice.value : this.minPrice,
    maxPrice: maxPrice.present ? maxPrice.value : this.maxPrice,
    priceTier: priceTier.present ? priceTier.value : this.priceTier,
    ticketUrl: ticketUrl.present ? ticketUrl.value : this.ticketUrl,
    ticketPlatform: ticketPlatform.present
        ? ticketPlatform.value
        : this.ticketPlatform,
    soldOut: soldOut ?? this.soldOut,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    ageRestriction: ageRestriction ?? this.ageRestriction,
    status: status ?? this.status,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
  );
  EventsTableData copyWithCompanion(EventsTableCompanion data) {
    return EventsTableData(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      slug: data.slug.present ? data.slug.value : this.slug,
      description: data.description.present
          ? data.description.value
          : this.description,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      doorsTime: data.doorsTime.present ? data.doorsTime.value : this.doorsTime,
      onSaleDate: data.onSaleDate.present
          ? data.onSaleDate.value
          : this.onSaleDate,
      venueId: data.venueId.present ? data.venueId.value : this.venueId,
      minPrice: data.minPrice.present ? data.minPrice.value : this.minPrice,
      maxPrice: data.maxPrice.present ? data.maxPrice.value : this.maxPrice,
      priceTier: data.priceTier.present ? data.priceTier.value : this.priceTier,
      ticketUrl: data.ticketUrl.present ? data.ticketUrl.value : this.ticketUrl,
      ticketPlatform: data.ticketPlatform.present
          ? data.ticketPlatform.value
          : this.ticketPlatform,
      soldOut: data.soldOut.present ? data.soldOut.value : this.soldOut,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      ageRestriction: data.ageRestriction.present
          ? data.ageRestriction.value
          : this.ageRestriction,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EventsTableData(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('slug: $slug, ')
          ..write('description: $description, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('doorsTime: $doorsTime, ')
          ..write('onSaleDate: $onSaleDate, ')
          ..write('venueId: $venueId, ')
          ..write('minPrice: $minPrice, ')
          ..write('maxPrice: $maxPrice, ')
          ..write('priceTier: $priceTier, ')
          ..write('ticketUrl: $ticketUrl, ')
          ..write('ticketPlatform: $ticketPlatform, ')
          ..write('soldOut: $soldOut, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('ageRestriction: $ageRestriction, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    slug,
    description,
    startTime,
    endTime,
    doorsTime,
    onSaleDate,
    venueId,
    minPrice,
    maxPrice,
    priceTier,
    ticketUrl,
    ticketPlatform,
    soldOut,
    imageUrl,
    ageRestriction,
    status,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EventsTableData &&
          other.id == this.id &&
          other.title == this.title &&
          other.slug == this.slug &&
          other.description == this.description &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.doorsTime == this.doorsTime &&
          other.onSaleDate == this.onSaleDate &&
          other.venueId == this.venueId &&
          other.minPrice == this.minPrice &&
          other.maxPrice == this.maxPrice &&
          other.priceTier == this.priceTier &&
          other.ticketUrl == this.ticketUrl &&
          other.ticketPlatform == this.ticketPlatform &&
          other.soldOut == this.soldOut &&
          other.imageUrl == this.imageUrl &&
          other.ageRestriction == this.ageRestriction &&
          other.status == this.status &&
          other.createdAt == this.createdAt);
}

class EventsTableCompanion extends UpdateCompanion<EventsTableData> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> slug;
  final Value<String?> description;
  final Value<DateTime> startTime;
  final Value<DateTime?> endTime;
  final Value<DateTime?> doorsTime;
  final Value<DateTime?> onSaleDate;
  final Value<String?> venueId;
  final Value<double?> minPrice;
  final Value<double?> maxPrice;
  final Value<String?> priceTier;
  final Value<String?> ticketUrl;
  final Value<String?> ticketPlatform;
  final Value<bool> soldOut;
  final Value<String?> imageUrl;
  final Value<String> ageRestriction;
  final Value<String> status;
  final Value<DateTime?> createdAt;
  final Value<int> rowid;
  const EventsTableCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.slug = const Value.absent(),
    this.description = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.doorsTime = const Value.absent(),
    this.onSaleDate = const Value.absent(),
    this.venueId = const Value.absent(),
    this.minPrice = const Value.absent(),
    this.maxPrice = const Value.absent(),
    this.priceTier = const Value.absent(),
    this.ticketUrl = const Value.absent(),
    this.ticketPlatform = const Value.absent(),
    this.soldOut = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.ageRestriction = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EventsTableCompanion.insert({
    required String id,
    required String title,
    required String slug,
    this.description = const Value.absent(),
    required DateTime startTime,
    this.endTime = const Value.absent(),
    this.doorsTime = const Value.absent(),
    this.onSaleDate = const Value.absent(),
    this.venueId = const Value.absent(),
    this.minPrice = const Value.absent(),
    this.maxPrice = const Value.absent(),
    this.priceTier = const Value.absent(),
    this.ticketUrl = const Value.absent(),
    this.ticketPlatform = const Value.absent(),
    this.soldOut = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.ageRestriction = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       slug = Value(slug),
       startTime = Value(startTime);
  static Insertable<EventsTableData> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? slug,
    Expression<String>? description,
    Expression<DateTime>? startTime,
    Expression<DateTime>? endTime,
    Expression<DateTime>? doorsTime,
    Expression<DateTime>? onSaleDate,
    Expression<String>? venueId,
    Expression<double>? minPrice,
    Expression<double>? maxPrice,
    Expression<String>? priceTier,
    Expression<String>? ticketUrl,
    Expression<String>? ticketPlatform,
    Expression<bool>? soldOut,
    Expression<String>? imageUrl,
    Expression<String>? ageRestriction,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (slug != null) 'slug': slug,
      if (description != null) 'description': description,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (doorsTime != null) 'doors_time': doorsTime,
      if (onSaleDate != null) 'on_sale_date': onSaleDate,
      if (venueId != null) 'venue_id': venueId,
      if (minPrice != null) 'min_price': minPrice,
      if (maxPrice != null) 'max_price': maxPrice,
      if (priceTier != null) 'price_tier': priceTier,
      if (ticketUrl != null) 'ticket_url': ticketUrl,
      if (ticketPlatform != null) 'ticket_platform': ticketPlatform,
      if (soldOut != null) 'sold_out': soldOut,
      if (imageUrl != null) 'image_url': imageUrl,
      if (ageRestriction != null) 'age_restriction': ageRestriction,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EventsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? slug,
    Value<String?>? description,
    Value<DateTime>? startTime,
    Value<DateTime?>? endTime,
    Value<DateTime?>? doorsTime,
    Value<DateTime?>? onSaleDate,
    Value<String?>? venueId,
    Value<double?>? minPrice,
    Value<double?>? maxPrice,
    Value<String?>? priceTier,
    Value<String?>? ticketUrl,
    Value<String?>? ticketPlatform,
    Value<bool>? soldOut,
    Value<String?>? imageUrl,
    Value<String>? ageRestriction,
    Value<String>? status,
    Value<DateTime?>? createdAt,
    Value<int>? rowid,
  }) {
    return EventsTableCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      doorsTime: doorsTime ?? this.doorsTime,
      onSaleDate: onSaleDate ?? this.onSaleDate,
      venueId: venueId ?? this.venueId,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      priceTier: priceTier ?? this.priceTier,
      ticketUrl: ticketUrl ?? this.ticketUrl,
      ticketPlatform: ticketPlatform ?? this.ticketPlatform,
      soldOut: soldOut ?? this.soldOut,
      imageUrl: imageUrl ?? this.imageUrl,
      ageRestriction: ageRestriction ?? this.ageRestriction,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (slug.present) {
      map['slug'] = Variable<String>(slug.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<DateTime>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<DateTime>(endTime.value);
    }
    if (doorsTime.present) {
      map['doors_time'] = Variable<DateTime>(doorsTime.value);
    }
    if (onSaleDate.present) {
      map['on_sale_date'] = Variable<DateTime>(onSaleDate.value);
    }
    if (venueId.present) {
      map['venue_id'] = Variable<String>(venueId.value);
    }
    if (minPrice.present) {
      map['min_price'] = Variable<double>(minPrice.value);
    }
    if (maxPrice.present) {
      map['max_price'] = Variable<double>(maxPrice.value);
    }
    if (priceTier.present) {
      map['price_tier'] = Variable<String>(priceTier.value);
    }
    if (ticketUrl.present) {
      map['ticket_url'] = Variable<String>(ticketUrl.value);
    }
    if (ticketPlatform.present) {
      map['ticket_platform'] = Variable<String>(ticketPlatform.value);
    }
    if (soldOut.present) {
      map['sold_out'] = Variable<bool>(soldOut.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (ageRestriction.present) {
      map['age_restriction'] = Variable<String>(ageRestriction.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventsTableCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('slug: $slug, ')
          ..write('description: $description, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('doorsTime: $doorsTime, ')
          ..write('onSaleDate: $onSaleDate, ')
          ..write('venueId: $venueId, ')
          ..write('minPrice: $minPrice, ')
          ..write('maxPrice: $maxPrice, ')
          ..write('priceTier: $priceTier, ')
          ..write('ticketUrl: $ticketUrl, ')
          ..write('ticketPlatform: $ticketPlatform, ')
          ..write('soldOut: $soldOut, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('ageRestriction: $ageRestriction, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VenuesTableTable extends VenuesTable
    with TableInfo<$VenuesTableTable, VenuesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VenuesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _slugMeta = const VerificationMeta('slug');
  @override
  late final GeneratedColumn<String> slug = GeneratedColumn<String>(
    'slug',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _neighborhoodMeta = const VerificationMeta(
    'neighborhood',
  );
  @override
  late final GeneratedColumn<String> neighborhood = GeneratedColumn<String>(
    'neighborhood',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _websiteUrlMeta = const VerificationMeta(
    'websiteUrl',
  );
  @override
  late final GeneratedColumn<String> websiteUrl = GeneratedColumn<String>(
    'website_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _upcomingEventCountMeta =
      const VerificationMeta('upcomingEventCount');
  @override
  late final GeneratedColumn<int> upcomingEventCount = GeneratedColumn<int>(
    'upcoming_event_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    slug,
    neighborhood,
    websiteUrl,
    upcomingEventCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'venues_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<VenuesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('slug')) {
      context.handle(
        _slugMeta,
        slug.isAcceptableOrUnknown(data['slug']!, _slugMeta),
      );
    } else if (isInserting) {
      context.missing(_slugMeta);
    }
    if (data.containsKey('neighborhood')) {
      context.handle(
        _neighborhoodMeta,
        neighborhood.isAcceptableOrUnknown(
          data['neighborhood']!,
          _neighborhoodMeta,
        ),
      );
    }
    if (data.containsKey('website_url')) {
      context.handle(
        _websiteUrlMeta,
        websiteUrl.isAcceptableOrUnknown(data['website_url']!, _websiteUrlMeta),
      );
    }
    if (data.containsKey('upcoming_event_count')) {
      context.handle(
        _upcomingEventCountMeta,
        upcomingEventCount.isAcceptableOrUnknown(
          data['upcoming_event_count']!,
          _upcomingEventCountMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VenuesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VenuesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      slug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slug'],
      )!,
      neighborhood: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}neighborhood'],
      ),
      websiteUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}website_url'],
      ),
      upcomingEventCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}upcoming_event_count'],
      )!,
    );
  }

  @override
  $VenuesTableTable createAlias(String alias) {
    return $VenuesTableTable(attachedDatabase, alias);
  }
}

class VenuesTableData extends DataClass implements Insertable<VenuesTableData> {
  final String id;
  final String name;
  final String slug;
  final String? neighborhood;
  final String? websiteUrl;
  final int upcomingEventCount;
  const VenuesTableData({
    required this.id,
    required this.name,
    required this.slug,
    this.neighborhood,
    this.websiteUrl,
    required this.upcomingEventCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['slug'] = Variable<String>(slug);
    if (!nullToAbsent || neighborhood != null) {
      map['neighborhood'] = Variable<String>(neighborhood);
    }
    if (!nullToAbsent || websiteUrl != null) {
      map['website_url'] = Variable<String>(websiteUrl);
    }
    map['upcoming_event_count'] = Variable<int>(upcomingEventCount);
    return map;
  }

  VenuesTableCompanion toCompanion(bool nullToAbsent) {
    return VenuesTableCompanion(
      id: Value(id),
      name: Value(name),
      slug: Value(slug),
      neighborhood: neighborhood == null && nullToAbsent
          ? const Value.absent()
          : Value(neighborhood),
      websiteUrl: websiteUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(websiteUrl),
      upcomingEventCount: Value(upcomingEventCount),
    );
  }

  factory VenuesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VenuesTableData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      slug: serializer.fromJson<String>(json['slug']),
      neighborhood: serializer.fromJson<String?>(json['neighborhood']),
      websiteUrl: serializer.fromJson<String?>(json['websiteUrl']),
      upcomingEventCount: serializer.fromJson<int>(json['upcomingEventCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'slug': serializer.toJson<String>(slug),
      'neighborhood': serializer.toJson<String?>(neighborhood),
      'websiteUrl': serializer.toJson<String?>(websiteUrl),
      'upcomingEventCount': serializer.toJson<int>(upcomingEventCount),
    };
  }

  VenuesTableData copyWith({
    String? id,
    String? name,
    String? slug,
    Value<String?> neighborhood = const Value.absent(),
    Value<String?> websiteUrl = const Value.absent(),
    int? upcomingEventCount,
  }) => VenuesTableData(
    id: id ?? this.id,
    name: name ?? this.name,
    slug: slug ?? this.slug,
    neighborhood: neighborhood.present ? neighborhood.value : this.neighborhood,
    websiteUrl: websiteUrl.present ? websiteUrl.value : this.websiteUrl,
    upcomingEventCount: upcomingEventCount ?? this.upcomingEventCount,
  );
  VenuesTableData copyWithCompanion(VenuesTableCompanion data) {
    return VenuesTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      slug: data.slug.present ? data.slug.value : this.slug,
      neighborhood: data.neighborhood.present
          ? data.neighborhood.value
          : this.neighborhood,
      websiteUrl: data.websiteUrl.present
          ? data.websiteUrl.value
          : this.websiteUrl,
      upcomingEventCount: data.upcomingEventCount.present
          ? data.upcomingEventCount.value
          : this.upcomingEventCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VenuesTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('slug: $slug, ')
          ..write('neighborhood: $neighborhood, ')
          ..write('websiteUrl: $websiteUrl, ')
          ..write('upcomingEventCount: $upcomingEventCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, slug, neighborhood, websiteUrl, upcomingEventCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VenuesTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.slug == this.slug &&
          other.neighborhood == this.neighborhood &&
          other.websiteUrl == this.websiteUrl &&
          other.upcomingEventCount == this.upcomingEventCount);
}

class VenuesTableCompanion extends UpdateCompanion<VenuesTableData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> slug;
  final Value<String?> neighborhood;
  final Value<String?> websiteUrl;
  final Value<int> upcomingEventCount;
  final Value<int> rowid;
  const VenuesTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.slug = const Value.absent(),
    this.neighborhood = const Value.absent(),
    this.websiteUrl = const Value.absent(),
    this.upcomingEventCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VenuesTableCompanion.insert({
    required String id,
    required String name,
    required String slug,
    this.neighborhood = const Value.absent(),
    this.websiteUrl = const Value.absent(),
    this.upcomingEventCount = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       slug = Value(slug);
  static Insertable<VenuesTableData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? slug,
    Expression<String>? neighborhood,
    Expression<String>? websiteUrl,
    Expression<int>? upcomingEventCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (slug != null) 'slug': slug,
      if (neighborhood != null) 'neighborhood': neighborhood,
      if (websiteUrl != null) 'website_url': websiteUrl,
      if (upcomingEventCount != null)
        'upcoming_event_count': upcomingEventCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VenuesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? slug,
    Value<String?>? neighborhood,
    Value<String?>? websiteUrl,
    Value<int>? upcomingEventCount,
    Value<int>? rowid,
  }) {
    return VenuesTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      neighborhood: neighborhood ?? this.neighborhood,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      upcomingEventCount: upcomingEventCount ?? this.upcomingEventCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (slug.present) {
      map['slug'] = Variable<String>(slug.value);
    }
    if (neighborhood.present) {
      map['neighborhood'] = Variable<String>(neighborhood.value);
    }
    if (websiteUrl.present) {
      map['website_url'] = Variable<String>(websiteUrl.value);
    }
    if (upcomingEventCount.present) {
      map['upcoming_event_count'] = Variable<int>(upcomingEventCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VenuesTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('slug: $slug, ')
          ..write('neighborhood: $neighborhood, ')
          ..write('websiteUrl: $websiteUrl, ')
          ..write('upcomingEventCount: $upcomingEventCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ArtistsTableTable extends ArtistsTable
    with TableInfo<$ArtistsTableTable, ArtistsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ArtistsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _slugMeta = const VerificationMeta('slug');
  @override
  late final GeneratedColumn<String> slug = GeneratedColumn<String>(
    'slug',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _genresMeta = const VerificationMeta('genres');
  @override
  late final GeneratedColumn<String> genres = GeneratedColumn<String>(
    'genres',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isLocalMeta = const VerificationMeta(
    'isLocal',
  );
  @override
  late final GeneratedColumn<bool> isLocal = GeneratedColumn<bool>(
    'is_local',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_local" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _spotifyUrlMeta = const VerificationMeta(
    'spotifyUrl',
  );
  @override
  late final GeneratedColumn<String> spotifyUrl = GeneratedColumn<String>(
    'spotify_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bandcampUrlMeta = const VerificationMeta(
    'bandcampUrl',
  );
  @override
  late final GeneratedColumn<String> bandcampUrl = GeneratedColumn<String>(
    'bandcamp_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _instagramUrlMeta = const VerificationMeta(
    'instagramUrl',
  );
  @override
  late final GeneratedColumn<String> instagramUrl = GeneratedColumn<String>(
    'instagram_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _canonicalNameMeta = const VerificationMeta(
    'canonicalName',
  );
  @override
  late final GeneratedColumn<String> canonicalName = GeneratedColumn<String>(
    'canonical_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    slug,
    genres,
    isLocal,
    spotifyUrl,
    bandcampUrl,
    instagramUrl,
    canonicalName,
    imageUrl,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'artists_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<ArtistsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('slug')) {
      context.handle(
        _slugMeta,
        slug.isAcceptableOrUnknown(data['slug']!, _slugMeta),
      );
    } else if (isInserting) {
      context.missing(_slugMeta);
    }
    if (data.containsKey('genres')) {
      context.handle(
        _genresMeta,
        genres.isAcceptableOrUnknown(data['genres']!, _genresMeta),
      );
    }
    if (data.containsKey('is_local')) {
      context.handle(
        _isLocalMeta,
        isLocal.isAcceptableOrUnknown(data['is_local']!, _isLocalMeta),
      );
    }
    if (data.containsKey('spotify_url')) {
      context.handle(
        _spotifyUrlMeta,
        spotifyUrl.isAcceptableOrUnknown(data['spotify_url']!, _spotifyUrlMeta),
      );
    }
    if (data.containsKey('bandcamp_url')) {
      context.handle(
        _bandcampUrlMeta,
        bandcampUrl.isAcceptableOrUnknown(
          data['bandcamp_url']!,
          _bandcampUrlMeta,
        ),
      );
    }
    if (data.containsKey('instagram_url')) {
      context.handle(
        _instagramUrlMeta,
        instagramUrl.isAcceptableOrUnknown(
          data['instagram_url']!,
          _instagramUrlMeta,
        ),
      );
    }
    if (data.containsKey('canonical_name')) {
      context.handle(
        _canonicalNameMeta,
        canonicalName.isAcceptableOrUnknown(
          data['canonical_name']!,
          _canonicalNameMeta,
        ),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ArtistsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ArtistsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      slug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slug'],
      )!,
      genres: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}genres'],
      )!,
      isLocal: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_local'],
      )!,
      spotifyUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}spotify_url'],
      ),
      bandcampUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bandcamp_url'],
      ),
      instagramUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}instagram_url'],
      ),
      canonicalName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}canonical_name'],
      ),
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
    );
  }

  @override
  $ArtistsTableTable createAlias(String alias) {
    return $ArtistsTableTable(attachedDatabase, alias);
  }
}

class ArtistsTableData extends DataClass
    implements Insertable<ArtistsTableData> {
  final String id;
  final String name;
  final String slug;
  final String genres;
  final bool isLocal;
  final String? spotifyUrl;
  final String? bandcampUrl;
  final String? instagramUrl;
  final String? canonicalName;
  final String? imageUrl;
  const ArtistsTableData({
    required this.id,
    required this.name,
    required this.slug,
    required this.genres,
    required this.isLocal,
    this.spotifyUrl,
    this.bandcampUrl,
    this.instagramUrl,
    this.canonicalName,
    this.imageUrl,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['slug'] = Variable<String>(slug);
    map['genres'] = Variable<String>(genres);
    map['is_local'] = Variable<bool>(isLocal);
    if (!nullToAbsent || spotifyUrl != null) {
      map['spotify_url'] = Variable<String>(spotifyUrl);
    }
    if (!nullToAbsent || bandcampUrl != null) {
      map['bandcamp_url'] = Variable<String>(bandcampUrl);
    }
    if (!nullToAbsent || instagramUrl != null) {
      map['instagram_url'] = Variable<String>(instagramUrl);
    }
    if (!nullToAbsent || canonicalName != null) {
      map['canonical_name'] = Variable<String>(canonicalName);
    }
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    return map;
  }

  ArtistsTableCompanion toCompanion(bool nullToAbsent) {
    return ArtistsTableCompanion(
      id: Value(id),
      name: Value(name),
      slug: Value(slug),
      genres: Value(genres),
      isLocal: Value(isLocal),
      spotifyUrl: spotifyUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(spotifyUrl),
      bandcampUrl: bandcampUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(bandcampUrl),
      instagramUrl: instagramUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(instagramUrl),
      canonicalName: canonicalName == null && nullToAbsent
          ? const Value.absent()
          : Value(canonicalName),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
    );
  }

  factory ArtistsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ArtistsTableData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      slug: serializer.fromJson<String>(json['slug']),
      genres: serializer.fromJson<String>(json['genres']),
      isLocal: serializer.fromJson<bool>(json['isLocal']),
      spotifyUrl: serializer.fromJson<String?>(json['spotifyUrl']),
      bandcampUrl: serializer.fromJson<String?>(json['bandcampUrl']),
      instagramUrl: serializer.fromJson<String?>(json['instagramUrl']),
      canonicalName: serializer.fromJson<String?>(json['canonicalName']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'slug': serializer.toJson<String>(slug),
      'genres': serializer.toJson<String>(genres),
      'isLocal': serializer.toJson<bool>(isLocal),
      'spotifyUrl': serializer.toJson<String?>(spotifyUrl),
      'bandcampUrl': serializer.toJson<String?>(bandcampUrl),
      'instagramUrl': serializer.toJson<String?>(instagramUrl),
      'canonicalName': serializer.toJson<String?>(canonicalName),
      'imageUrl': serializer.toJson<String?>(imageUrl),
    };
  }

  ArtistsTableData copyWith({
    String? id,
    String? name,
    String? slug,
    String? genres,
    bool? isLocal,
    Value<String?> spotifyUrl = const Value.absent(),
    Value<String?> bandcampUrl = const Value.absent(),
    Value<String?> instagramUrl = const Value.absent(),
    Value<String?> canonicalName = const Value.absent(),
    Value<String?> imageUrl = const Value.absent(),
  }) => ArtistsTableData(
    id: id ?? this.id,
    name: name ?? this.name,
    slug: slug ?? this.slug,
    genres: genres ?? this.genres,
    isLocal: isLocal ?? this.isLocal,
    spotifyUrl: spotifyUrl.present ? spotifyUrl.value : this.spotifyUrl,
    bandcampUrl: bandcampUrl.present ? bandcampUrl.value : this.bandcampUrl,
    instagramUrl: instagramUrl.present ? instagramUrl.value : this.instagramUrl,
    canonicalName: canonicalName.present
        ? canonicalName.value
        : this.canonicalName,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
  );
  ArtistsTableData copyWithCompanion(ArtistsTableCompanion data) {
    return ArtistsTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      slug: data.slug.present ? data.slug.value : this.slug,
      genres: data.genres.present ? data.genres.value : this.genres,
      isLocal: data.isLocal.present ? data.isLocal.value : this.isLocal,
      spotifyUrl: data.spotifyUrl.present
          ? data.spotifyUrl.value
          : this.spotifyUrl,
      bandcampUrl: data.bandcampUrl.present
          ? data.bandcampUrl.value
          : this.bandcampUrl,
      instagramUrl: data.instagramUrl.present
          ? data.instagramUrl.value
          : this.instagramUrl,
      canonicalName: data.canonicalName.present
          ? data.canonicalName.value
          : this.canonicalName,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ArtistsTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('slug: $slug, ')
          ..write('genres: $genres, ')
          ..write('isLocal: $isLocal, ')
          ..write('spotifyUrl: $spotifyUrl, ')
          ..write('bandcampUrl: $bandcampUrl, ')
          ..write('instagramUrl: $instagramUrl, ')
          ..write('canonicalName: $canonicalName, ')
          ..write('imageUrl: $imageUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    slug,
    genres,
    isLocal,
    spotifyUrl,
    bandcampUrl,
    instagramUrl,
    canonicalName,
    imageUrl,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ArtistsTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.slug == this.slug &&
          other.genres == this.genres &&
          other.isLocal == this.isLocal &&
          other.spotifyUrl == this.spotifyUrl &&
          other.bandcampUrl == this.bandcampUrl &&
          other.instagramUrl == this.instagramUrl &&
          other.canonicalName == this.canonicalName &&
          other.imageUrl == this.imageUrl);
}

class ArtistsTableCompanion extends UpdateCompanion<ArtistsTableData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> slug;
  final Value<String> genres;
  final Value<bool> isLocal;
  final Value<String?> spotifyUrl;
  final Value<String?> bandcampUrl;
  final Value<String?> instagramUrl;
  final Value<String?> canonicalName;
  final Value<String?> imageUrl;
  final Value<int> rowid;
  const ArtistsTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.slug = const Value.absent(),
    this.genres = const Value.absent(),
    this.isLocal = const Value.absent(),
    this.spotifyUrl = const Value.absent(),
    this.bandcampUrl = const Value.absent(),
    this.instagramUrl = const Value.absent(),
    this.canonicalName = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ArtistsTableCompanion.insert({
    required String id,
    required String name,
    required String slug,
    this.genres = const Value.absent(),
    this.isLocal = const Value.absent(),
    this.spotifyUrl = const Value.absent(),
    this.bandcampUrl = const Value.absent(),
    this.instagramUrl = const Value.absent(),
    this.canonicalName = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       slug = Value(slug);
  static Insertable<ArtistsTableData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? slug,
    Expression<String>? genres,
    Expression<bool>? isLocal,
    Expression<String>? spotifyUrl,
    Expression<String>? bandcampUrl,
    Expression<String>? instagramUrl,
    Expression<String>? canonicalName,
    Expression<String>? imageUrl,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (slug != null) 'slug': slug,
      if (genres != null) 'genres': genres,
      if (isLocal != null) 'is_local': isLocal,
      if (spotifyUrl != null) 'spotify_url': spotifyUrl,
      if (bandcampUrl != null) 'bandcamp_url': bandcampUrl,
      if (instagramUrl != null) 'instagram_url': instagramUrl,
      if (canonicalName != null) 'canonical_name': canonicalName,
      if (imageUrl != null) 'image_url': imageUrl,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ArtistsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? slug,
    Value<String>? genres,
    Value<bool>? isLocal,
    Value<String?>? spotifyUrl,
    Value<String?>? bandcampUrl,
    Value<String?>? instagramUrl,
    Value<String?>? canonicalName,
    Value<String?>? imageUrl,
    Value<int>? rowid,
  }) {
    return ArtistsTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      genres: genres ?? this.genres,
      isLocal: isLocal ?? this.isLocal,
      spotifyUrl: spotifyUrl ?? this.spotifyUrl,
      bandcampUrl: bandcampUrl ?? this.bandcampUrl,
      instagramUrl: instagramUrl ?? this.instagramUrl,
      canonicalName: canonicalName ?? this.canonicalName,
      imageUrl: imageUrl ?? this.imageUrl,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (slug.present) {
      map['slug'] = Variable<String>(slug.value);
    }
    if (genres.present) {
      map['genres'] = Variable<String>(genres.value);
    }
    if (isLocal.present) {
      map['is_local'] = Variable<bool>(isLocal.value);
    }
    if (spotifyUrl.present) {
      map['spotify_url'] = Variable<String>(spotifyUrl.value);
    }
    if (bandcampUrl.present) {
      map['bandcamp_url'] = Variable<String>(bandcampUrl.value);
    }
    if (instagramUrl.present) {
      map['instagram_url'] = Variable<String>(instagramUrl.value);
    }
    if (canonicalName.present) {
      map['canonical_name'] = Variable<String>(canonicalName.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ArtistsTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('slug: $slug, ')
          ..write('genres: $genres, ')
          ..write('isLocal: $isLocal, ')
          ..write('spotifyUrl: $spotifyUrl, ')
          ..write('bandcampUrl: $bandcampUrl, ')
          ..write('instagramUrl: $instagramUrl, ')
          ..write('canonicalName: $canonicalName, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EventArtistsTableTable extends EventArtistsTable
    with TableInfo<$EventArtistsTableTable, EventArtistsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventArtistsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _artistIdMeta = const VerificationMeta(
    'artistId',
  );
  @override
  late final GeneratedColumn<String> artistId = GeneratedColumn<String>(
    'artist_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [eventId, artistId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'event_artists_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<EventArtistsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('artist_id')) {
      context.handle(
        _artistIdMeta,
        artistId.isAcceptableOrUnknown(data['artist_id']!, _artistIdMeta),
      );
    } else if (isInserting) {
      context.missing(_artistIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {eventId, artistId};
  @override
  EventArtistsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EventArtistsTableData(
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      )!,
      artistId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist_id'],
      )!,
    );
  }

  @override
  $EventArtistsTableTable createAlias(String alias) {
    return $EventArtistsTableTable(attachedDatabase, alias);
  }
}

class EventArtistsTableData extends DataClass
    implements Insertable<EventArtistsTableData> {
  final String eventId;
  final String artistId;
  const EventArtistsTableData({required this.eventId, required this.artistId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['event_id'] = Variable<String>(eventId);
    map['artist_id'] = Variable<String>(artistId);
    return map;
  }

  EventArtistsTableCompanion toCompanion(bool nullToAbsent) {
    return EventArtistsTableCompanion(
      eventId: Value(eventId),
      artistId: Value(artistId),
    );
  }

  factory EventArtistsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EventArtistsTableData(
      eventId: serializer.fromJson<String>(json['eventId']),
      artistId: serializer.fromJson<String>(json['artistId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'eventId': serializer.toJson<String>(eventId),
      'artistId': serializer.toJson<String>(artistId),
    };
  }

  EventArtistsTableData copyWith({String? eventId, String? artistId}) =>
      EventArtistsTableData(
        eventId: eventId ?? this.eventId,
        artistId: artistId ?? this.artistId,
      );
  EventArtistsTableData copyWithCompanion(EventArtistsTableCompanion data) {
    return EventArtistsTableData(
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      artistId: data.artistId.present ? data.artistId.value : this.artistId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EventArtistsTableData(')
          ..write('eventId: $eventId, ')
          ..write('artistId: $artistId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(eventId, artistId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EventArtistsTableData &&
          other.eventId == this.eventId &&
          other.artistId == this.artistId);
}

class EventArtistsTableCompanion
    extends UpdateCompanion<EventArtistsTableData> {
  final Value<String> eventId;
  final Value<String> artistId;
  final Value<int> rowid;
  const EventArtistsTableCompanion({
    this.eventId = const Value.absent(),
    this.artistId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EventArtistsTableCompanion.insert({
    required String eventId,
    required String artistId,
    this.rowid = const Value.absent(),
  }) : eventId = Value(eventId),
       artistId = Value(artistId);
  static Insertable<EventArtistsTableData> custom({
    Expression<String>? eventId,
    Expression<String>? artistId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (eventId != null) 'event_id': eventId,
      if (artistId != null) 'artist_id': artistId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EventArtistsTableCompanion copyWith({
    Value<String>? eventId,
    Value<String>? artistId,
    Value<int>? rowid,
  }) {
    return EventArtistsTableCompanion(
      eventId: eventId ?? this.eventId,
      artistId: artistId ?? this.artistId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (artistId.present) {
      map['artist_id'] = Variable<String>(artistId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventArtistsTableCompanion(')
          ..write('eventId: $eventId, ')
          ..write('artistId: $artistId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BookmarksTableTable extends BookmarksTable
    with TableInfo<$BookmarksTableTable, BookmarksTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookmarksTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bookmarkedAtMeta = const VerificationMeta(
    'bookmarkedAt',
  );
  @override
  late final GeneratedColumn<DateTime> bookmarkedAt = GeneratedColumn<DateTime>(
    'bookmarked_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [eventId, bookmarkedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bookmarks_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<BookmarksTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('bookmarked_at')) {
      context.handle(
        _bookmarkedAtMeta,
        bookmarkedAt.isAcceptableOrUnknown(
          data['bookmarked_at']!,
          _bookmarkedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_bookmarkedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {eventId};
  @override
  BookmarksTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BookmarksTableData(
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      )!,
      bookmarkedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}bookmarked_at'],
      )!,
    );
  }

  @override
  $BookmarksTableTable createAlias(String alias) {
    return $BookmarksTableTable(attachedDatabase, alias);
  }
}

class BookmarksTableData extends DataClass
    implements Insertable<BookmarksTableData> {
  final String eventId;
  final DateTime bookmarkedAt;
  const BookmarksTableData({required this.eventId, required this.bookmarkedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['event_id'] = Variable<String>(eventId);
    map['bookmarked_at'] = Variable<DateTime>(bookmarkedAt);
    return map;
  }

  BookmarksTableCompanion toCompanion(bool nullToAbsent) {
    return BookmarksTableCompanion(
      eventId: Value(eventId),
      bookmarkedAt: Value(bookmarkedAt),
    );
  }

  factory BookmarksTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BookmarksTableData(
      eventId: serializer.fromJson<String>(json['eventId']),
      bookmarkedAt: serializer.fromJson<DateTime>(json['bookmarkedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'eventId': serializer.toJson<String>(eventId),
      'bookmarkedAt': serializer.toJson<DateTime>(bookmarkedAt),
    };
  }

  BookmarksTableData copyWith({String? eventId, DateTime? bookmarkedAt}) =>
      BookmarksTableData(
        eventId: eventId ?? this.eventId,
        bookmarkedAt: bookmarkedAt ?? this.bookmarkedAt,
      );
  BookmarksTableData copyWithCompanion(BookmarksTableCompanion data) {
    return BookmarksTableData(
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      bookmarkedAt: data.bookmarkedAt.present
          ? data.bookmarkedAt.value
          : this.bookmarkedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BookmarksTableData(')
          ..write('eventId: $eventId, ')
          ..write('bookmarkedAt: $bookmarkedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(eventId, bookmarkedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BookmarksTableData &&
          other.eventId == this.eventId &&
          other.bookmarkedAt == this.bookmarkedAt);
}

class BookmarksTableCompanion extends UpdateCompanion<BookmarksTableData> {
  final Value<String> eventId;
  final Value<DateTime> bookmarkedAt;
  final Value<int> rowid;
  const BookmarksTableCompanion({
    this.eventId = const Value.absent(),
    this.bookmarkedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BookmarksTableCompanion.insert({
    required String eventId,
    required DateTime bookmarkedAt,
    this.rowid = const Value.absent(),
  }) : eventId = Value(eventId),
       bookmarkedAt = Value(bookmarkedAt);
  static Insertable<BookmarksTableData> custom({
    Expression<String>? eventId,
    Expression<DateTime>? bookmarkedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (eventId != null) 'event_id': eventId,
      if (bookmarkedAt != null) 'bookmarked_at': bookmarkedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BookmarksTableCompanion copyWith({
    Value<String>? eventId,
    Value<DateTime>? bookmarkedAt,
    Value<int>? rowid,
  }) {
    return BookmarksTableCompanion(
      eventId: eventId ?? this.eventId,
      bookmarkedAt: bookmarkedAt ?? this.bookmarkedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (bookmarkedAt.present) {
      map['bookmarked_at'] = Variable<DateTime>(bookmarkedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookmarksTableCompanion(')
          ..write('eventId: $eventId, ')
          ..write('bookmarkedAt: $bookmarkedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncMetadataTableTable extends SyncMetadataTable
    with TableInfo<$SyncMetadataTableTable, SyncMetadataTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncMetadataTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dataTypeMeta = const VerificationMeta(
    'dataType',
  );
  @override
  late final GeneratedColumn<String> dataType = GeneratedColumn<String>(
    'data_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [dataType, lastSyncedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_metadata_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncMetadataTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('data_type')) {
      context.handle(
        _dataTypeMeta,
        dataType.isAcceptableOrUnknown(data['data_type']!, _dataTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_dataTypeMeta);
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastSyncedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {dataType};
  @override
  SyncMetadataTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncMetadataTableData(
      dataType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data_type'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      )!,
    );
  }

  @override
  $SyncMetadataTableTable createAlias(String alias) {
    return $SyncMetadataTableTable(attachedDatabase, alias);
  }
}

class SyncMetadataTableData extends DataClass
    implements Insertable<SyncMetadataTableData> {
  final String dataType;
  final DateTime lastSyncedAt;
  const SyncMetadataTableData({
    required this.dataType,
    required this.lastSyncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['data_type'] = Variable<String>(dataType);
    map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    return map;
  }

  SyncMetadataTableCompanion toCompanion(bool nullToAbsent) {
    return SyncMetadataTableCompanion(
      dataType: Value(dataType),
      lastSyncedAt: Value(lastSyncedAt),
    );
  }

  factory SyncMetadataTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncMetadataTableData(
      dataType: serializer.fromJson<String>(json['dataType']),
      lastSyncedAt: serializer.fromJson<DateTime>(json['lastSyncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'dataType': serializer.toJson<String>(dataType),
      'lastSyncedAt': serializer.toJson<DateTime>(lastSyncedAt),
    };
  }

  SyncMetadataTableData copyWith({String? dataType, DateTime? lastSyncedAt}) =>
      SyncMetadataTableData(
        dataType: dataType ?? this.dataType,
        lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      );
  SyncMetadataTableData copyWithCompanion(SyncMetadataTableCompanion data) {
    return SyncMetadataTableData(
      dataType: data.dataType.present ? data.dataType.value : this.dataType,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetadataTableData(')
          ..write('dataType: $dataType, ')
          ..write('lastSyncedAt: $lastSyncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(dataType, lastSyncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncMetadataTableData &&
          other.dataType == this.dataType &&
          other.lastSyncedAt == this.lastSyncedAt);
}

class SyncMetadataTableCompanion
    extends UpdateCompanion<SyncMetadataTableData> {
  final Value<String> dataType;
  final Value<DateTime> lastSyncedAt;
  final Value<int> rowid;
  const SyncMetadataTableCompanion({
    this.dataType = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncMetadataTableCompanion.insert({
    required String dataType,
    required DateTime lastSyncedAt,
    this.rowid = const Value.absent(),
  }) : dataType = Value(dataType),
       lastSyncedAt = Value(lastSyncedAt);
  static Insertable<SyncMetadataTableData> custom({
    Expression<String>? dataType,
    Expression<DateTime>? lastSyncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (dataType != null) 'data_type': dataType,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncMetadataTableCompanion copyWith({
    Value<String>? dataType,
    Value<DateTime>? lastSyncedAt,
    Value<int>? rowid,
  }) {
    return SyncMetadataTableCompanion(
      dataType: dataType ?? this.dataType,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (dataType.present) {
      map['data_type'] = Variable<String>(dataType.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetadataTableCompanion(')
          ..write('dataType: $dataType, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $EventsTableTable eventsTable = $EventsTableTable(this);
  late final $VenuesTableTable venuesTable = $VenuesTableTable(this);
  late final $ArtistsTableTable artistsTable = $ArtistsTableTable(this);
  late final $EventArtistsTableTable eventArtistsTable =
      $EventArtistsTableTable(this);
  late final $BookmarksTableTable bookmarksTable = $BookmarksTableTable(this);
  late final $SyncMetadataTableTable syncMetadataTable =
      $SyncMetadataTableTable(this);
  late final EventDao eventDao = EventDao(this as AppDatabase);
  late final ArtistDao artistDao = ArtistDao(this as AppDatabase);
  late final VenueDao venueDao = VenueDao(this as AppDatabase);
  late final BookmarkDao bookmarkDao = BookmarkDao(this as AppDatabase);
  late final SyncMetadataDao syncMetadataDao = SyncMetadataDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    eventsTable,
    venuesTable,
    artistsTable,
    eventArtistsTable,
    bookmarksTable,
    syncMetadataTable,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$EventsTableTableCreateCompanionBuilder =
    EventsTableCompanion Function({
      required String id,
      required String title,
      required String slug,
      Value<String?> description,
      required DateTime startTime,
      Value<DateTime?> endTime,
      Value<DateTime?> doorsTime,
      Value<DateTime?> onSaleDate,
      Value<String?> venueId,
      Value<double?> minPrice,
      Value<double?> maxPrice,
      Value<String?> priceTier,
      Value<String?> ticketUrl,
      Value<String?> ticketPlatform,
      Value<bool> soldOut,
      Value<String?> imageUrl,
      Value<String> ageRestriction,
      Value<String> status,
      Value<DateTime?> createdAt,
      Value<int> rowid,
    });
typedef $$EventsTableTableUpdateCompanionBuilder =
    EventsTableCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> slug,
      Value<String?> description,
      Value<DateTime> startTime,
      Value<DateTime?> endTime,
      Value<DateTime?> doorsTime,
      Value<DateTime?> onSaleDate,
      Value<String?> venueId,
      Value<double?> minPrice,
      Value<double?> maxPrice,
      Value<String?> priceTier,
      Value<String?> ticketUrl,
      Value<String?> ticketPlatform,
      Value<bool> soldOut,
      Value<String?> imageUrl,
      Value<String> ageRestriction,
      Value<String> status,
      Value<DateTime?> createdAt,
      Value<int> rowid,
    });

class $$EventsTableTableFilterComposer
    extends Composer<_$AppDatabase, $EventsTableTable> {
  $$EventsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get doorsTime => $composableBuilder(
    column: $table.doorsTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get onSaleDate => $composableBuilder(
    column: $table.onSaleDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get venueId => $composableBuilder(
    column: $table.venueId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get minPrice => $composableBuilder(
    column: $table.minPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get maxPrice => $composableBuilder(
    column: $table.maxPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get priceTier => $composableBuilder(
    column: $table.priceTier,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ticketUrl => $composableBuilder(
    column: $table.ticketUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ticketPlatform => $composableBuilder(
    column: $table.ticketPlatform,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get soldOut => $composableBuilder(
    column: $table.soldOut,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ageRestriction => $composableBuilder(
    column: $table.ageRestriction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EventsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $EventsTableTable> {
  $$EventsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get doorsTime => $composableBuilder(
    column: $table.doorsTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get onSaleDate => $composableBuilder(
    column: $table.onSaleDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get venueId => $composableBuilder(
    column: $table.venueId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get minPrice => $composableBuilder(
    column: $table.minPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get maxPrice => $composableBuilder(
    column: $table.maxPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get priceTier => $composableBuilder(
    column: $table.priceTier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ticketUrl => $composableBuilder(
    column: $table.ticketUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ticketPlatform => $composableBuilder(
    column: $table.ticketPlatform,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get soldOut => $composableBuilder(
    column: $table.soldOut,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ageRestriction => $composableBuilder(
    column: $table.ageRestriction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EventsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $EventsTableTable> {
  $$EventsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get slug =>
      $composableBuilder(column: $table.slug, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<DateTime> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<DateTime> get doorsTime =>
      $composableBuilder(column: $table.doorsTime, builder: (column) => column);

  GeneratedColumn<DateTime> get onSaleDate => $composableBuilder(
    column: $table.onSaleDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get venueId =>
      $composableBuilder(column: $table.venueId, builder: (column) => column);

  GeneratedColumn<double> get minPrice =>
      $composableBuilder(column: $table.minPrice, builder: (column) => column);

  GeneratedColumn<double> get maxPrice =>
      $composableBuilder(column: $table.maxPrice, builder: (column) => column);

  GeneratedColumn<String> get priceTier =>
      $composableBuilder(column: $table.priceTier, builder: (column) => column);

  GeneratedColumn<String> get ticketUrl =>
      $composableBuilder(column: $table.ticketUrl, builder: (column) => column);

  GeneratedColumn<String> get ticketPlatform => $composableBuilder(
    column: $table.ticketPlatform,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get soldOut =>
      $composableBuilder(column: $table.soldOut, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<String> get ageRestriction => $composableBuilder(
    column: $table.ageRestriction,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$EventsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EventsTableTable,
          EventsTableData,
          $$EventsTableTableFilterComposer,
          $$EventsTableTableOrderingComposer,
          $$EventsTableTableAnnotationComposer,
          $$EventsTableTableCreateCompanionBuilder,
          $$EventsTableTableUpdateCompanionBuilder,
          (
            EventsTableData,
            BaseReferences<_$AppDatabase, $EventsTableTable, EventsTableData>,
          ),
          EventsTableData,
          PrefetchHooks Function()
        > {
  $$EventsTableTableTableManager(_$AppDatabase db, $EventsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> slug = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime> startTime = const Value.absent(),
                Value<DateTime?> endTime = const Value.absent(),
                Value<DateTime?> doorsTime = const Value.absent(),
                Value<DateTime?> onSaleDate = const Value.absent(),
                Value<String?> venueId = const Value.absent(),
                Value<double?> minPrice = const Value.absent(),
                Value<double?> maxPrice = const Value.absent(),
                Value<String?> priceTier = const Value.absent(),
                Value<String?> ticketUrl = const Value.absent(),
                Value<String?> ticketPlatform = const Value.absent(),
                Value<bool> soldOut = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String> ageRestriction = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventsTableCompanion(
                id: id,
                title: title,
                slug: slug,
                description: description,
                startTime: startTime,
                endTime: endTime,
                doorsTime: doorsTime,
                onSaleDate: onSaleDate,
                venueId: venueId,
                minPrice: minPrice,
                maxPrice: maxPrice,
                priceTier: priceTier,
                ticketUrl: ticketUrl,
                ticketPlatform: ticketPlatform,
                soldOut: soldOut,
                imageUrl: imageUrl,
                ageRestriction: ageRestriction,
                status: status,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String slug,
                Value<String?> description = const Value.absent(),
                required DateTime startTime,
                Value<DateTime?> endTime = const Value.absent(),
                Value<DateTime?> doorsTime = const Value.absent(),
                Value<DateTime?> onSaleDate = const Value.absent(),
                Value<String?> venueId = const Value.absent(),
                Value<double?> minPrice = const Value.absent(),
                Value<double?> maxPrice = const Value.absent(),
                Value<String?> priceTier = const Value.absent(),
                Value<String?> ticketUrl = const Value.absent(),
                Value<String?> ticketPlatform = const Value.absent(),
                Value<bool> soldOut = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String> ageRestriction = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventsTableCompanion.insert(
                id: id,
                title: title,
                slug: slug,
                description: description,
                startTime: startTime,
                endTime: endTime,
                doorsTime: doorsTime,
                onSaleDate: onSaleDate,
                venueId: venueId,
                minPrice: minPrice,
                maxPrice: maxPrice,
                priceTier: priceTier,
                ticketUrl: ticketUrl,
                ticketPlatform: ticketPlatform,
                soldOut: soldOut,
                imageUrl: imageUrl,
                ageRestriction: ageRestriction,
                status: status,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EventsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EventsTableTable,
      EventsTableData,
      $$EventsTableTableFilterComposer,
      $$EventsTableTableOrderingComposer,
      $$EventsTableTableAnnotationComposer,
      $$EventsTableTableCreateCompanionBuilder,
      $$EventsTableTableUpdateCompanionBuilder,
      (
        EventsTableData,
        BaseReferences<_$AppDatabase, $EventsTableTable, EventsTableData>,
      ),
      EventsTableData,
      PrefetchHooks Function()
    >;
typedef $$VenuesTableTableCreateCompanionBuilder =
    VenuesTableCompanion Function({
      required String id,
      required String name,
      required String slug,
      Value<String?> neighborhood,
      Value<String?> websiteUrl,
      Value<int> upcomingEventCount,
      Value<int> rowid,
    });
typedef $$VenuesTableTableUpdateCompanionBuilder =
    VenuesTableCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> slug,
      Value<String?> neighborhood,
      Value<String?> websiteUrl,
      Value<int> upcomingEventCount,
      Value<int> rowid,
    });

class $$VenuesTableTableFilterComposer
    extends Composer<_$AppDatabase, $VenuesTableTable> {
  $$VenuesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get neighborhood => $composableBuilder(
    column: $table.neighborhood,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get websiteUrl => $composableBuilder(
    column: $table.websiteUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get upcomingEventCount => $composableBuilder(
    column: $table.upcomingEventCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VenuesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $VenuesTableTable> {
  $$VenuesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get neighborhood => $composableBuilder(
    column: $table.neighborhood,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get websiteUrl => $composableBuilder(
    column: $table.websiteUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get upcomingEventCount => $composableBuilder(
    column: $table.upcomingEventCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VenuesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $VenuesTableTable> {
  $$VenuesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get slug =>
      $composableBuilder(column: $table.slug, builder: (column) => column);

  GeneratedColumn<String> get neighborhood => $composableBuilder(
    column: $table.neighborhood,
    builder: (column) => column,
  );

  GeneratedColumn<String> get websiteUrl => $composableBuilder(
    column: $table.websiteUrl,
    builder: (column) => column,
  );

  GeneratedColumn<int> get upcomingEventCount => $composableBuilder(
    column: $table.upcomingEventCount,
    builder: (column) => column,
  );
}

class $$VenuesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VenuesTableTable,
          VenuesTableData,
          $$VenuesTableTableFilterComposer,
          $$VenuesTableTableOrderingComposer,
          $$VenuesTableTableAnnotationComposer,
          $$VenuesTableTableCreateCompanionBuilder,
          $$VenuesTableTableUpdateCompanionBuilder,
          (
            VenuesTableData,
            BaseReferences<_$AppDatabase, $VenuesTableTable, VenuesTableData>,
          ),
          VenuesTableData,
          PrefetchHooks Function()
        > {
  $$VenuesTableTableTableManager(_$AppDatabase db, $VenuesTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VenuesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VenuesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VenuesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> slug = const Value.absent(),
                Value<String?> neighborhood = const Value.absent(),
                Value<String?> websiteUrl = const Value.absent(),
                Value<int> upcomingEventCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VenuesTableCompanion(
                id: id,
                name: name,
                slug: slug,
                neighborhood: neighborhood,
                websiteUrl: websiteUrl,
                upcomingEventCount: upcomingEventCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String slug,
                Value<String?> neighborhood = const Value.absent(),
                Value<String?> websiteUrl = const Value.absent(),
                Value<int> upcomingEventCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VenuesTableCompanion.insert(
                id: id,
                name: name,
                slug: slug,
                neighborhood: neighborhood,
                websiteUrl: websiteUrl,
                upcomingEventCount: upcomingEventCount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VenuesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VenuesTableTable,
      VenuesTableData,
      $$VenuesTableTableFilterComposer,
      $$VenuesTableTableOrderingComposer,
      $$VenuesTableTableAnnotationComposer,
      $$VenuesTableTableCreateCompanionBuilder,
      $$VenuesTableTableUpdateCompanionBuilder,
      (
        VenuesTableData,
        BaseReferences<_$AppDatabase, $VenuesTableTable, VenuesTableData>,
      ),
      VenuesTableData,
      PrefetchHooks Function()
    >;
typedef $$ArtistsTableTableCreateCompanionBuilder =
    ArtistsTableCompanion Function({
      required String id,
      required String name,
      required String slug,
      Value<String> genres,
      Value<bool> isLocal,
      Value<String?> spotifyUrl,
      Value<String?> bandcampUrl,
      Value<String?> instagramUrl,
      Value<String?> canonicalName,
      Value<String?> imageUrl,
      Value<int> rowid,
    });
typedef $$ArtistsTableTableUpdateCompanionBuilder =
    ArtistsTableCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> slug,
      Value<String> genres,
      Value<bool> isLocal,
      Value<String?> spotifyUrl,
      Value<String?> bandcampUrl,
      Value<String?> instagramUrl,
      Value<String?> canonicalName,
      Value<String?> imageUrl,
      Value<int> rowid,
    });

class $$ArtistsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ArtistsTableTable> {
  $$ArtistsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get genres => $composableBuilder(
    column: $table.genres,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isLocal => $composableBuilder(
    column: $table.isLocal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get spotifyUrl => $composableBuilder(
    column: $table.spotifyUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bandcampUrl => $composableBuilder(
    column: $table.bandcampUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get instagramUrl => $composableBuilder(
    column: $table.instagramUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get canonicalName => $composableBuilder(
    column: $table.canonicalName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ArtistsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ArtistsTableTable> {
  $$ArtistsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get genres => $composableBuilder(
    column: $table.genres,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isLocal => $composableBuilder(
    column: $table.isLocal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get spotifyUrl => $composableBuilder(
    column: $table.spotifyUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bandcampUrl => $composableBuilder(
    column: $table.bandcampUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get instagramUrl => $composableBuilder(
    column: $table.instagramUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get canonicalName => $composableBuilder(
    column: $table.canonicalName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ArtistsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ArtistsTableTable> {
  $$ArtistsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get slug =>
      $composableBuilder(column: $table.slug, builder: (column) => column);

  GeneratedColumn<String> get genres =>
      $composableBuilder(column: $table.genres, builder: (column) => column);

  GeneratedColumn<bool> get isLocal =>
      $composableBuilder(column: $table.isLocal, builder: (column) => column);

  GeneratedColumn<String> get spotifyUrl => $composableBuilder(
    column: $table.spotifyUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bandcampUrl => $composableBuilder(
    column: $table.bandcampUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get instagramUrl => $composableBuilder(
    column: $table.instagramUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get canonicalName => $composableBuilder(
    column: $table.canonicalName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);
}

class $$ArtistsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ArtistsTableTable,
          ArtistsTableData,
          $$ArtistsTableTableFilterComposer,
          $$ArtistsTableTableOrderingComposer,
          $$ArtistsTableTableAnnotationComposer,
          $$ArtistsTableTableCreateCompanionBuilder,
          $$ArtistsTableTableUpdateCompanionBuilder,
          (
            ArtistsTableData,
            BaseReferences<_$AppDatabase, $ArtistsTableTable, ArtistsTableData>,
          ),
          ArtistsTableData,
          PrefetchHooks Function()
        > {
  $$ArtistsTableTableTableManager(_$AppDatabase db, $ArtistsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ArtistsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ArtistsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ArtistsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> slug = const Value.absent(),
                Value<String> genres = const Value.absent(),
                Value<bool> isLocal = const Value.absent(),
                Value<String?> spotifyUrl = const Value.absent(),
                Value<String?> bandcampUrl = const Value.absent(),
                Value<String?> instagramUrl = const Value.absent(),
                Value<String?> canonicalName = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ArtistsTableCompanion(
                id: id,
                name: name,
                slug: slug,
                genres: genres,
                isLocal: isLocal,
                spotifyUrl: spotifyUrl,
                bandcampUrl: bandcampUrl,
                instagramUrl: instagramUrl,
                canonicalName: canonicalName,
                imageUrl: imageUrl,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String slug,
                Value<String> genres = const Value.absent(),
                Value<bool> isLocal = const Value.absent(),
                Value<String?> spotifyUrl = const Value.absent(),
                Value<String?> bandcampUrl = const Value.absent(),
                Value<String?> instagramUrl = const Value.absent(),
                Value<String?> canonicalName = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ArtistsTableCompanion.insert(
                id: id,
                name: name,
                slug: slug,
                genres: genres,
                isLocal: isLocal,
                spotifyUrl: spotifyUrl,
                bandcampUrl: bandcampUrl,
                instagramUrl: instagramUrl,
                canonicalName: canonicalName,
                imageUrl: imageUrl,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ArtistsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ArtistsTableTable,
      ArtistsTableData,
      $$ArtistsTableTableFilterComposer,
      $$ArtistsTableTableOrderingComposer,
      $$ArtistsTableTableAnnotationComposer,
      $$ArtistsTableTableCreateCompanionBuilder,
      $$ArtistsTableTableUpdateCompanionBuilder,
      (
        ArtistsTableData,
        BaseReferences<_$AppDatabase, $ArtistsTableTable, ArtistsTableData>,
      ),
      ArtistsTableData,
      PrefetchHooks Function()
    >;
typedef $$EventArtistsTableTableCreateCompanionBuilder =
    EventArtistsTableCompanion Function({
      required String eventId,
      required String artistId,
      Value<int> rowid,
    });
typedef $$EventArtistsTableTableUpdateCompanionBuilder =
    EventArtistsTableCompanion Function({
      Value<String> eventId,
      Value<String> artistId,
      Value<int> rowid,
    });

class $$EventArtistsTableTableFilterComposer
    extends Composer<_$AppDatabase, $EventArtistsTableTable> {
  $$EventArtistsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artistId => $composableBuilder(
    column: $table.artistId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EventArtistsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $EventArtistsTableTable> {
  $$EventArtistsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artistId => $composableBuilder(
    column: $table.artistId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EventArtistsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $EventArtistsTableTable> {
  $$EventArtistsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<String> get artistId =>
      $composableBuilder(column: $table.artistId, builder: (column) => column);
}

class $$EventArtistsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EventArtistsTableTable,
          EventArtistsTableData,
          $$EventArtistsTableTableFilterComposer,
          $$EventArtistsTableTableOrderingComposer,
          $$EventArtistsTableTableAnnotationComposer,
          $$EventArtistsTableTableCreateCompanionBuilder,
          $$EventArtistsTableTableUpdateCompanionBuilder,
          (
            EventArtistsTableData,
            BaseReferences<
              _$AppDatabase,
              $EventArtistsTableTable,
              EventArtistsTableData
            >,
          ),
          EventArtistsTableData,
          PrefetchHooks Function()
        > {
  $$EventArtistsTableTableTableManager(
    _$AppDatabase db,
    $EventArtistsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventArtistsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventArtistsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventArtistsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> eventId = const Value.absent(),
                Value<String> artistId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventArtistsTableCompanion(
                eventId: eventId,
                artistId: artistId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String eventId,
                required String artistId,
                Value<int> rowid = const Value.absent(),
              }) => EventArtistsTableCompanion.insert(
                eventId: eventId,
                artistId: artistId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EventArtistsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EventArtistsTableTable,
      EventArtistsTableData,
      $$EventArtistsTableTableFilterComposer,
      $$EventArtistsTableTableOrderingComposer,
      $$EventArtistsTableTableAnnotationComposer,
      $$EventArtistsTableTableCreateCompanionBuilder,
      $$EventArtistsTableTableUpdateCompanionBuilder,
      (
        EventArtistsTableData,
        BaseReferences<
          _$AppDatabase,
          $EventArtistsTableTable,
          EventArtistsTableData
        >,
      ),
      EventArtistsTableData,
      PrefetchHooks Function()
    >;
typedef $$BookmarksTableTableCreateCompanionBuilder =
    BookmarksTableCompanion Function({
      required String eventId,
      required DateTime bookmarkedAt,
      Value<int> rowid,
    });
typedef $$BookmarksTableTableUpdateCompanionBuilder =
    BookmarksTableCompanion Function({
      Value<String> eventId,
      Value<DateTime> bookmarkedAt,
      Value<int> rowid,
    });

class $$BookmarksTableTableFilterComposer
    extends Composer<_$AppDatabase, $BookmarksTableTable> {
  $$BookmarksTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get bookmarkedAt => $composableBuilder(
    column: $table.bookmarkedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BookmarksTableTableOrderingComposer
    extends Composer<_$AppDatabase, $BookmarksTableTable> {
  $$BookmarksTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get bookmarkedAt => $composableBuilder(
    column: $table.bookmarkedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BookmarksTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $BookmarksTableTable> {
  $$BookmarksTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<DateTime> get bookmarkedAt => $composableBuilder(
    column: $table.bookmarkedAt,
    builder: (column) => column,
  );
}

class $$BookmarksTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BookmarksTableTable,
          BookmarksTableData,
          $$BookmarksTableTableFilterComposer,
          $$BookmarksTableTableOrderingComposer,
          $$BookmarksTableTableAnnotationComposer,
          $$BookmarksTableTableCreateCompanionBuilder,
          $$BookmarksTableTableUpdateCompanionBuilder,
          (
            BookmarksTableData,
            BaseReferences<
              _$AppDatabase,
              $BookmarksTableTable,
              BookmarksTableData
            >,
          ),
          BookmarksTableData,
          PrefetchHooks Function()
        > {
  $$BookmarksTableTableTableManager(
    _$AppDatabase db,
    $BookmarksTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookmarksTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookmarksTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookmarksTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> eventId = const Value.absent(),
                Value<DateTime> bookmarkedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BookmarksTableCompanion(
                eventId: eventId,
                bookmarkedAt: bookmarkedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String eventId,
                required DateTime bookmarkedAt,
                Value<int> rowid = const Value.absent(),
              }) => BookmarksTableCompanion.insert(
                eventId: eventId,
                bookmarkedAt: bookmarkedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BookmarksTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BookmarksTableTable,
      BookmarksTableData,
      $$BookmarksTableTableFilterComposer,
      $$BookmarksTableTableOrderingComposer,
      $$BookmarksTableTableAnnotationComposer,
      $$BookmarksTableTableCreateCompanionBuilder,
      $$BookmarksTableTableUpdateCompanionBuilder,
      (
        BookmarksTableData,
        BaseReferences<_$AppDatabase, $BookmarksTableTable, BookmarksTableData>,
      ),
      BookmarksTableData,
      PrefetchHooks Function()
    >;
typedef $$SyncMetadataTableTableCreateCompanionBuilder =
    SyncMetadataTableCompanion Function({
      required String dataType,
      required DateTime lastSyncedAt,
      Value<int> rowid,
    });
typedef $$SyncMetadataTableTableUpdateCompanionBuilder =
    SyncMetadataTableCompanion Function({
      Value<String> dataType,
      Value<DateTime> lastSyncedAt,
      Value<int> rowid,
    });

class $$SyncMetadataTableTableFilterComposer
    extends Composer<_$AppDatabase, $SyncMetadataTableTable> {
  $$SyncMetadataTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get dataType => $composableBuilder(
    column: $table.dataType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncMetadataTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncMetadataTableTable> {
  $$SyncMetadataTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get dataType => $composableBuilder(
    column: $table.dataType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncMetadataTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncMetadataTableTable> {
  $$SyncMetadataTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get dataType =>
      $composableBuilder(column: $table.dataType, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );
}

class $$SyncMetadataTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncMetadataTableTable,
          SyncMetadataTableData,
          $$SyncMetadataTableTableFilterComposer,
          $$SyncMetadataTableTableOrderingComposer,
          $$SyncMetadataTableTableAnnotationComposer,
          $$SyncMetadataTableTableCreateCompanionBuilder,
          $$SyncMetadataTableTableUpdateCompanionBuilder,
          (
            SyncMetadataTableData,
            BaseReferences<
              _$AppDatabase,
              $SyncMetadataTableTable,
              SyncMetadataTableData
            >,
          ),
          SyncMetadataTableData,
          PrefetchHooks Function()
        > {
  $$SyncMetadataTableTableTableManager(
    _$AppDatabase db,
    $SyncMetadataTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncMetadataTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncMetadataTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncMetadataTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> dataType = const Value.absent(),
                Value<DateTime> lastSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncMetadataTableCompanion(
                dataType: dataType,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String dataType,
                required DateTime lastSyncedAt,
                Value<int> rowid = const Value.absent(),
              }) => SyncMetadataTableCompanion.insert(
                dataType: dataType,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncMetadataTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncMetadataTableTable,
      SyncMetadataTableData,
      $$SyncMetadataTableTableFilterComposer,
      $$SyncMetadataTableTableOrderingComposer,
      $$SyncMetadataTableTableAnnotationComposer,
      $$SyncMetadataTableTableCreateCompanionBuilder,
      $$SyncMetadataTableTableUpdateCompanionBuilder,
      (
        SyncMetadataTableData,
        BaseReferences<
          _$AppDatabase,
          $SyncMetadataTableTable,
          SyncMetadataTableData
        >,
      ),
      SyncMetadataTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$EventsTableTableTableManager get eventsTable =>
      $$EventsTableTableTableManager(_db, _db.eventsTable);
  $$VenuesTableTableTableManager get venuesTable =>
      $$VenuesTableTableTableManager(_db, _db.venuesTable);
  $$ArtistsTableTableTableManager get artistsTable =>
      $$ArtistsTableTableTableManager(_db, _db.artistsTable);
  $$EventArtistsTableTableTableManager get eventArtistsTable =>
      $$EventArtistsTableTableTableManager(_db, _db.eventArtistsTable);
  $$BookmarksTableTableTableManager get bookmarksTable =>
      $$BookmarksTableTableTableManager(_db, _db.bookmarksTable);
  $$SyncMetadataTableTableTableManager get syncMetadataTable =>
      $$SyncMetadataTableTableTableManager(_db, _db.syncMetadataTable);
}

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(appDatabase)
final appDatabaseProvider = AppDatabaseProvider._();

final class AppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  AppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appDatabaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return appDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$appDatabaseHash() => r'47be2e3bda76bd13ff016bd0195306cc78bea53f';
