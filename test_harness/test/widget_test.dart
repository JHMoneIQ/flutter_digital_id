// Widget/integration-style tests for the Digital ID Test Harness.
// These exercise the UI flows using a mocked platform (no native calls).

import 'dart:typed_data';

import 'package:digital_id_test_harness/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_digital_id/flutter_digital_id.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockHarnessPlatform extends DigitalIdPlatform {
  bool available = true;
  DigitalIdCredential? nextResult;

  @override
  Future<bool> isDigitalIdAvailable(
    DigitalIdType type, {
    DigitalIdRequestOptions? options,
  }) async {
    return available;
  }

  @override
  Future<bool> requestPermission(
    DigitalIdType type, {
    DigitalIdRequestOptions? options,
  }) async {
    return available;
  }

  @override
  Future<DigitalIdCredential?> getDigitalId(
    DigitalIdType type, {
    DigitalIdRequestOptions? options,
  }) async {
    return nextResult;
  }
}

void main() {
  late _MockHarnessPlatform mock;

  setUp(() {
    mock = _MockHarnessPlatform();
    DigitalIdPlatform.instance = mock;
  });

  testWidgets('DigitalIdTestHarnessApp smoke test + basic UI elements', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const DigitalIdTestHarnessApp());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.textContaining('Digital ID Test Harness'), findsOneWidget);
    expect(find.textContaining('Ready'), findsOneWidget);
  });

  testWidgets('Harness shows success state when mock returns a credential', (
    WidgetTester tester,
  ) async {
    mock.nextResult = DigitalIdCredential(
      givenName: 'Test',
      familyName: 'User',
      rawCredential: Uint8List.fromList([1, 2, 3, 4]),
      credentialFormat: 'apple-encrypted',
    );

    await tester.pumpWidget(const DigitalIdTestHarnessApp());

    await tester.tap(find.byKey(requestButtonKey(DigitalIdType.passport)));
    await tester.pumpAndSettle();

    expect(find.byKey(statusTextKey), findsOneWidget);
    expect(find.textContaining('SUCCESS'), findsWidgets);
    expect(find.byKey(lastCredentialCardKey), findsOneWidget);
  });

  testWidgets('Harness handles null result (cancel) gracefully', (
    WidgetTester tester,
  ) async {
    mock.nextResult = null;

    await tester.pumpWidget(const DigitalIdTestHarnessApp());

    await tester.tap(find.byKey(requestButtonKey(DigitalIdType.passport)));
    await tester.pumpAndSettle();

    expect(find.textContaining('cancelled'), findsWidgets);
  });

  testWidgets('Harness load test vector button populates credential details', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const DigitalIdTestHarnessApp());

    await tester.tap(find.byKey(loadTestVectorButtonKey));
    await tester.pumpAndSettle();

    expect(find.byKey(lastCredentialCardKey), findsOneWidget);
    expect(find.textContaining('Jane Doe'), findsWidgets);
    expect(find.textContaining('test-vector'), findsWidgets);
  });

  testWidgets('Harness renders without crashing with mocked platform', (
    WidgetTester tester,
  ) async {
    mock.available = false;
    mock.nextResult = null;

    await tester.pumpWidget(const DigitalIdTestHarnessApp());

    // Basic structural expectations
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.textContaining('Test Harness'), findsOneWidget);
  });
}
