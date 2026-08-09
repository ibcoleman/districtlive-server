// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookmark_dao.dart';

// ignore_for_file: type=lint
mixin _$BookmarkDaoMixin on DatabaseAccessor<AppDatabase> {
  $BookmarksTableTable get bookmarksTable => attachedDatabase.bookmarksTable;
  $EventsTableTable get eventsTable => attachedDatabase.eventsTable;
  BookmarkDaoManager get managers => BookmarkDaoManager(this);
}

class BookmarkDaoManager {
  final _$BookmarkDaoMixin _db;
  BookmarkDaoManager(this._db);
  $$BookmarksTableTableTableManager get bookmarksTable =>
      $$BookmarksTableTableTableManager(
        _db.attachedDatabase,
        _db.bookmarksTable,
      );
  $$EventsTableTableTableManager get eventsTable =>
      $$EventsTableTableTableManager(_db.attachedDatabase, _db.eventsTable);
}
