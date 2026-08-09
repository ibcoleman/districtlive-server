import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:district_live/core/database/app_database.dart';
import 'package:district_live/core/widgets/empty_state.dart';
import 'package:district_live/features/events/presentation/event_card.dart';

class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final database = ref.watch(appDatabaseProvider);
    final bookmarkedEventsStream = database.bookmarkDao.watchBookmarkedEvents();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved'),
        elevation: 0,
      ),
      body: StreamBuilder<List<EventsTableData>>(
        stream: bookmarkedEventsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final events = snapshot.data ?? [];

          if (events.isEmpty) {
            return const EmptyState(
              message: 'No saved events yet.\nTap the bookmark in any event detail to save it.',
              icon: Icons.bookmark_border,
            );
          }

          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return _SavedEventCard(event: event);
            },
          );
        },
      ),
    );
  }
}

class _SavedEventCard extends ConsumerWidget {
  final EventsTableData event;

  const _SavedEventCard({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final database = ref.watch(appDatabaseProvider);

    return FutureBuilder<VenuesTableData?>(
      future: event.venueId != null
          ? database.venueDao.getVenueById(event.venueId!)
          : Future.value(null),
      builder: (context, snapshot) {
        final venue = snapshot.data;
        return EventCard(
          event: event,
          startTime: event.startTime,
          doorsTime: event.doorsTime,
          title: event.title,
          minPrice: event.minPrice,
          maxPrice: event.maxPrice,
          priceTier: event.priceTier,
          imageUrl: event.imageUrl,
          ageRestriction: event.ageRestriction,
          venueName: venue?.name,
          neighborhood: venue?.neighborhood,
          onTap: () => context.go('/saved/event/${event.id}'),
        );
      },
    );
  }
}
