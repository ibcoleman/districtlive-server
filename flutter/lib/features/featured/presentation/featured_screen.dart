import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:district_live/core/widgets/error_state.dart';
import 'package:district_live/core/widgets/empty_state.dart';
import 'package:district_live/core/widgets/loading_state.dart';
import 'package:district_live/features/featured/data/featured_notifier.dart';
import 'package:district_live/features/featured/domain/featured_ui_state.dart';
import 'package:district_live/features/events/presentation/event_format_utils.dart';

class FeaturedScreen extends ConsumerWidget {
  const FeaturedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(featuredProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Featured')),
      body: asyncState.when(
        loading: () => const LoadingState(),
        error: (error, stack) => ErrorState(
          message: error.toString(),
          onRetry: () => ref.read(featuredProvider.notifier).refresh(),
        ),
        data: (uiState) => _buildContent(context, ref, uiState),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, FeaturedUiState uiState) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(featuredProvider.notifier).refresh();
      },
      child: switch (uiState) {
        FeaturedLoading() => const LoadingState(),
        FeaturedCurated(:final featuredEvent, :final isRefreshing) =>
          _buildHeroCard(
            context,
            title: featuredEvent.event.title,
            imageUrl: featuredEvent.event.imageUrl,
            venueName: featuredEvent.event.venue?.name,
            neighborhood: featuredEvent.event.venue?.neighborhood,
            startTime: featuredEvent.event.startTime,
            doorsTime: featuredEvent.event.doorsTime,
            blurb: featuredEvent.blurb,
            ticketUrl: featuredEvent.event.ticketUrl,
            eventId: featuredEvent.event.id,
            isRefreshing: isRefreshing,
          ),
        FeaturedFallbackHero(:final event, :final isRefreshing) =>
          event != null
            ? _buildHeroCard(
                context,
                title: event.title,
                imageUrl: event.imageUrl,
                venueName: event.venue?.name,
                neighborhood: event.venue?.neighborhood,
                startTime: event.startTime,
                doorsTime: event.doorsTime,
                blurb: null,
                ticketUrl: event.ticketUrl,
                eventId: event.id,
                isRefreshing: isRefreshing,
              )
            : EmptyState(
                message: 'No upcoming events found',
                icon: Icons.event_busy,
              ),
        FeaturedError(:final message) => ErrorState(
          message: message,
          onRetry: () => ref.read(featuredProvider.notifier).refresh(),
        ),
      },
    );
  }

  Widget _buildHeroCard(
    BuildContext context, {
    required String title,
    String? imageUrl,
    String? venueName,
    String? neighborhood,
    required DateTime startTime,
    DateTime? doorsTime,
    String? blurb,
    String? ticketUrl,
    required String eventId,
    bool isRefreshing = false,
  }) {
    final theme = Theme.of(context);

    return ListView(
      children: [
        // Hero image with overlay
        GestureDetector(
          onTap: () => context.go('/featured/event/$eventId'),
          child: Stack(
            children: [
              if (imageUrl != null)
                CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: double.infinity,
                  height: 300,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Container(
                    height: 300,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Center(child: Icon(Icons.music_note, size: 64)),
                  ),
                )
              else
                Container(
                  height: 300,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Center(child: Icon(Icons.music_note, size: 64)),
                ),
              // Gradient overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                    ),
                  ),
                ),
              ),
              // Title and venue overlay text
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.headlineLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      formatVenueWithNeighborhood(venueName, neighborhood),
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatEventDateTime(startTime, doorsTime),
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Blurb (curated only)
        if (blurb != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              blurb,
              style: theme.textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic),
            ),
          ),

        // Action buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context.go('/featured/event/$eventId'),
                  child: const Text('View Details'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

}
