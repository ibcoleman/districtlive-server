import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:district_live/features/venues/presentation/venue_card.dart';

void main() {
  group('VenueCard widget tests', () {
    testWidgets('renders name, neighborhood, and event count', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VenueCard(
              name: '9:30 Club',
              neighborhood: 'U Street',
              upcomingEventCount: 12,
            ),
          ),
        ),
      );

      expect(find.text('9:30 Club'), findsOneWidget);
      expect(find.text('U Street'), findsOneWidget);
      expect(find.text('12 shows'), findsOneWidget);
    });

    testWidgets('hides neighborhood text when null', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VenueCard(
              name: 'Black Cat',
              neighborhood: null,
              upcomingEventCount: 8,
            ),
          ),
        ),
      );

      expect(find.text('Black Cat'), findsOneWidget);
      expect(find.text('8 shows'), findsOneWidget);
      // Should not find any neighborhood text
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('displays 0 shows when upcomingEventCount is 0', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VenueCard(
              name: 'Test Venue',
              neighborhood: 'Downtown',
              upcomingEventCount: 0,
            ),
          ),
        ),
      );

      expect(find.text('Test Venue'), findsOneWidget);
      expect(find.text('0 shows'), findsOneWidget);
    });

    testWidgets('invokes onTap callback when tapped', (WidgetTester tester) async {
      var wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VenueCard(
              name: 'Kennedy Center',
              neighborhood: 'West End',
              upcomingEventCount: 5,
              onTap: () => wasTapped = true,
            ),
          ),
        ),
      );

      expect(wasTapped, false);
      await tester.tap(find.byType(Card));
      await tester.pumpAndSettle();
      expect(wasTapped, true);
    });

    testWidgets('truncates long venue name with ellipsis', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200, // Constrain width to force truncation
              child: VenueCard(
                name: 'This is a very long venue name that should be truncated with ellipsis',
                neighborhood: 'U Street',
                upcomingEventCount: 3,
              ),
            ),
          ),
        ),
      );

      expect(find.text('This is a very long venue name that should be truncated with ellipsis'), findsOneWidget);
      // The text should have maxLines=2 and overflow=ellipsis
    });
  });
}
