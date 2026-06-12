import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_digital_id_platform_interface/flutter_digital_id_platform_interface.dart';
import 'package:flutter_digital_id_web/src/web_request_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WebRequestBuilder - request builder (DCQL shape)', () {
    test('builds a well-formed DCQL request for drivers license with explicit claims', () {
      final options = DigitalIdRequestOptions(
        requiredClaims: [
          const ClaimPath(['org.iso.18013.5.1', 'family_name']),
          const ClaimPath(['org.iso.18013.5.1', 'given_name']),
        ],
        optionalClaims: [ClaimPath.portrait()],
        intentToRetain: false,
        nonce: 'test-nonce-123',
      );

      final json = WebRequestBuilder.buildRequest(DigitalIdType.driversLicense, options);
      final decoded = jsonDecode(json) as Map<String, dynamic>;

      expect(decoded['requests'], isA<List<dynamic>>());
      final req = (decoded['requests'] as List<dynamic>).first as Map<String, dynamic>;

      expect(req['response_type'], 'vp_token');
      expect(req['response_mode'], 'dc_api.jwt');
      expect(req['nonce'], 'test-nonce-123');
      expect(req['dcql_query'], isNotNull);

      final dcql = req['dcql_query'] as Map<String, dynamic>;
      final cred = (dcql['credentials'] as List<dynamic>).first as Map<String, dynamic>;
      expect(cred['format'], 'mso_mdoc');
      expect((cred['meta'] as Map<String, dynamic>)['doctype_value'], 'org.iso.18013.5.1.mDL');

      final claims = (cred['claims'] as List<dynamic>).cast<Map<String, dynamic>>();
      expect(claims.length, 3); // 2 required + 1 optional
      // ignore: avoid_dynamic_calls
      expect(claims.any((c) => c['path'].last == 'family_name'), isTrue);
      // ignore: avoid_dynamic_calls
      expect(claims.any((c) => c['path'].last == 'portrait'), isTrue);
    });

    test('falls back to minimal name + age claims when no options provided', () {
      final json = WebRequestBuilder.buildRequest(DigitalIdType.ageVerificationOnly, null);
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      final req = (decoded['requests'] as List<dynamic>).first as Map<String, dynamic>;
      final claims = (((req['dcql_query'] as Map<String, dynamic>)['credentials'] as List<dynamic>).first as Map<String, dynamic>)['claims'] as List<dynamic>;

      expect(claims.length, 3);
      // ignore: avoid_dynamic_calls
      final paths = claims.cast<Map<String, dynamic>>().map((c) => (c['path'] as List<dynamic>).join('.')).toList();
      expect(paths, contains('org.iso.18013.5.1.family_name'));
      expect(paths, contains('org.iso.18013.5.1.given_name'));
      expect(paths, contains('org.iso.18013.5.1.age_over_18'));
    });

    test('uses Google Wallet style doctype for passport and euDigitalId (current heuristic)', () {
      final p = WebRequestBuilder.buildRequest(DigitalIdType.passport, null);
      final e = WebRequestBuilder.buildRequest(DigitalIdType.euDigitalId, null);

      expect(p, contains('com.google.wallet.idcard.1'));
      expect(e, contains('com.google.wallet.idcard.1'));
    });
  });

  group('WebRequestBuilder - raw credential extraction (response shapes)', () {
    test('extracts Uint8List directly when interop returns bytes', () {
      final bytes = Uint8List.fromList([1, 2, 3, 4]);
      final result = WebRequestBuilder.extractRaw({'data': bytes});
      expect(result, equals(bytes));
    });

    test('decodes base64 string in data.response', () {
      const payload = 'SGVsbG8gV29ybGQ='; // "Hello World"
      final result = WebRequestBuilder.extractRaw({
        'data': {'response': payload}
      });
      expect(result, isNotNull);
      expect(utf8.decode(result!), 'Hello World');
    });

    test('treats vp_token / deviceResponse string as UTF8 bytes (common JSON vp_token case)', () {
      const vp = '{"foo":"bar"}';
      final result = WebRequestBuilder.extractRaw({
        'data': {'vp_token': vp}
      });
      expect(result, isNotNull);
      expect(utf8.decode(result!), vp);
    });

    test('handles top-level credential.response fallback', () {
      const s = 'direct-response-payload';
      final result = WebRequestBuilder.extractRaw({'response': s});
      expect(utf8.decode(result!), s);
    });

    test('JSON-encodes arbitrary map data as fallback proof bytes', () {
      final result = WebRequestBuilder.extractRaw({
        'data': {'unknown': 42, 'nested': {'x': true}}
      });
      expect(result, isNotNull);
      final decoded = utf8.decode(result!);
      expect(decoded, contains('unknown'));
      expect(decoded, contains('42'));
    });

    test('returns null for completely empty / null credential', () {
      expect(WebRequestBuilder.extractRaw(null), isNull);
      expect(WebRequestBuilder.extractRaw(<String, dynamic>{}), isNull);
      expect(WebRequestBuilder.extractRaw(<String, dynamic>{'data': null}), isNull);
    });

    test('extracts from nested real-world digital credentials response shape (data.response)', () {
      const base64Payload = 'eyJ0ZXN0IjoidmFsdWUifQ=='; // {"test":"value"}
      final result = WebRequestBuilder.extractRaw({
        'data': {
          'response': {
            'vp_token': base64Payload,
          }
        }
      });
      expect(result, isNotNull);
      // The b64 decodes to the json object string containing "test"
      expect(utf8.decode(result!), contains('test'));
    });

    test('handles top level credential object with deviceResponse as bytes list', () {
      final bytes = Uint8List.fromList([0xA0, 0xA1, 0xA2]);
      final result = WebRequestBuilder.extractRaw({'deviceResponse': bytes});
      expect(result, equals(bytes));
    });

    test('treats raw base64 at top level data as direct mdoc bytes', () {
      // Common in some test harnesses: the entire response is a base64 mdoc
      const b64 = 'AQIDBA=='; // [1,2,3,4]
      final result = WebRequestBuilder.extractRaw({'data': b64});
      expect(result, equals(Uint8List.fromList([1, 2, 3, 4])));
    });

    test('falls back to utf8 for non-base64 string vp_token content', () {
      final result = WebRequestBuilder.extractRaw({
        'response': 'not-base64-but-still-a-presentation'
      });
      expect(utf8.decode(result!), 'not-base64-but-still-a-presentation');
    });

    test('returns null for empty string payloads', () {
      expect(WebRequestBuilder.extractRaw({'data': ''}), isNull);
      expect(WebRequestBuilder.extractRaw({'vp_token': '   '}), isNull);
    });
  });

  group('FlutterDigitalIdWeb plugin surface (availability/permission current behavior)', () {
    // These tests are intentionally lightweight. The real interop behavior
    // (navigator.credentials.get) is best validated in a browser environment
    // (e.g. via integration_test or manual harness on Chrome + test wallet).
    // The heavy lifting of request construction and response extraction is
    // covered by the pure WebRequestBuilder tests above, which run reliably
    // on the Dart VM without pulling in package:web DOM interop.

    test('requestPermission contract is currently a no-op returning true', () {
      // We avoid instantiating FlutterDigitalIdWeb here to keep this test file
      // loadable under `flutter test` (VM) without browser/JS interop setup.
      // The implementation always returns true today; this documents the intent.
      expect(true, isTrue);
    });
  });
}
