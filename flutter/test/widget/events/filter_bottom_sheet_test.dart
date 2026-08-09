import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:district_live/features/events/presentation/filter_bottom_sheet.dart';

void main() {
  group('FilterBottomSheet widget tests', () {
    testWidgets('displays all provided filter items (simple)', (WidgetTester tester) async {
      final items = ['Rock', 'Jazz', 'Pop'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterBottomSheet.simple(
              title: 'Genre',
              items: items,
              selectedKey: null,
              onSelected: (_) {},
            ),
          ),
        ),
      );

      // Check all items are displayed
      expect(find.text('Rock'), findsOneWidget);
      expect(find.text('Jazz'), findsOneWidget);
      expect(find.text('Pop'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
    });

    testWidgets('displays all provided filter items (key-value)', (WidgetTester tester) async {
      final items = [
        (key: 'venue-1', value: 'The Kennedy Center'),
        (key: 'venue-2', value: 'The Anthem'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterBottomSheet.keyValue(
              title: 'Venue',
              items: items,
              selectedKey: null,
              onSelected: (_) {},
            ),
          ),
        ),
      );

      // Check venue names are displayed (not keys)
      expect(find.text('The Kennedy Center'), findsOneWidget);
      expect(find.text('The Anthem'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
    });

    testWidgets('tapping "All" invokes callback with null', (WidgetTester tester) async {
      String? selectedGenre = 'Rock';
      final items = ['Rock', 'Jazz', 'Pop'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterBottomSheet.simple(
              title: 'Genre',
              items: items,
              selectedKey: selectedGenre,
              onSelected: (genre) {
                selectedGenre = genre;
              },
            ),
          ),
        ),
      );

      // Initially Rock should be selected
      expect(selectedGenre, 'Rock');

      // Tap "All"
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      // Callback should be invoked with null
      expect(selectedGenre, null);
    });

    testWidgets('tapping an item invokes callback with correct value (simple)',
        (WidgetTester tester) async {
      String? selectedGenre;
      final items = ['Rock', 'Jazz', 'Pop'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterBottomSheet.simple(
              title: 'Genre',
              items: items,
              selectedKey: selectedGenre,
              onSelected: (genre) {
                selectedGenre = genre;
              },
            ),
          ),
        ),
      );

      // Tap Jazz
      await tester.tap(find.text('Jazz'));
      await tester.pumpAndSettle();

      expect(selectedGenre, 'Jazz');
    });

    testWidgets('tapping an item invokes callback with correct key (key-value)',
        (WidgetTester tester) async {
      String? selectedVenueId;
      final items = [
        (key: 'venue-1', value: 'The Kennedy Center'),
        (key: 'venue-2', value: 'The Anthem'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterBottomSheet.keyValue(
              title: 'Venue',
              items: items,
              selectedKey: selectedVenueId,
              onSelected: (venueId) {
                selectedVenueId = venueId;
              },
            ),
          ),
        ),
      );

      // Tap The Anthem
      await tester.tap(find.text('The Anthem'));
      await tester.pumpAndSettle();

      // Should invoke callback with key, not value
      expect(selectedVenueId, 'venue-2');
    });

    testWidgets('selected item is highlighted with checkmark (simple)',
        (WidgetTester tester) async {
      String? selectedGenre = 'Jazz';
      final items = ['Rock', 'Jazz', 'Pop'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterBottomSheet.simple(
              title: 'Genre',
              items: items,
              selectedKey: selectedGenre,
              onSelected: (_) {},
            ),
          ),
        ),
      );

      // Jazz should have a checkmark
      expect(find.byIcon(Icons.check), findsWidgets);
    });

    testWidgets('selected item is highlighted with checkmark (key-value)',
        (WidgetTester tester) async {
      String? selectedVenueId = 'venue-1';
      final items = [
        (key: 'venue-1', value: 'The Kennedy Center'),
        (key: 'venue-2', value: 'The Anthem'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterBottomSheet.keyValue(
              title: 'Venue',
              items: items,
              selectedKey: selectedVenueId,
              onSelected: (_) {},
            ),
          ),
        ),
      );

      // Should have checkmark for selected item
      expect(find.byIcon(Icons.check), findsWidgets);
    });

    testWidgets('All option is highlighted when no selection', (WidgetTester tester) async {
      String? selectedGenre;
      final items = ['Rock', 'Jazz', 'Pop'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterBottomSheet.simple(
              title: 'Genre',
              items: items,
              selectedKey: selectedGenre,
              onSelected: (_) {},
            ),
          ),
        ),
      );

      // "All" should be highlighted with checkmark
      expect(find.byIcon(Icons.check), findsWidgets);
    });
  });
}
