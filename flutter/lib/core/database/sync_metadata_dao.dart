import 'package:drift/drift.dart';
import 'package:district_live/core/database/app_database.dart';
import 'package:district_live/core/database/tables.dart';

part 'sync_metadata_dao.g.dart';

@DriftAccessor(tables: [SyncMetadataTable])
class SyncMetadataDao extends DatabaseAccessor<AppDatabase> {
  SyncMetadataDao(super.db);

  /// Get the last sync time for a data type, returns null if not found
  Future<DateTime?> getLastSyncedAt(String dataType) async {
    final result = await (select(db.syncMetadataTable)
          ..where((row) => row.dataType.equals(dataType)))
        .getSingleOrNull();
    return result?.lastSyncedAt;
  }

  /// Update (upsert) the last sync time for a data type
  Future<void> updateLastSyncedAt(String dataType, DateTime syncedAt) async {
    await into(db.syncMetadataTable).insert(
      SyncMetadataTableCompanion(
        dataType: Value(dataType),
        lastSyncedAt: Value(syncedAt),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  /// Check if data is stale
  /// Returns true if no metadata exists or last sync is older than threshold
  Future<bool> isStale(
    String dataType, {
    Duration threshold = const Duration(minutes: 15),
  }) async {
    final lastSyncedAt = await getLastSyncedAt(dataType);

    if (lastSyncedAt == null) {
      return true; // No metadata exists, consider stale
    }

    final now = DateTime.now();
    final timeSinceLastSync = now.difference(lastSyncedAt);

    return timeSinceLastSync > threshold;
  }
}
