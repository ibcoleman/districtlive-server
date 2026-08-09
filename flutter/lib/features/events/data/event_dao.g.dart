// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_dao.dart';

// ignore_for_file: type=lint
mixin _$EventDaoMixin on DatabaseAccessor<AppDatabase> {
  $EventsTableTable get eventsTable => attachedDatabase.eventsTable;
  $ArtistsTableTable get artistsTable => attachedDatabase.artistsTable;
  $EventArtistsTableTable get eventArtistsTable =>
      attachedDatabase.eventArtistsTable;
  EventDaoManager get managers => EventDaoManager(this);
}

class EventDaoManager {
  final _$EventDaoMixin _db;
  EventDaoManager(this._db);
  $$EventsTableTableTableManager get eventsTable =>
      $$EventsTableTableTableManager(_db.attachedDatabase, _db.eventsTable);
  $$ArtistsTableTableTableManager get artistsTable =>
      $$ArtistsTableTableTableManager(_db.attachedDatabase, _db.artistsTable);
  $$EventArtistsTableTableTableManager get eventArtistsTable =>
      $$EventArtistsTableTableTableManager(
        _db.attachedDatabase,
        _db.eventArtistsTable,
      );
}
