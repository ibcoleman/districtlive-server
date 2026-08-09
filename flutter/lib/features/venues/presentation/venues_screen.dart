import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:district_live/core/database/app_database.dart';
import 'package:district_live/core/widgets/error_state.dart';
import 'package:district_live/core/widgets/empty_state.dart';
import 'package:district_live/core/widgets/loading_state.dart';
import 'package:district_live/features/venues/data/venues_notifier.dart';
import 'package:district_live/features/venues/presentation/venue_card.dart';

class VenuesScreen extends ConsumerWidget {
  const VenuesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ensure VenuesNotifier is active so background refresh triggers on first install
    ref.watch(venuesProvider);

    // Watch the venues stream (no neighborhood filter)
    final venuesAsync = ref.watch(_watchVenuesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Venues'),
        elevation: 0,
      ),
      body: venuesAsync.when(
        loading: () => const LoadingState(),
        error: (error, stack) => ErrorState(
          message: error.toString(),
          onRetry: () => ref.read(venuesProvider.notifier).refresh(),
        ),
        data: (venues) => _buildVenuesList(context, ref, venues),
      ),
    );
  }

  Widget _buildVenuesList(BuildContext context, WidgetRef ref, List<VenuesTableData> venues) {
    if (venues.isEmpty) {
      return const EmptyState(message: 'No venues found');
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(venuesProvider.notifier).refresh();
      },
      child: ListView.builder(
        itemCount: venues.length,
        itemBuilder: (context, index) {
          final venue = venues[index];
          return VenueCard(
            name: venue.name,
            neighborhood: venue.neighborhood,
            upcomingEventCount: venue.upcomingEventCount,
            onTap: () {
              context.go('/venues/${venue.id}/events?name=${Uri.encodeComponent(venue.name)}&slug=${Uri.encodeComponent(venue.slug)}');
            },
          );
        },
      ),
    );
  }

}

/// Watch all venues
final _watchVenuesProvider = StreamProvider<List<VenuesTableData>>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return database.venueDao.watchVenues();
});
