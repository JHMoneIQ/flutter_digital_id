import 'package:flutter_digital_id/flutter_digital_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeDigitalIdPlatform fakePlatform;
  late DigitalIdPlatform originalPlatform;

  setUp(() {
    originalPlatform = DigitalIdPlatform.instance;
    fakePlatform = _FakeDigitalIdPlatform();
    DigitalIdPlatform.instance = fakePlatform;
  });

  tearDown(() {
    DigitalIdPlatform.instance = originalPlatform;
  });

  test('verifyAge uses the requested minimum age threshold', () async {
    await DigitalId.instance.verifyAge(minimumAge: 25);

    expect(fakePlatform.lastType, DigitalIdType.ageVerificationOnly);
    expect(fakePlatform.lastOptions, isNotNull);
    expect(fakePlatform.lastOptions!.requiredClaims, hasLength(1));
    expect(
      fakePlatform.lastOptions!.requiredClaims.single,
      ClaimPath.ageOver(25),
    );
  });

  test('verifyAge defaults to age over 18', () async {
    await DigitalId.instance.verifyAge();

    expect(
      fakePlatform.lastOptions!.requiredClaims.single,
      ClaimPath.ageOver18(),
    );
  });
}

class _FakeDigitalIdPlatform extends DigitalIdPlatform {
  DigitalIdType? lastType;
  DigitalIdRequestOptions? lastOptions;

  @override
  Future<DigitalIdCredential?> getDigitalId(
    DigitalIdType type, {
    DigitalIdRequestOptions? options,
  }) async {
    lastType = type;
    lastOptions = options;
    return null;
  }

  @override
  Future<bool> isDigitalIdAvailable(
    DigitalIdType type, {
    DigitalIdRequestOptions? options,
  }) async => false;

  @override
  Future<bool> requestPermission(
    DigitalIdType type, {
    DigitalIdRequestOptions? options,
  }) async => false;
}
