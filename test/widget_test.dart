import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_auth.dart';

void main() {
  testWidgets('shell renders the four bottom-nav tabs', (tester) async {
    await pumpApp(tester);

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Outstanding'), findsOneWidget);
    expect(find.text('Customers'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
  });

  testWidgets('home app bar shows the caller and their region and city',
      (tester) async {
    await pumpApp(tester);

    expect(find.textContaining('Aakanksha'), findsWidgets);
    expect(find.textContaining('Mumbai'), findsWidgets);
  });

  testWidgets('home shows the priority queue below the fold', (tester) async {
    await pumpApp(tester);

    await tester.scrollUntilVisible(
      find.text('Priority calls'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Priority calls'), findsOneWidget);
    expect(find.textContaining('POLYCAB'), findsOneWidget);
  });

  testWidgets('tapping a tab switches the branch', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Customers'));
    await tester.pumpAndSettle();

    // The real directory, not the placeholder it replaced.
    expect(find.text('Search name, code or mobile'), findsOneWidget);
  });
}
