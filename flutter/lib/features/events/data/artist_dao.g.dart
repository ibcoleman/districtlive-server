// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'artist_dao.dart';

// ignore_for_file: type=lint
mixin _$ArtistDaoMixin on DatabaseAccessor<AppDatabase> {
  $ArtistsTableTable get artistsTable => attachedDatabase.artistsTable;
  ArtistDaoManager get managers => ArtistDaoManager(this);
}

class ArtistDaoManager {
  final _$ArtistDaoMixin _db;
  ArtistDaoManager(this._db);
  $$ArtistsTableTableTableManager get artistsTable =>
      $$ArtistsTableTableTableManager(_db.attachedDatabase, _db.artistsTable);
}
