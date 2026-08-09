import 'package:drift/drift.dart';
import 'package:district_live/core/database/app_database.dart';
import 'package:district_live/core/database/tables.dart';

part 'artist_dao.g.dart';

@DriftAccessor(tables: [ArtistsTable])
class ArtistDao extends DatabaseAccessor<AppDatabase> {
  ArtistDao(super.db);

  /// Upsert (insert or update) artists in batch
  Future<void> upsertArtists(List<ArtistsTableCompanion> artists) async {
    await batch((batch) {
      batch.insertAll(
        db.artistsTable,
        artists,
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  /// Get a single artist by ID
  Future<ArtistsTableData?> getArtistById(String id) {
    return (select(db.artistsTable)..where((row) => row.id.equals(id)))
        .getSingleOrNull();
  }

  /// Watch all artists
  Stream<List<ArtistsTableData>> watchArtists() {
    return (select(db.artistsTable)
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .watch();
  }
}
