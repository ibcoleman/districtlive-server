import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:district_live/core/theme/app_theme.dart';
import 'package:district_live/features/events/presentation/event_format_utils.dart';

/// A simplified hero card widget for golden testing.
/// Mirrors the _buildHeroCard logic from FeaturedScreen without Riverpod dependencies.
class FeaturedHeroCard extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final String? venueName;
  final String? neighborhood;
  final DateTime startTime;
  final DateTime? doorsTime;
  final String? blurb;
  final String eventId;

  const FeaturedHeroCard({
    super.key,
    required this.title,
    required this.startTime,
    required this.eventId,
    this.imageUrl,
    this.venueName,
    this.neighborhood,
    this.doorsTime,
    this.blurb,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      children: [
        // Hero image with overlay
        Stack(
          children: [
            if (imageUrl != null)
              Container(
                width: double.infinity,
                height: 300,
                color: theme.colorScheme.surfaceContainerHighest,
                child: Center(
                  child: Text(
                    '[Image: $imageUrl]',
                    style: theme.textTheme.bodySmall,
                  ),
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
                  Text(
                    title,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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

        // Blurb (curated only)
        if (blurb != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              blurb!,
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
                  onPressed: () {},
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

void main() {
  group('FeaturedScreen Hero Card Golden Tests', () {
    testWidgets('Featured hero card light mode with curated blurb',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 500);
      addTearDown(() => tester.view.resetPhysicalSize());

      final startTime = DateTime(2025, 3, 20, 20, 0);
      final doorsTime = DateTime(2025, 3, 20, 19, 30);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: FeaturedHeroCard(
              title: 'Live at The Kennedy Center: A Night to Remember',
              startTime: startTime,
              doorsTime: doorsTime,
              venueName: 'The Kennedy Center',
              neighborhood: 'Downtown',
              eventId: 'test-event-1',
              blurb: 'This is a curated featured event that should not be missed. '
                  'An incredible performance featuring world-class musicians.',
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(FeaturedHeroCard),
        matchesGoldenFile('goldens/featured_hero_curated_light.png'),
      );
    });

    testWidgets('Featured hero card dark mode with curated blurb',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 500);
      addTearDown(() => tester.view.resetPhysicalSize());

      final startTime = DateTime(2025, 3, 20, 20, 0);
      final doorsTime = DateTime(2025, 3, 20, 19, 30);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: FeaturedHeroCard(
              title: 'Live at The Kennedy Center: A Night to Remember',
              startTime: startTime,
              doorsTime: doorsTime,
              venueName: 'The Kennedy Center',
              neighborhood: 'Downtown',
              eventId: 'test-event-1',
              blurb: 'This is a curated featured event that should not be missed. '
                  'An incredible performance featuring world-class musicians.',
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(FeaturedHeroCard),
        matchesGoldenFile('goldens/featured_hero_curated_dark.png'),
      );
    });

    testWidgets('Featured hero card light mode without blurb (fallback)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 400);
      addTearDown(() => tester.view.resetPhysicalSize());

      final startTime = DateTime(2025, 3, 22, 19, 0);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: FeaturedHeroCard(
              title: 'Jazz Evening at The 9:30 Club',
              startTime: startTime,
              venueName: 'The 9:30 Club',
              neighborhood: 'U Street Corridor',
              eventId: 'test-event-2',
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(FeaturedHeroCard),
        matchesGoldenFile('goldens/featured_hero_fallback_light.png'),
      );
    });

    testWidgets('Featured hero card with long title', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 450);
      addTearDown(() => tester.view.resetPhysicalSize());

      final startTime = DateTime(2025, 3, 25, 20, 0);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: FeaturedHeroCard(
              title: 'An Evening of Classical Symphonies with the DC Orchestra '
                  'and Special International Guests',
              startTime: startTime,
              venueName: 'The Kennedy Center Concert Hall',
              neighborhood: 'Downtown',
              eventId: 'test-event-3',
              blurb: 'A spectacular evening of classical music.',
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(FeaturedHeroCard),
        matchesGoldenFile('goldens/featured_hero_long_title_light.png'),
      );
    });
  });
}
