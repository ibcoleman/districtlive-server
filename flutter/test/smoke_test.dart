import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:district_live/app.dart';

void main() {
  testWidgets('App renders with bottom navigation bar', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: DistrictLiveApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify bottom navigation bar exists with 3 tabs
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Featured'), findsWidgets);
    expect(find.text('Events'), findsWidgets);
    expect(find.text('Venues'), findsWidgets);
  });
}
