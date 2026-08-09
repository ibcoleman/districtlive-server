import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:district_live/core/theme/app_theme.dart';
import 'package:district_live/features/events/presentation/event_card.dart';

void main() {
  group('EventCard Golden Tests', () {
    testWidgets('EventCard light mode with price and age restriction',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(500, 250);
      addTearDown(() => tester.view.resetPhysicalSize());

      final startTime = DateTime(2025, 3, 15, 20, 0);
      final doorsTime = DateTime(2025, 3, 15, 19, 30);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: EventCard(
                event: 'test-event',
                startTime: startTime,
                doorsTime: doorsTime,
                title: 'Amazing Concert Experience',
                minPrice: 25.0,
                maxPrice: 50.0,
                priceTier: 'PRICE_15_TO_30',
                ageRestriction: 'TWENTY_ONE_PLUS',
                venueName: 'The Kennedy Center',
                neighborhood: 'Downtown',
                imageUrl: null,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await expectLater(
        find.byType(Card),
        matchesGoldenFile('goldens/event_card_light.png'),
      );
    });

    testWidgets('EventCard dark mode with price and age restriction',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(500, 250);
      addTearDown(() => tester.view.resetPhysicalSize());

      final startTime = DateTime(2025, 3, 15, 20, 0);
      final doorsTime = DateTime(2025, 3, 15, 19, 30);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: EventCard(
                event: 'test-event',
                startTime: startTime,
                doorsTime: doorsTime,
                title: 'Amazing Concert Experience',
                minPrice: 25.0,
                maxPrice: 50.0,
                priceTier: 'PRICE_15_TO_30',
                ageRestriction: 'TWENTY_ONE_PLUS',
                venueName: 'The Kennedy Center',
                neighborhood: 'Downtown',
                imageUrl: null,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await expectLater(
        find.byType(Card),
        matchesGoldenFile('goldens/event_card_dark.png'),
      );
    });

    testWidgets('EventCard light mode with free price tier',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(500, 200);
      addTearDown(() => tester.view.resetPhysicalSize());

      final startTime = DateTime(2025, 3, 15, 20, 0);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: EventCard(
                event: 'test-event',
                startTime: startTime,
                title: 'Free Community Event',
                priceTier: 'FREE',
                ageRestriction: 'ALL_AGES',
                venueName: 'Local Park',
                neighborhood: 'Columbia Heights',
                imageUrl: null,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await expectLater(
        find.byType(Card),
        matchesGoldenFile('goldens/event_card_free_light.png'),
      );
    });
  });
}
