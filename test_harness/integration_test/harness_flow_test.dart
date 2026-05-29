import 'dart:typed_data';

import 'package:digital_id_test_harness/main.dart';
import 'package:flutter_digital_id/flutter_digital_id.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late _FakeHarnessPlatform fakePlatform;
  late DigitalIdPlatform originalPlatform;

  setUp(() {
    originalPlatform = DigitalIdPlatform.instance;
    fakePlatform = _FakeHarnessPlatform();
    DigitalIdPlatform.instance = fakePlatform;
  });

  tearDown(() {
    DigitalIdPlatform.instance = originalPlatform;
  });

  testWidgets('load test vector flow populates the credential card', (
    tester,
  ) async {
    await tester.pumpWidget(const DigitalIdTestHarnessApp());

    await tester.tap(find.byKey(loadTestVectorButtonKey));
    await tester.pumpAndSettle();

    expect(find.byKey(lastCredentialCardKey), findsOneWidget);
    expect(find.textContaining('Jane Doe'), findsWidgets);
    expect(find.textContaining('test-vector'), findsWidgets);
  });

  testWidgets('availability flow updates status text', (tester) async {
    fakePlatform.available = false;

    await tester.pumpWidget(const DigitalIdTestHarnessApp());

    await tester.tap(find.byKey(availabilityButtonKey(DigitalIdType.passport)));
    await tester.pumpAndSettle();

    expect(find.byKey(statusTextKey), findsOneWidget);
    expect(find.textContaining('not available'), findsWidgets);
  });

  testWidgets('real request flow surfaces returned credential details', (
    tester,
  ) async {
    fakePlatform.nextResult = DigitalIdCredential(
      givenName: 'Integration',
      familyName: 'Tester',
      rawCredential: Uint8List.fromList([1, 2, 3]),
      credentialFormat: 'openid4vp-vp-token',
    );

    await tester.pumpWidget(const DigitalIdTestHarnessApp());

    await tester.tap(
      find.byKey(requestButtonKey(DigitalIdType.driversLicense)),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('SUCCESS!'), findsWidgets);
    expect(find.byKey(lastCredentialCardKey), findsOneWidget);
    expect(find.textContaining('Integration Tester'), findsWidgets);
  });
}

class _FakeHarnessPlatform extends DigitalIdPlatform {
  bool available = true;
  DigitalIdCredential? nextResult;

  @override
  Future<DigitalIdCredential?> getDigitalId(
    DigitalIdType type, {
    DigitalIdRequestOptions? options,
  }) async => nextResult;

  @override
  Future<bool> isDigitalIdAvailable(
    DigitalIdType type, {
    DigitalIdRequestOptions? options,
  }) async => available;

  @override
  Future<bool> requestPermission(
    DigitalIdType type, {
    DigitalIdRequestOptions? options,
  }) async => available;
}
