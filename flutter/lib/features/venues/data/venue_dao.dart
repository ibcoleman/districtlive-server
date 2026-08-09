import 'package:drift/drift.dart';
import 'package:district_live/core/database/app_database.dart';
import 'package:district_live/core/database/tables.dart';

part 'venue_dao.g.dart';

@DriftAccessor(tables: [VenuesTable])
class VenueDao extends DatabaseAccessor<AppDatabase> {
  VenueDao(super.db);

  /// Watch venues with optional neighborhood filter
  Stream<List<VenuesTableData>> watchVenues({String? neighborhood}) {
    return (select(db.venuesTable)
          ..where((row) {
            if (neighborhood != null) {
              return row.neighborhood.equals(neighborhood);
            }
            return const Constant(true);
          })
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .watch();
  }

  /// Get a single venue by ID
  Future<VenuesTableData?> getVenueById(String id) {
    return (select(db.venuesTable)..where((row) => row.id.equals(id)))
        .getSingleOrNull();
  }

  /// Upsert (insert or update) venues in batch
  Future<void> upsertVenues(List<VenuesTableCompanion> venues) async {
    await batch((batch) {
      batch.insertAll(
        db.venuesTable,
        venues,
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  /// Watch distinct neighborhoods (non-null values only)
  Stream<List<String>> watchDistinctNeighborhoods() {
    return customSelect(
      'SELECT DISTINCT neighborhood FROM venues_table WHERE neighborhood IS NOT NULL ORDER BY neighborhood ASC',
      readsFrom: {db.venuesTable},
    ).watch().map((rows) {
      return rows
          .map((row) => row.read<String>('neighborhood'))
          .toList();
    });
  }
}
