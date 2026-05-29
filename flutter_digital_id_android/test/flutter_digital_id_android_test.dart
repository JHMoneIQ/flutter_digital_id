import 'dart:convert';

import 'package:flutter_digital_id_android/flutter_digital_id_android.dart';
import 'package:flutter_digital_id_platform_interface/flutter_digital_id_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FlutterDigitalIdAndroid request builder (channel mapping)', () {
    late FlutterDigitalIdAndroid impl;

    setUp(() {
      impl = FlutterDigitalIdAndroid();
    });

    test('builds DCQL request for driversLicense with required claims', () {
      final options = DigitalIdRequestOptions(
        requiredClaims: [
          ClaimPath.familyName(),
          ClaimPath.givenName(),
          ClaimPath.documentNumber(),
        ],
        intentToRetain: true,
        nonce: 'test-nonce-123',
      );

      final jsonStr = impl.buildDcqlRequestJson(DigitalIdType.driversLicense, options);
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;

      expect(decoded['requests'], isA<List>());
      final request = (decoded['requests'] as List).first as Map<String, dynamic>;
      expect(request['nonce'], 'test-nonce-123');
      expect(request['dcql_query'], isNotNull);

      final dcql = request['dcql_query'] as Map<String, dynamic>;
      final cred = (dcql['credentials'] as List).first as Map<String, dynamic>;
      expect(cred['meta']['doctype_value'], 'org.iso.18013.5.1.mDL');
      expect(cred['claims'], isA<List>());
      expect((cred['claims'] as List).length, 3);
      expect((cred['claims'] as List).any((c) => (c as Map)['path'].last == 'family_name'), isTrue);
    });

    test('includes platformOptions escape hatch when provided', () {
      final options = DigitalIdRequestOptions(
        platformOptions: {
          'requests': [
            {'custom': 'full-override'}
          ]
        },
      );

      final jsonStr = impl.buildDcqlRequestJson(DigitalIdType.passport, options);
      expect(jsonStr, contains('full-override'));
    });

    test('falls back to sensible defaults when no claims specified', () {
      final jsonStr = impl.buildDcqlRequestJson(DigitalIdType.ageVerificationOnly, null);
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      final claims = (((decoded['requests'] as List).first as Map)['dcql_query'] as Map)['credentials'].first['claims'] as List;
      expect(claims.any((c) => (c as Map)['path'].contains('age_over_18')), isTrue);
    });

    test('maps euDigitalId / passport to expected doctype', () {
      final json = impl.buildDcqlRequestJson(DigitalIdType.euDigitalId, null);
      expect(json, contains('com.google.wallet.idcard.1'));
    });
  });

  group('FlutterDigitalIdAndroid registration', () {
    test('registerWith sets the platform instance', () {
      // Reset to stub first
      DigitalIdPlatform.instance = _FakeStub();
      FlutterDigitalIdAndroid.registerWith();
      expect(DigitalIdPlatform.instance, isA<FlutterDigitalIdAndroid>());
    });
  });
}

class _FakeStub extends DigitalIdPlatform {
  @override
  Future<bool> isDigitalIdAvailable(DigitalIdType type, {DigitalIdRequestOptions? options}) async => false;

  @override
  Future<bool> requestPermission(DigitalIdType type, {DigitalIdRequestOptions? options}) async => false;

  @override
  Future<DigitalIdCredential?> getDigitalId(DigitalIdType type, {DigitalIdRequestOptions? options}) async => null;
}
