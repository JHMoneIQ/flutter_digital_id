import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_digital_id_platform_interface/flutter_digital_id_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DigitalIdCredential hand-coded serialization', () {
    test(
      'roundtrips through toMap/fromMap and toJson/fromJson with realistic seed',
      () {
        final seed = _buildRealisticPassportSeed();

        final original = DigitalIdCredential.fromMap(seed);
        final map = original.toMap();
        final jsonString = original.toJson();

        final fromMap = DigitalIdCredential.fromMap(map);
        final fromJson = DigitalIdCredential.fromJson(jsonString);

        // Structured fields match
        expect(fromMap.givenName, 'Jane');
        expect(fromMap.familyName, 'Doe');
        expect(fromMap.nationality, 'US');
        expect(fromMap.ageOver18, true);
        expect(fromMap.portrait, isNotNull);
        expect(fromMap.portrait!.length, greaterThan(100));

        // Raw proof is preserved exactly
        expect(fromMap.rawCredential, equals(original.rawCredential));
        expect(fromJson.rawCredential, equals(original.rawCredential));

        // Format and metadata preserved
        expect(fromMap.credentialFormat, 'apple-encrypted');
        expect(fromJson.metadata['sessionId'], 'test-session-123');
      },
    );

    test('handles minimal credential (only required fields + raw proof)', () {
      final minimal = DigitalIdCredential(
        rawCredential: Uint8List.fromList([1, 2, 3, 4, 5]),
        credentialFormat: 'mdoc-device-response',
      );

      final roundtripped = DigitalIdCredential.fromJson(minimal.toJson());

      expect(roundtripped.givenName, isNull);
      expect(roundtripped.rawCredential, equals(minimal.rawCredential));
      expect(roundtripped.credentialFormat, 'mdoc-device-response');
    });

    test(
      'negative case - corrupted base64 in portrait does not crash fromMap',
      () {
        final badMap = {
          'rawCredential': base64Encode(Uint8List(8)),
          'credentialFormat': 'test',
          'portrait': 'not-valid-base64!!!',
        };

        expect(
          () => DigitalIdCredential.fromMap(badMap),
          throwsA(isA<FormatException>()),
        );
      },
    );
  });

  group('DigitalIdRequestOptions hand-coded serialization', () {
    test('roundtrips required + optional claims', () {
      final options = DigitalIdRequestOptions(
        requiredClaims: [ClaimPath.familyName(), ClaimPath.givenName()],
        optionalClaims: [ClaimPath.portrait()],
        intentToRetain: false,
        nonce: 'abc123',
      );

      final json = options.toJson();
      final restored = DigitalIdRequestOptions.fromJson(json);

      expect(restored.requiredClaims.length, 2);
      expect(restored.optionalClaims.length, 1);
      expect(restored.nonce, 'abc123');
    });
  });

  group('ClaimPath equality (critical for options dedup / comparison)', () {
    test('equal paths are equal regardless of construction', () {
      final a = ClaimPath.familyName();
      final b = const ClaimPath(['org.iso.18013.5.1', 'family_name']);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different order or values are not equal (fixed bug)', () {
      final a = const ClaimPath(['org.iso.18013.5.1', 'family_name']);
      final reordered = const ClaimPath(['family_name', 'org.iso.18013.5.1']);
      final different = const ClaimPath(['org.iso.18013.5.1', 'given_name']);

      expect(a == reordered, isFalse);
      expect(a == different, isFalse);
    });

    test('ClaimPath.ageOver honors minimumAge semantics', () {
      expect(ClaimPath.ageOver(18), ClaimPath.ageOver18());
      expect(ClaimPath.ageOver(21), ClaimPath.ageOver21());
      expect(ClaimPath.ageOver(25).segments.last, 'age_over_25');
    });
  });
}

Map<String, dynamic> _buildRealisticPassportSeed() {
  return {
    'givenName': 'Jane',
    'familyName': 'Doe',
    'fullName': 'Jane Doe',
    'dateOfBirth': '1990-05-15T00:00:00.000Z',
    'ageOver18': true,
    'ageOver21': true,
    'nationality': 'US',
    'documentNumber': 'A12345678',
    'documentType': 'passport',
    'issuingCountry': 'US',
    'expirationDate': '2035-05-15T00:00:00.000Z',
    'portrait': base64Encode(
      Uint8List.fromList(List.filled(512, 0xAA)),
    ), // fake JPEG bytes
    'rawCredential': base64Encode(
      Uint8List.fromList([0xDE, 0xAD, 0xBE, 0xEF, 0xCA, 0xFE]),
    ),
    'credentialFormat': 'apple-encrypted',
    'disclosedClaimPaths': [
      'org.iso.18013.5.1.family_name',
      'org.iso.18013.5.1.given_name',
    ],
    'metadata': {
      'sessionId': 'test-session-123',
      'issuer': 'us-passport-issuer',
    },
  };
}
