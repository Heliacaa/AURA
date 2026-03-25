// Basic smoke test for AURA app.

import 'package:flutter_test/flutter_test.dart';

import 'package:aura/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AuraApp());
    expect(find.text('AURA'), findsOneWidget);
  });
}
