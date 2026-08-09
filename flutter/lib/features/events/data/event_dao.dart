import 'package:drift/drift.dart';
import 'package:district_live/core/database/app_database.dart';
import 'package:district_live/core/database/tables.dart';

part 'event_dao.g.dart';

@DriftAccessor(tables: [EventsTable, ArtistsTable, EventArtistsTable])
class EventDao extends DatabaseAccessor<AppDatabase> {
  EventDao(super.db);

  /// Watch events with optional filters and pagination.
  /// [sort] accepts server-style sort strings like 'createdAt,desc'.
  Stream<List<EventsTableData>> watchEvents({
    String? venueId,
    String? genre,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? sort,
    int limit = 20,
    int offset = 0,
  }) {
    // If genre filter is needed, use custom SQL
    if (genre != null) {
      return _watchEventsWithFilters(
        venueId: venueId,
        genre: genre,
        dateFrom: dateFrom,
        dateTo: dateTo,
        sort: sort,
        limit: limit,
        offset: offset,
      );
    }

    // Parse sort parameter
    final orderBy = _buildDriftOrderBy(sort);

    // Build the query with filters
    return (select(db.eventsTable)
          ..where((row) {
            Expression<bool> expr = const Constant(true);

            if (venueId != null) {
              expr = expr & row.venueId.equals(venueId);
            }

            if (dateFrom != null) {
              expr = expr & row.startTime.isBiggerOrEqual(Variable<DateTime>(dateFrom));
            }

            if (dateTo != null) {
              expr = expr & row.startTime.isSmallerOrEqual(Variable<DateTime>(dateTo));
            }

            return expr;
          })
          ..orderBy(orderBy)
          ..limit(limit, offset: offset))
        .watch();
  }

  /// Convert server-style sort string to Drift OrderingTerms.
  List<OrderingTerm Function($EventsTableTable)> _buildDriftOrderBy(String? sort) {
    if (sort != null && sort.contains('createdAt')) {
      final desc = sort.contains('desc');
      return [(t) => OrderingTerm(
        expression: t.createdAt,
        mode: desc ? OrderingMode.desc : OrderingMode.asc,
      )];
    }
    return [(t) => OrderingTerm(expression: t.startTime)];
  }

  /// Helper to watch events with genre filter via custom SQL
  Stream<List<EventsTableData>> _watchEventsWithFilters({
    String? venueId,
    String? genre,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? sort,
    required int limit,
    required int offset,
  }) {
    return customSelect(
      _buildEventQueryWithFilters(
        venueId: venueId,
        genre: genre,
        dateFrom: dateFrom,
        dateTo: dateTo,
        sort: sort,
        limit: limit,
        offset: offset,
      ),
      readsFrom: {db.eventsTable, db.artistsTable, db.eventArtistsTable},
    ).watch().map(
      (rows) {
        // Convert raw rows back to EventsTableData
        final eventMap = <String, EventsTableData>{};
        for (final row in rows) {
          final id = row.read<String>('id');
          if (!eventMap.containsKey(id)) {
            eventMap[id] = EventsTableData(
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
            );
          }
        }
        return eventMap.values.toList();
      },
    );
  }

  /// Build SQL query for events with genre filter
  String _buildEventQueryWithFilters({
    String? venueId,
    String? genre,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? sort,
    required int limit,
    required int offset,
  }) {
    final sb = StringBuffer();
    sb.write('''
      SELECT DISTINCT e.*
      FROM events_table e
      LEFT JOIN event_artists_table ea ON e.id = ea.event_id
      LEFT JOIN artists_table a ON ea.artist_id = a.id
      WHERE 1=1
    ''');

    if (venueId != null) {
      sb.write(" AND e.venue_id = '${venueId.replaceAll("'", "''")}'");
    }

    if (dateFrom != null) {
      sb.write(" AND e.start_time >= '${dateFrom.toIso8601String()}'");
    }

    if (dateTo != null) {
      sb.write(" AND e.start_time <= '${dateTo.toIso8601String()}'");
    }

    if (genre != null) {
      // Check if genre is in the pipe-separated genres string
      // Escape single quotes to prevent SQL injection
      final escapedGenre = genre.replaceAll("'", "''");
      sb.write(" AND a.genres LIKE '%$escapedGenre%'");
    }

    if (sort != null && sort.contains('createdAt')) {
      final direction = sort.contains('desc') ? 'DESC' : 'ASC';
      sb.write(' ORDER BY e.created_at $direction');
    } else {
      sb.write(' ORDER BY e.start_time ASC');
    }
    sb.write(' LIMIT $limit OFFSET $offset');
    return sb.toString();
  }

  /// Delete events whose startTime is before the given cutoff.
  /// Called on app startup to keep the cache from showing past events.
  Future<int> deletePastEvents(DateTime before) {
    return (delete(db.eventsTable)
          ..where((row) => row.startTime.isSmallerThan(Variable<DateTime>(before))))
        .go();
  }

  /// Get a single event by ID
  Future<EventsTableData?> getEventById(String id) {
    return (select(db.eventsTable)..where((row) => row.id.equals(id)))
        .getSingleOrNull();
  }

  /// Upsert (insert or update) events in batch
  Future<void> upsertEvents(List<EventsTableCompanion> events) async {
    await batch((batch) {
      batch.insertAll(
        db.eventsTable,
        events,
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  /// Upsert event-artist associations for a given event
  /// Deletes existing associations and inserts new ones atomically
  Future<void> upsertEventArtists(String eventId, List<String> artistIds) async {
    await transaction(() async {
      // Delete existing associations for this event
      await (delete(db.eventArtistsTable)
            ..where((row) => row.eventId.equals(eventId)))
          .go();

      // Insert new associations
      if (artistIds.isNotEmpty) {
        final companions = artistIds
            .map((artistId) => EventArtistsTableCompanion(
                  eventId: Value(eventId),
                  artistId: Value(artistId),
                ))
            .toList();

        await batch((batch) {
          batch.insertAll(db.eventArtistsTable, companions);
        });
      }
    });
  }

  /// Watch distinct genres from all artists, returned as a List of Strings
  Stream<List<String>> watchDistinctGenres() {
    return customSelect(
      'SELECT DISTINCT genres FROM artists_table WHERE genres != ""',
      readsFrom: {db.artistsTable},
    ).watch().map((rows) {
      final genreSet = <String>{};
      for (final row in rows) {
        final genresStr = row.read<String>('genres');
        // Split by ||| and add all non-empty genres
        final genres = genresStr
            .split('|||')
            .map((g) => g.trim())
            .where((g) => g.isNotEmpty);
        genreSet.addAll(genres);
      }
      return genreSet.toList()..sort();
    });
  }

}
