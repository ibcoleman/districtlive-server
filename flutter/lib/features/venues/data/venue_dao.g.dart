// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'venue_dao.dart';

// ignore_for_file: type=lint
mixin _$VenueDaoMixin on DatabaseAccessor<AppDatabase> {
  $VenuesTableTable get venuesTable => attachedDatabase.venuesTable;
  VenueDaoManager get managers => VenueDaoManager(this);
}

class VenueDaoManager {
  final _$VenueDaoMixin _db;
  VenueDaoManager(this._db);
  $$VenuesTableTableTableManager get venuesTable =>
      $$VenuesTableTableTableManager(_db.attachedDatabase, _db.venuesTable);
}
