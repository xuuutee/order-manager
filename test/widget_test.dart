// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:order_manager/main.dart';

void main() {
  testWidgets('App loads without crash', (WidgetTester tester) async {
    // This test verifies the app widget tree builds without error.
    // Full integration tests require Supabase connectivity.
    await tester.pumpWidget(const OrderManagerApp());
    await tester.pumpAndSettle(const Duration(seconds: 1));
  });
}
