import 'package:drift/drift.dart';

class EventsTable extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get slug => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
  DateTimeColumn get doorsTime => dateTime().nullable()();
  DateTimeColumn get onSaleDate => dateTime().nullable()();
  TextColumn get venueId => text().nullable()();
  RealColumn get minPrice => real().nullable()();
  RealColumn get maxPrice => real().nullable()();
  TextColumn get priceTier => text().nullable()();
  TextColumn get ticketUrl => text().nullable()();
  TextColumn get ticketPlatform => text().nullable()();
  BoolColumn get soldOut => boolean().withDefault(const Constant(false))();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get ageRestriction =>
      text().withDefault(const Constant('ALL_AGES'))();
  TextColumn get status => text().withDefault(const Constant('ACTIVE'))();
  DateTimeColumn get createdAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class VenuesTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get slug => text()();
  TextColumn get neighborhood => text().nullable()();
  TextColumn get websiteUrl => text().nullable()();
  IntColumn get upcomingEventCount =>
      integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class ArtistsTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get slug => text()();
  TextColumn get genres => text().withDefault(const Constant(''))();
  BoolColumn get isLocal => boolean().withDefault(const Constant(false))();
  TextColumn get spotifyUrl => text().nullable()();
  TextColumn get bandcampUrl => text().nullable()();
  TextColumn get instagramUrl => text().nullable()();
  TextColumn get canonicalName => text().nullable()();
  TextColumn get imageUrl => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class EventArtistsTable extends Table {
  TextColumn get eventId => text()();
  TextColumn get artistId => text()();

  @override
  Set<Column> get primaryKey => {eventId, artistId};
}

class BookmarksTable extends Table {
  TextColumn get eventId => text()();
  DateTimeColumn get bookmarkedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {eventId};
}

class SyncMetadataTable extends Table {
  TextColumn get dataType => text()();
  DateTimeColumn get lastSyncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {dataType};
}
