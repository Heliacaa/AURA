// Basic smoke test for AURA app.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:aura/core/router/app_router.dart';
import 'package:aura/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('AURA')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [routerProvider.overrideWith((ref) => router)],
        child: const AuraApp(),
      ),
    );
    expect(find.text('AURA'), findsOneWidget);
  });
}
