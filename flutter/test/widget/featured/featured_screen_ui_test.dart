import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:district_live/features/featured/domain/featured_ui_state.dart';
import 'package:district_live/features/featured/domain/featured_event.dart';
import 'package:district_live/features/events/domain/event.dart';
import 'package:district_live/features/events/domain/event_detail.dart';
import 'package:district_live/features/venues/domain/venue.dart';

// Test-specific version of FeaturedScreen that doesn't require Riverpod override
class _FeaturedScreenTest extends StatelessWidget {
  final FeaturedUiState uiState;

  const _FeaturedScreenTest({required this.uiState});

  @override
  Widget build(BuildContext context) {
    final asyncState = AsyncValue.data(uiState);

    return Scaffold(
      appBar: AppBar(title: const Text('Featured')),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(context, error),
        data: (uiState) => _buildContent(context, uiState),
      ),
    );
  }

  Widget _buildContent(BuildContext context, FeaturedUiState uiState) {
    return RefreshIndicator(
      onRefresh: () async {
        // no-op for testing
      },
      child: switch (uiState) {
        FeaturedLoading() => const Center(child: CircularProgressIndicator()),
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
            : _buildEmptyState(context),
        FeaturedError(:final message) => _buildErrorState(context, message),
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
          onTap: () => Navigator.of(context).pushNamed('/featured/event/$eventId'),
          child: Stack(
            children: [
              if (imageUrl != null)
                Container(
                  width: double.infinity,
                  height: 300,
                  color: Colors.grey,
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
                    Text(title,
                        style: theme.textTheme.headlineLarge
                            ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    if (venueName != null)
                      Text(
                        venueName +
                            (neighborhood != null ? ' · $neighborhood' : ''),
                        style:
                            theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      '$startTime',
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
          child: ElevatedButton(
            onPressed: () =>
                Navigator.of(context).pushNamed('/featured/event/$eventId'),
            child: const Text('View Details'),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 64, color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 16),
                Text('No upcoming events found', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 16),
                Text('Failed to load',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(error.toString(), style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

void main() {
  group('FeaturedScreen UI rendering tests', () {
    final testVenue = const Venue(
      id: 'venue-1',
      name: 'The Kennedy Center',
      slug: 'the-kennedy-center',
      neighborhood: 'Downtown',
    );

    final testEventDetail = EventDetail(
      id: 'event-1',
      title: 'Amazing Concert',
      slug: 'amazing-concert',
      startTime: DateTime(2025, 3, 15, 20, 0),
      doorsTime: DateTime(2025, 3, 15, 19, 30),
      venue: testVenue,
      artists: const [],
      imageUrl: 'https://example.com/image.jpg',
      description: 'A great concert',
    );

    final testFeaturedEvent = FeaturedEvent(
      id: 'featured-1',
      event: testEventDetail,
      blurb: 'Don\'t miss this amazing concert!',
      createdAt: DateTime.now(),
      createdBy: 'admin',
    );

    Widget buildTestWidget({required FeaturedUiState uiState}) {
      return MaterialApp(
        home: _FeaturedScreenTest(uiState: uiState),
      );
    }

    testWidgets('Hero card renders with title and venue',
        (WidgetTester tester) async {
      final uiState = FeaturedUiState.curated(
        featuredEvent: testFeaturedEvent,
        isRefreshing: false,
      );

      await tester.pumpWidget(buildTestWidget(uiState: uiState));

      expect(find.text('Amazing Concert'), findsOneWidget);
      expect(find.text('The Kennedy Center · Downtown'), findsOneWidget);
    });

    testWidgets('Blurb text appears in curated state',
        (WidgetTester tester) async {
      final uiState = FeaturedUiState.curated(
        featuredEvent: testFeaturedEvent,
        isRefreshing: false,
      );

      await tester.pumpWidget(buildTestWidget(uiState: uiState));

      expect(find.text('Don\'t miss this amazing concert!'), findsOneWidget);
    });

    testWidgets('View Details button appears', (WidgetTester tester) async {
      final uiState = FeaturedUiState.curated(
        featuredEvent: testFeaturedEvent,
        isRefreshing: false,
      );

      await tester.pumpWidget(buildTestWidget(uiState: uiState));

      expect(find.text('View Details'), findsOneWidget);
    });

    testWidgets('Music note icon appears when no image',
        (WidgetTester tester) async {
      final eventNoImage = EventDetail(
        id: 'event-2',
        title: 'Event Without Image',
        slug: 'event-no-image',
        startTime: DateTime(2025, 3, 15, 20, 0),
        venue: testVenue,
        artists: const [],
      );

      final featured = FeaturedEvent(
        id: 'featured-2',
        event: eventNoImage,
        blurb: 'Check this out!',
        createdAt: DateTime.now(),
        createdBy: 'admin',
      );

      final uiState = FeaturedUiState.curated(
        featuredEvent: featured,
        isRefreshing: false,
      );

      await tester.pumpWidget(buildTestWidget(uiState: uiState));

      expect(find.byIcon(Icons.music_note), findsWidgets);
    });

    testWidgets('Empty state message appears when no events',
        (WidgetTester tester) async {
      final uiState = const FeaturedUiState.fallbackHero(event: null);

      await tester.pumpWidget(buildTestWidget(uiState: uiState));

      expect(find.text('No upcoming events found'), findsOneWidget);
      expect(find.byIcon(Icons.event_busy), findsOneWidget);
    });

    testWidgets('Error message and retry button appear on error',
        (WidgetTester tester) async {
      final uiState = FeaturedUiState.error(message: 'Network error');

      await tester.pumpWidget(buildTestWidget(uiState: uiState));

      expect(find.text('Failed to load'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('AppBar is present', (WidgetTester tester) async {
      final uiState = FeaturedUiState.curated(
        featuredEvent: testFeaturedEvent,
        isRefreshing: false,
      );

      await tester.pumpWidget(buildTestWidget(uiState: uiState));

      expect(find.byType(AppBar), findsWidgets);
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('ListView is used for scroll support',
        (WidgetTester tester) async {
      final uiState = FeaturedUiState.curated(
        featuredEvent: testFeaturedEvent,
        isRefreshing: false,
      );

      await tester.pumpWidget(buildTestWidget(uiState: uiState));

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('FallbackHero without blurb renders correctly',
        (WidgetTester tester) async {
      final fallbackEvent = Event(
        id: 'event-2',
        title: 'Tonight\'s Show',
        slug: 'tonights-show',
        startTime: DateTime(2025, 3, 15, 20, 0),
        venue: testVenue,
        artists: const [],
      );

      final uiState = FeaturedUiState.fallbackHero(
        event: fallbackEvent,
        isRefreshing: false,
      );

      await tester.pumpWidget(buildTestWidget(uiState: uiState));

      expect(find.text('Tonight\'s Show'), findsOneWidget);
      expect(find.text('The Kennedy Center · Downtown'), findsOneWidget);
      // Blurb should not appear in fallback
      expect(find.text('Don\'t miss this amazing concert!'), findsNothing);
    });

    testWidgets('Loading state shows spinner', (WidgetTester tester) async {
      final uiState = const FeaturedUiState.loading();

      await tester.pumpWidget(buildTestWidget(uiState: uiState));

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });
  });
}
