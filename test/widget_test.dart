import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telecaller_app/app/tegh_app.dart';

void main() {
  testWidgets('shell renders the four bottom-nav tabs', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TeghApp()));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Outstanding'), findsOneWidget);
    expect(find.text('Customers'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
  });

  testWidgets('home shows the region and city the caller is scoped to',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TeghApp()));
    await tester.pumpAndSettle();

    expect(find.text('Calling in'), findsOneWidget);
    expect(find.textContaining('Mumbai'), findsWidgets);
  });

  testWidgets('home shows the priority queue below the fold', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TeghApp()));
    await tester.pumpAndSettle();

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
    await tester.pumpWidget(const ProviderScope(child: TeghApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Customers'));
    await tester.pumpAndSettle();

    expect(find.text('Party directory'), findsOneWidget);
  });
}
