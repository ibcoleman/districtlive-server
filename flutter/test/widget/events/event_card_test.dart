import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:district_live/features/events/presentation/event_card.dart';

void main() {
  group('EventCard widget tests', () {
    testWidgets('renders title, venue, date/time, and price tier', (WidgetTester tester) async {
      final startTime = DateTime(2025, 3, 15, 20, 0);
      final doorsTime = DateTime(2025, 3, 15, 19, 30);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventCard(
              event: 'test-event',
              startTime: startTime,
              doorsTime: doorsTime,
              title: 'Amazing Concert',
              minPrice: 25.0,
              maxPrice: 50.0,
              priceTier: 'PAID',
              ageRestriction: 'ALL_AGES',
              venueName: 'The Venue',
              neighborhood: 'U Street',
            ),
          ),
        ),
      );

      expect(find.text('Amazing Concert'), findsOneWidget);
      expect(find.text('The Venue · U Street'), findsOneWidget);
      expect(find.text('\$25-\$50'), findsOneWidget);
      // Date format: "Sat, Mar 15"
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('hides price chip when no price data', (WidgetTester tester) async {
      final startTime = DateTime(2025, 3, 15, 20, 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventCard(
              event: 'test-event',
              startTime: startTime,
              title: 'Event Without Price',
              ageRestriction: 'ALL_AGES',
            ),
          ),
        ),
      );

      // Should not find any price chip
      expect(find.byType(Chip), findsNothing);
    });

    testWidgets('hides age chip when ALL_AGES', (WidgetTester tester) async {
      final startTime = DateTime(2025, 3, 15, 20, 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventCard(
              event: 'test-event',
              startTime: startTime,
              title: 'All Ages Event',
              minPrice: 10.0,
              ageRestriction: 'ALL_AGES',
            ),
          ),
        ),
      );

      // Should have price chip but not age chip
      expect(find.byType(Chip), findsOneWidget);
      expect(find.text('18+'), findsNothing);
      expect(find.text('21+'), findsNothing);
    });

    testWidgets('shows 18+ age chip when EIGHTEEN_PLUS', (WidgetTester tester) async {
      final startTime = DateTime(2025, 3, 15, 20, 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventCard(
              event: 'test-event',
              startTime: startTime,
              title: '18+ Event',
              ageRestriction: 'EIGHTEEN_PLUS',
            ),
          ),
        ),
      );

      expect(find.text('18+'), findsOneWidget);
    });

    testWidgets('shows 21+ age chip when TWENTY_ONE_PLUS', (WidgetTester tester) async {
      final startTime = DateTime(2025, 3, 15, 20, 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventCard(
              event: 'test-event',
              startTime: startTime,
              title: '21+ Event',
              ageRestriction: 'TWENTY_ONE_PLUS',
            ),
          ),
        ),
      );

      expect(find.text('21+'), findsOneWidget);
    });

    testWidgets('shows placeholder when no imageUrl', (WidgetTester tester) async {
      final startTime = DateTime(2025, 3, 15, 20, 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventCard(
              event: 'test-event',
              startTime: startTime,
              title: 'Event Without Image',
              ageRestriction: 'ALL_AGES',
            ),
          ),
        ),
      );

      // Should have a placeholder icon
      expect(find.byIcon(Icons.music_note), findsOneWidget);
    });

    testWidgets('invokes onTap callback when tapped', (WidgetTester tester) async {
      var wasPressed = false;
      final startTime = DateTime(2025, 3, 15, 20, 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventCard(
              event: 'test-event',
              startTime: startTime,
              title: 'Tappable Event',
              ageRestriction: 'ALL_AGES',
              onTap: () => wasPressed = true,
            ),
          ),
        ),
      );

      expect(wasPressed, false);
      await tester.tap(find.byType(Card));
      await tester.pumpAndSettle();
      expect(wasPressed, true);
    });

    testWidgets('displays only start time when doors time is null', (WidgetTester tester) async {
      final startTime = DateTime(2025, 3, 15, 20, 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventCard(
              event: 'test-event',
              startTime: startTime,
              doorsTime: null,
              title: 'Event Without Doors',
              ageRestriction: 'ALL_AGES',
            ),
          ),
        ),
      );

      // Should contain "Show 8:00pm" but not "Doors"
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('displays FREE price tier when priceTier is FREE', (WidgetTester tester) async {
      final startTime = DateTime(2025, 3, 15, 20, 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventCard(
              event: 'test-event',
              startTime: startTime,
              title: 'Free Event',
              priceTier: 'FREE',
              ageRestriction: 'ALL_AGES',
            ),
          ),
        ),
      );

      expect(find.text('Free'), findsOneWidget);
    });
  });
}
