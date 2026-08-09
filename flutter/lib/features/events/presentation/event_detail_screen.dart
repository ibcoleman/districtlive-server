import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:district_live/core/widgets/error_state.dart';
import 'package:district_live/core/widgets/loading_state.dart';
import 'package:district_live/features/events/data/event_detail_notifier.dart';
import 'package:district_live/features/events/domain/event_detail.dart';
import 'package:district_live/features/events/domain/event.dart';
import 'package:district_live/features/events/presentation/event_format_utils.dart';
import 'package:district_live/features/bookmarks/presentation/bookmark_star.dart';
import 'package:district_live/features/events/presentation/share_utils.dart';

class EventDetailScreen extends ConsumerWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDetail = ref.watch(eventDetailProvider(eventId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
        actions: [
          BookmarkStar(eventId: eventId),
        ],
      ),
      body: asyncDetail.when(
        loading: () => const LoadingState(),
        error: (error, stack) => ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(eventDetailProvider(eventId)),
        ),
        data: (detail) => _buildEventDetail(context, ref, detail),
      ),
    );
  }

  Widget _buildEventDetail(
      BuildContext context, WidgetRef ref, EventDetail detail) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Image
          if (detail.imageUrl != null)
            CachedNetworkImage(
              imageUrl: detail.imageUrl!,
              width: double.infinity,
              height: 250,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => const SizedBox.shrink(),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2. Title
                Text(detail.title, style: theme.textTheme.headlineMedium),
                const SizedBox(height: 8),

                // 3. Venue + Neighborhood
                if (detail.venue != null)
                  Text(
                    formatVenueWithNeighborhood(
                        detail.venue!.name, detail.venue?.neighborhood),
                    style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),

                const SizedBox(height: 8),

                // 4. Date/Time
                Text(
                  formatEventDateTime(detail.startTime, detail.doorsTime),
                  style: theme.textTheme.bodyMedium,
                ),

                const SizedBox(height: 8),

                // 5. Artists
                if (detail.artists.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      detail.artists.map((a) => a.name).join(', '),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),

                // 6. Price
                Builder(builder: (context) {
                  final priceText = formatPrice(
                      detail.minPrice, detail.maxPrice, detail.priceTier);
                  if (priceText.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(priceText, style: theme.textTheme.bodyMedium),
                  );
                }),

                // 7. Age Restriction
                Builder(builder: (context) {
                  final ageText = formatAge(detail.ageRestriction);
                  if (ageText.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(ageText, style: theme.textTheme.bodyMedium),
                  );
                }),

                const SizedBox(height: 16),

                // 8. Action buttons
                Row(
                  children: [
                    // Get Tickets - hidden when ticketUrl is null (AC3.4)
                    if (detail.ticketUrl != null)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              launchUrl(Uri.parse(detail.ticketUrl!)),
                          child: const Text('Get Tickets'),
                        ),
                      ),
                    if (detail.ticketUrl != null) const SizedBox(width: 8),
                    // Share button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // Build share text from Event (convert EventDetail to Event for share)
                          final event = Event(
                            id: detail.id,
                            title: detail.title,
                            slug: detail.slug,
                            startTime: detail.startTime,
                            doorsTime: detail.doorsTime,
                            venue: detail.venue,
                            artists: detail.artists,
                            minPrice: detail.minPrice,
                            maxPrice: detail.maxPrice,
                            priceTier: detail.priceTier,
                            ticketUrl: detail.ticketUrl,
                            soldOut: detail.soldOut,
                            imageUrl: detail.imageUrl,
                            ageRestriction: detail.ageRestriction,
                            status: detail.status,
                            description: detail.description,
                          );
                          SharePlus.instance.share(ShareParams(
                              text: buildShareText(event),
                              subject: detail.title));
                        },
                        child: const Text('Share'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 9. Description
                if (detail.description != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(detail.description!,
                        style: theme.textTheme.bodyMedium),
                  ),

                // 10. Related Events (up to 5, at same venue)
                if (detail.relatedEvents.isNotEmpty) ...[
                  Text(
                    'More at ${detail.venue?.name ?? "this venue"}',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...detail.relatedEvents
                      .take(5)
                      .map((relatedEvent) =>
                          _buildRelatedEventTile(context, relatedEvent)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedEventTile(BuildContext context, Event event) {
    return ListTile(
      title: Text(event.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle:
          Text(formatEventDateTime(event.startTime, event.doorsTime)),
      leading: event.imageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: CachedNetworkImage(
                imageUrl: event.imageUrl!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              ),
            )
          : null,
      onTap: () {
        // Navigate to event detail for related event
        context.push('/events/${event.id}');
      },
    );
  }
}
