import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:district_live/core/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    testWidgets('light mode renders correctly with light brightness',
        (WidgetTester tester) async {
      final testWidget = MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: Center(
            child: Text('Light Mode'),
          ),
        ),
      );

      await tester.pumpWidget(testWidget);

      // Verify brightness is light
      final context = tester.element(find.byType(Scaffold));
      expect(Theme.of(context).brightness, Brightness.light);

      // Verify colorScheme is light
      expect(Theme.of(context).colorScheme.brightness, Brightness.light);

      // Verify Material 3 is enabled
      expect(Theme.of(context).useMaterial3, true);
    });

    testWidgets('dark mode renders correctly with dark brightness',
        (WidgetTester tester) async {
      final testWidget = MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(
          body: Center(
            child: Text('Dark Mode'),
          ),
        ),
      );

      await tester.pumpWidget(testWidget);

      // Verify brightness is dark
      final context = tester.element(find.byType(Scaffold));
      expect(Theme.of(context).brightness, Brightness.dark);

      // Verify colorScheme is dark
      expect(Theme.of(context).colorScheme.brightness, Brightness.dark);

      // Verify Material 3 is enabled
      expect(Theme.of(context).useMaterial3, true);
    });

    test('light and dark modes have distinct color schemes', () {
      final lightTheme = AppTheme.light();
      final darkTheme = AppTheme.dark();

      // Verify both are Material 3
      expect(lightTheme.useMaterial3, true);
      expect(darkTheme.useMaterial3, true);

      // Verify brightness is different
      expect(
        lightTheme.colorScheme.brightness,
        isNot(darkTheme.colorScheme.brightness),
      );

      // Verify some key colors are different
      expect(
        lightTheme.colorScheme.primary,
        isNot(darkTheme.colorScheme.primary),
      );
      expect(
        lightTheme.colorScheme.surface,
        isNot(darkTheme.colorScheme.surface),
      );
    });

    test('light theme has correct card theme', () {
      final theme = AppTheme.light();

      expect(theme.cardTheme.elevation, 1);
      expect(theme.cardTheme.shape, isA<RoundedRectangleBorder>());

      final shape = theme.cardTheme.shape as RoundedRectangleBorder;
      final borderRadius = shape.borderRadius as BorderRadius;

      // Verify all corners are 12dp
      expect(borderRadius.topLeft.x, 12);
      expect(borderRadius.topRight.x, 12);
      expect(borderRadius.bottomLeft.x, 12);
      expect(borderRadius.bottomRight.x, 12);
    });

    test('dark theme has correct card theme', () {
      final theme = AppTheme.dark();

      expect(theme.cardTheme.elevation, 1);
      expect(theme.cardTheme.shape, isA<RoundedRectangleBorder>());

      final shape = theme.cardTheme.shape as RoundedRectangleBorder;
      final borderRadius = shape.borderRadius as BorderRadius;

      // Verify all corners are 12dp
      expect(borderRadius.topLeft.x, 12);
      expect(borderRadius.topRight.x, 12);
      expect(borderRadius.bottomLeft.x, 12);
      expect(borderRadius.bottomRight.x, 12);
    });

    test('light theme navigation bar indicator uses secondary container', () {
      final theme = AppTheme.light();
      final lightColorScheme =
          ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4), brightness: Brightness.light);

      expect(
        theme.navigationBarTheme.indicatorColor,
        lightColorScheme.secondaryContainer,
      );
    });

    test('dark theme navigation bar indicator uses secondary container', () {
      final theme = AppTheme.dark();
      final darkColorScheme =
          ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4), brightness: Brightness.dark);

      expect(
        theme.navigationBarTheme.indicatorColor,
        darkColorScheme.secondaryContainer,
      );
    });
  });
}
