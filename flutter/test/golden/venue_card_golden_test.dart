import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:district_live/core/theme/app_theme.dart';
import 'package:district_live/features/venues/presentation/venue_card.dart';

void main() {
  group('VenueCard Golden Tests', () {
    testWidgets('VenueCard light mode with neighborhood and event count',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 100);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Center(
              child: VenueCard(
                name: 'The Kennedy Center',
                neighborhood: 'Downtown',
                upcomingEventCount: 12,
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(VenueCard),
        matchesGoldenFile('goldens/venue_card_light.png'),
      );
    });

    testWidgets('VenueCard dark mode with neighborhood and event count',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 100);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: Center(
              child: VenueCard(
                name: 'The Kennedy Center',
                neighborhood: 'Downtown',
                upcomingEventCount: 12,
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(VenueCard),
        matchesGoldenFile('goldens/venue_card_dark.png'),
      );
    });

    testWidgets('VenueCard light mode without neighborhood',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 80);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Center(
              child: VenueCard(
                name: 'Fillmore Silver Spring',
                upcomingEventCount: 8,
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(VenueCard),
        matchesGoldenFile('goldens/venue_card_no_neighborhood_light.png'),
      );
    });

    testWidgets('VenueCard with high event count', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 100);
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Center(
              child: VenueCard(
                name: 'The 9:30 Club',
                neighborhood: 'U Street Corridor',
                upcomingEventCount: 24,
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(VenueCard),
        matchesGoldenFile('goldens/venue_card_high_count_light.png'),
      );
    });
  });
}
