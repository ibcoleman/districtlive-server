import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:district_live/core/database/app_database.dart';

void main() {
  group('SyncMetadataDao', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('getLastSyncedAt returns null when no metadata exists', () async {
      final result = await db.syncMetadataDao.getLastSyncedAt('events');
      expect(result, isNull);
    });

    test('updateLastSyncedAt inserts new metadata', () async {
      final now = DateTime.now();
      await db.syncMetadataDao.updateLastSyncedAt('events', now);

      final result = await db.syncMetadataDao.getLastSyncedAt('events');
      expect(result, isNotNull);
      expect(
        result?.difference(now).inSeconds,
        lessThan(1),
      );
    });

    test('updateLastSyncedAt updates existing metadata', () async {
      final time1 = DateTime(2026, 1, 1);
      await db.syncMetadataDao.updateLastSyncedAt('events', time1);

      final time2 = DateTime(2026, 3, 1);
      await db.syncMetadataDao.updateLastSyncedAt('events', time2);

      final result = await db.syncMetadataDao.getLastSyncedAt('events');
      expect(result?.year, 2026);
      expect(result?.month, 3);
      expect(result?.day, 1);
    });

    test('isStale returns true for fresh database', () async {
      final result = await db.syncMetadataDao.isStale('events');
      expect(result, true);
    });

    test('isStale returns false after recent sync', () async {
      final now = DateTime.now();
      await db.syncMetadataDao.updateLastSyncedAt('events', now);

      final result = await db.syncMetadataDao.isStale('events');
      expect(result, false);
    });

    test('isStale returns true after sync older than threshold', () async {
      final old = DateTime.now().subtract(const Duration(minutes: 20));
      await db.syncMetadataDao.updateLastSyncedAt('events', old);

      final result = await db.syncMetadataDao.isStale('events');
      expect(result, true);
    });

    test('isStale respects custom threshold', () async {
      final sixMinutesAgo =
          DateTime.now().subtract(const Duration(minutes: 6));
      await db.syncMetadataDao.updateLastSyncedAt('events', sixMinutesAgo);

      // With default 15-minute threshold, should not be stale
      var result = await db.syncMetadataDao.isStale('events');
      expect(result, false);

      // With custom 5-minute threshold, should be stale
      result = await db.syncMetadataDao.isStale(
        'events',
        threshold: const Duration(minutes: 5),
      );
      expect(result, true);
    });

    test('isStale tracks different data types independently', () async {
      final now = DateTime.now();
      final old = DateTime.now().subtract(const Duration(minutes: 20));

      await db.syncMetadataDao.updateLastSyncedAt('events', now);
      await db.syncMetadataDao.updateLastSyncedAt('venues', old);

      final eventsStale = await db.syncMetadataDao.isStale('events');
      final venuesStale = await db.syncMetadataDao.isStale('venues');

      expect(eventsStale, false);
      expect(venuesStale, true);
    });

    test('getLastSyncedAt returns different times for different data types',
        () async {
      final time1 = DateTime(2026, 1, 1, 10, 0);
      final time2 = DateTime(2026, 2, 1, 14, 30);

      await db.syncMetadataDao.updateLastSyncedAt('events', time1);
      await db.syncMetadataDao.updateLastSyncedAt('venues', time2);

      final eventTime = await db.syncMetadataDao.getLastSyncedAt('events');
      final venueTime = await db.syncMetadataDao.getLastSyncedAt('venues');

      expect(eventTime?.month, 1);
      expect(venueTime?.month, 2);
    });
  });
}
