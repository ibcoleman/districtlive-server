import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:district_live/core/database/app_database.dart';

void main() {
  group('Staleness check integration tests', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('Fresh database with no metadata is stale', () async {
      final isStale = await db.syncMetadataDao.isStale('events');
      expect(isStale, true);
    });

    test('Update sync time to now makes data not stale', () async {
      final now = DateTime.now();
      await db.syncMetadataDao.updateLastSyncedAt('events', now);

      final isStale = await db.syncMetadataDao.isStale('events');
      expect(isStale, false);
    });

    test('Update sync time to 16 minutes ago makes data stale', () async {
      final sixteenMinutesAgo =
          DateTime.now().subtract(const Duration(minutes: 16));
      await db.syncMetadataDao.updateLastSyncedAt('events', sixteenMinutesAgo);

      final isStale = await db.syncMetadataDao.isStale('events');
      expect(isStale, true);
    });

    test('Update sync time to 14 minutes ago keeps data not stale', () async {
      final fourteenMinutesAgo =
          DateTime.now().subtract(const Duration(minutes: 14));
      await db.syncMetadataDao.updateLastSyncedAt('events', fourteenMinutesAgo);

      final isStale = await db.syncMetadataDao.isStale('events');
      expect(isStale, false);
    });

    test('Different data types are tracked independently', () async {
      final now = DateTime.now();
      final sixteenMinutesAgo =
          DateTime.now().subtract(const Duration(minutes: 16));

      // Events: recent (not stale)
      await db.syncMetadataDao.updateLastSyncedAt('events', now);

      // Venues: old (stale)
      await db.syncMetadataDao.updateLastSyncedAt('venues', sixteenMinutesAgo);

      // Artists: not tracked yet (stale)

      final eventsStale = await db.syncMetadataDao.isStale('events');
      final venuesStale = await db.syncMetadataDao.isStale('venues');
      final artistsStale = await db.syncMetadataDao.isStale('artists');

      expect(eventsStale, false);
      expect(venuesStale, true);
      expect(artistsStale, true);
    });

    test('Full flow: fresh → recent → stale → recent', () async {
      // Start fresh (stale)
      var isStale = await db.syncMetadataDao.isStale('events');
      expect(isStale, true);

      // Sync now (not stale)
      var now = DateTime.now();
      await db.syncMetadataDao.updateLastSyncedAt('events', now);
      isStale = await db.syncMetadataDao.isStale('events');
      expect(isStale, false);

      // Move time to 16 minutes ago (stale)
      var old = DateTime.now().subtract(const Duration(minutes: 16));
      await db.syncMetadataDao.updateLastSyncedAt('events', old);
      isStale = await db.syncMetadataDao.isStale('events');
      expect(isStale, true);

      // Sync again (not stale)
      now = DateTime.now();
      await db.syncMetadataDao.updateLastSyncedAt('events', now);
      isStale = await db.syncMetadataDao.isStale('events');
      expect(isStale, false);
    });
  });
}
