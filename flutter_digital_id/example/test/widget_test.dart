// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_digital_id_example/main.dart';

void main() {
  testWidgets('DigitalIdExampleApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const DigitalIdExampleApp());

    // Basic smoke test — the example should render without crashing.
    expect(find.byType(MaterialApp), findsOneWidget);
    // AppBar title is the visible text
    expect(find.text('flutter_digital_id Demo'), findsOneWidget);
    // Key UI elements from the (now scrollable) body
    expect(find.textContaining('Availability checks'), findsOneWidget);
    expect(find.textContaining('Use test vector'), findsOneWidget);
  });
}
