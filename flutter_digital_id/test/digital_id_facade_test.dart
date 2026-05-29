import 'dart:typed_data';

import 'package:flutter_digital_id/flutter_digital_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _CapturingMockPlatform mock;

  setUp(() {
    mock = _CapturingMockPlatform();
    DigitalIdPlatform.instance = mock;
  });

  test('DigitalId convenience methods delegate to platform', () async {
    mock.nextResult = _makeTestCredential();

    final cred = await DigitalId.instance.verifyWithPassport();
    expect(cred, isNotNull);
    expect(cred!.givenName, 'Jane');
  });

  test('verifyAge honors minimumAge by selecting correct claim (via options)', () async {
    DigitalIdRequestOptions? captured;

    mock.captureOptions = (opts) => captured = opts;
    mock.nextResult = _makeMinimalAgeCred();

    await DigitalId.instance.verifyAge(minimumAge: 21);
    expect(captured, isNotNull);
    expect(captured!.requiredClaims, hasLength(1));
    expect(captured!.requiredClaims.first, ClaimPath.ageOver21());

    await DigitalId.instance.verifyAge(minimumAge: 16);
    expect(captured!.requiredClaims.first, ClaimPath.ageOver18());

    await DigitalId.instance.verifyAge(minimumAge: 25);
    // Dynamic path for >21
    expect(captured!.requiredClaims.first.segments.last, 'age_over_25');
  });

  test('isAvailable and requestPermission delegate correctly', () async {
    mock.available = true;
    expect(await DigitalId.instance.isAvailable(DigitalIdType.passport), isTrue);

    final perm = await DigitalId.instance.requestPermission(DigitalIdType.driversLicense);
    expect(perm, isTrue);
  });
}

class _CapturingMockPlatform extends DigitalIdPlatform {
  bool available = true;
  DigitalIdCredential? nextResult;
  void Function(DigitalIdRequestOptions?)? captureOptions;

  @override
  Future<bool> isDigitalIdAvailable(DigitalIdType type, {DigitalIdRequestOptions? options}) async => available;

  @override
  Future<bool> requestPermission(DigitalIdType type, {DigitalIdRequestOptions? options}) async => available;

  @override
  Future<DigitalIdCredential?> getDigitalId(DigitalIdType type, {DigitalIdRequestOptions? options}) async {
    captureOptions?.call(options);
    return nextResult;
  }
}

DigitalIdCredential _makeTestCredential() => DigitalIdCredential(
      givenName: 'Jane',
      familyName: 'Doe',
      rawCredential: Uint8List.fromList([1, 2, 3]),
      credentialFormat: 'apple-encrypted',
    );

DigitalIdCredential _makeMinimalAgeCred() => DigitalIdCredential(
      ageOver18: true,
      ageOver21: true,
      rawCredential: Uint8List(4),
      credentialFormat: 'mdoc-device-response',
    );
