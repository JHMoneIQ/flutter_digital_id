import 'package:flutter_digital_id_platform_interface/flutter_digital_id_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mock_digital_id_platform.dart';
import 'test_vectors.dart';

void main() {
  late MockDigitalIdPlatform mock;

  setUp(() {
    mock = MockDigitalIdPlatform();
    DigitalIdPlatform.instance = mock;
  });

  test('positive path - rich passport request returns structured data + raw proof', () async {
    mock.setNextResult(DigitalIdTestVectors.richPassport);

    final result = await mock.getDigitalId(DigitalIdType.passport);

    expect(result, isNotNull);
    expect(result!.givenName, 'Jane');
    expect(result.familyName, 'Doe');
    expect(result.nationality, 'US');
    expect(result.ageOver18, true);
    expect(result.rawCredential, isNotEmpty);
    expect(result.credentialFormat, 'apple-encrypted');
  });

  test('positive path - minimal age verification', () async {
    mock.setNextResult(DigitalIdTestVectors.minimalAgeVerification);

    final result = await mock.getDigitalId(DigitalIdType.ageVerificationOnly);

    expect(result, isNotNull);
    expect(result!.ageOver18, true);
    expect(result.ageOver21, true);
  });

  test('negative path - user cancellation returns null', () async {
    mock.setNextError(Exception('user cancelled'));

    final result = await mock.getDigitalId(DigitalIdType.driversLicense);
    expect(result, isNull);
  });

  test('negative path - not entitled error is properly constructed', () async {
    final error = DigitalIdTestVectors.notEntitledError;
    expect(error.code, DigitalIdErrorCode.notEntitled);
    expect(error.toJson(), contains('notEntitled'));
  });

  test('availability check respects mock', () async {
    mock.setAvailable(false);
    expect(await mock.isDigitalIdAvailable(DigitalIdType.passport), isFalse);

    mock.setAvailable(true);
    expect(await mock.isDigitalIdAvailable(DigitalIdType.passport), isTrue);
  });

  test('serialization roundtrip of test vectors', () {
    final vectors = [
      DigitalIdTestVectors.richPassport,
      DigitalIdTestVectors.minimalAgeVerification,
      DigitalIdTestVectors.withPortrait,
      DigitalIdTestVectors.iosEncryptedPassport,
      DigitalIdTestVectors.androidMdlSuccess,
      DigitalIdTestVectors.webDigitalCredentialsSuccess,
    ];

    for (final original in vectors) {
      final json = original.toJson();
      final restored = DigitalIdCredential.fromJson(json);

      expect(restored.givenName, original.givenName);
      expect(restored.rawCredential, original.rawCredential);
      expect(restored.credentialFormat, original.credentialFormat);
    }
  });

  test('Android-specific seed roundtrips and has expected metadata', () {
    final cred = DigitalIdTestVectors.androidMdlSuccess;
    expect(cred.credentialFormat, 'openid4vp-vp-token');
    expect(cred.metadata['source'], 'android-credential-manager');
    expect(cred.state, 'CA');
  });

  test('Web-specific seed roundtrips and has expected format', () {
    final cred = DigitalIdTestVectors.webDigitalCredentialsSuccess;
    expect(cred.credentialFormat, 'digital-credentials-api');
    expect(cred.metadata['protocol'], 'openid4vp-v1-unsigned');
  });

  test('Negative case - noCredential error serializes and has correct code', () {
    final err = DigitalIdTestVectors.noCredentialError;
    expect(err.code, DigitalIdErrorCode.noCredential);
    final json = err.toJson();
    expect(json, contains('noCredential'));
  });
}
