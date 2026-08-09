import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:district_live/features/bookmarks/data/bookmark_dao.dart';
import 'package:district_live/features/events/data/event_dao.dart';
import 'package:district_live/features/events/data/artist_dao.dart';
import 'package:district_live/features/venues/data/venue_dao.dart';
import 'package:district_live/core/database/sync_metadata_dao.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    EventsTable,
    VenuesTable,
    ArtistsTable,
    EventArtistsTable,
    BookmarksTable,
    SyncMetadataTable,
  ],
  daos: [
    EventDao,
    ArtistDao,
    VenueDao,
    BookmarkDao,
    SyncMetadataDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // Destructive migration: drop everything and recreate.
          // Fine during development — add proper migrations before production.
          for (final table in allTables) {
            await customStatement('DROP TABLE IF EXISTS ${table.actualTableName}');
          }
          await m.createAll();
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'district_live');
  }
}

@riverpod
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  // Purge past events once when the database provider is first created.
  // This keeps the cache lean without relying on app restarts.
  final now = DateTime.now();
  final startOfToday = DateTime.utc(now.year, now.month, now.day);
  db.eventDao.deletePastEvents(startOfToday);
  ref.onDispose(() => db.close());
  return db;
}
