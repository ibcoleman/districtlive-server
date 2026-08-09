import 'package:drift/drift.dart';
import 'package:district_live/core/database/app_database.dart';
import 'package:district_live/core/database/tables.dart';

part 'bookmark_dao.g.dart';

@DriftAccessor(tables: [BookmarksTable, EventsTable])
class BookmarkDao extends DatabaseAccessor<AppDatabase> {
  BookmarkDao(super.db);

  /// Toggle bookmark for an event. Returns true if now bookmarked, false if removed.
  Future<bool> toggle(String eventId) async {
    final existing = await (select(db.bookmarksTable)
          ..where((row) => row.eventId.equals(eventId)))
        .getSingleOrNull();

    if (existing != null) {
      await (delete(db.bookmarksTable)
            ..where((row) => row.eventId.equals(eventId)))
          .go();
      return false;
    } else {
      await into(db.bookmarksTable).insert(
        BookmarksTableCompanion(
          eventId: Value(eventId),
          bookmarkedAt: Value(DateTime.now()),
        ),
      );
      return true;
    }
  }

  /// Watch whether a specific event is bookmarked.
  Stream<bool> watchIsBookmarked(String eventId) {
    return (select(db.bookmarksTable)
          ..where((row) => row.eventId.equals(eventId)))
        .watch()
        .map((rows) => rows.isNotEmpty);
  }

  /// Watch all bookmarked event IDs (for efficient bulk checks).
  Stream<Set<String>> watchBookmarkedIds() {
    return select(db.bookmarksTable).watch().map(
          (rows) => rows.map((r) => r.eventId).toSet(),
        );
  }

  /// Watch bookmarked events joined with event data, sorted by bookmark date (newest first).
  Stream<List<EventsTableData>> watchBookmarkedEvents() {
    return customSelect(
      '''
      SELECT e.*
      FROM events_table e
      INNER JOIN bookmarks_table b ON e.id = b.event_id
      ORDER BY e.start_time ASC
      ''',
      readsFrom: {db.eventsTable, db.bookmarksTable},
    ).watch().map((rows) {
      return rows
          .map((row) => EventsTableData(
                id: row.read<String>('id'),
                title: row.read<String>('title'),
                slug: row.read<String>('slug'),
                description: row.read<String?>('description'),
                startTime: row.read<DateTime>('start_time'),
                endTime: row.read<DateTime?>('end_time'),
                doorsTime: row.read<DateTime?>('doors_time'),
                onSaleDate: row.read<DateTime?>('on_sale_date'),
                venueId: row.read<String?>('venue_id'),
                minPrice: row.read<double?>('min_price'),
                maxPrice: row.read<double?>('max_price'),
                priceTier: row.read<String?>('price_tier'),
                ticketUrl: row.read<String?>('ticket_url'),
                ticketPlatform: row.read<String?>('ticket_platform'),
                soldOut: row.read<bool>('sold_out'),
                imageUrl: row.read<String?>('image_url'),
                ageRestriction: row.read<String>('age_restriction'),
                status: row.read<String>('status'),
              ))
          .toList();
    });
  }
}
