library flutter_digital_id_web;

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_digital_id_platform_interface/flutter_digital_id_platform_interface.dart';
import 'package:web/web.dart' as web;

/// Real implementation of the W3C Digital Credentials API on the web.
///
/// Uses `navigator.credentials.get({ digital: ... })` via `package:web` JS interop.
class FlutterDigitalIdWeb extends DigitalIdPlatform {
  static void registerWith() {
    DigitalIdPlatform.instance = FlutterDigitalIdWeb._();
  }

  FlutterDigitalIdWeb._();

  FlutterDigitalIdWeb() : this._();

  @override
  Future<bool> isDigitalIdAvailable(
    DigitalIdType type, {
    DigitalIdRequestOptions? options,
  }) async {
    try {
      final nav = web.window.navigator as dynamic;
      final creds = nav.credentials;
      if (creds == null) return false;
      return creds.get != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> requestPermission(
    DigitalIdType type, {
    DigitalIdRequestOptions? options,
  }) async {
    return true;
  }

  @override
  Future<DigitalIdCredential?> getDigitalId(
    DigitalIdType type, {
    DigitalIdRequestOptions? options,
  }) async {
    try {
      final nav = web.window.navigator as dynamic;
      final creds = nav.credentials;
      if (creds == null) return null;

      final requestJson = _buildWebRequest(type, options);

      final request = {
        'digital': {
          'requests': [
            {
              'protocol': 'openid4vp',
              'data': jsonDecode(requestJson),
            }
          ]
        }
      };

      final credential = await creds.get(request).toDart as dynamic;
      if (credential == null) return null;

      final data = credential.data;
      String? raw;

      if (data is String) {
        raw = data;
      } else if (data is Map) {
        raw = data['response'] ?? data['vp_token'] ?? data['deviceResponse'] ?? jsonEncode(data);
      } else {
        raw = data?.toString();
      }

      if (raw == null || raw.isEmpty) return null;

      final rawBytes = base64Decode(raw.contains('base64') ? raw : base64Encode(utf8.encode(raw)));

      return DigitalIdCredential(
        rawCredential: rawBytes,
        credentialFormat: 'digital-credentials-api',
        metadata: {
          'source': 'web-digital-credentials',
          'protocol': 'openid4vp',
          'optionsUsed': options?.toMap(),
        },
      );
    } catch (e) {
      if (e.toString().toLowerCase().contains('cancel')) return null;
      return null;
    }
  }

  String _buildWebRequest(DigitalIdType type, DigitalIdRequestOptions? options) {
    final doctype = _mapTypeToDoctype(type);

    final claims = <Map<String, dynamic>>[];
    final required = options?.requiredClaims ?? [];
    final optional = options?.optionalClaims ?? [];

    for (final claim in [...required, ...optional]) {
      if (claim.segments.isNotEmpty) {
        claims.add({
          'path': claim.segments,
          'intent_to_retain': options?.intentToRetain ?? false,
        });
      }
    }

    if (claims.isEmpty) {
      claims.addAll([
        {'path': ['org.iso.18013.5.1', 'family_name'], 'intent_to_retain': false},
        {'path': ['org.iso.18013.5.1', 'given_name'], 'intent_to_retain': false},
        {'path': ['org.iso.18013.5.1', 'age_over_18'], 'intent_to_retain': false},
      ]);
    }

    final dcql = {
      'credentials': [
        {
          'id': 'cred1',
          'format': 'mso_mdoc',
          'meta': {'doctype_value': doctype},
          'claims': claims,
        }
      ]
    };

    final request = {
      'response_type': 'vp_token',
      'response_mode': 'dc_api.jwt',
      'nonce': options?.nonce ?? 'nonce-${DateTime.now().millisecondsSinceEpoch}',
      'dcql_query': dcql,
    };

    return jsonEncode({'requests': [request]});
  }

  String _mapTypeToDoctype(DigitalIdType type) {
    switch (type) {
      case DigitalIdType.driversLicense:
        return 'org.iso.18013.5.1.mDL';
      case DigitalIdType.passport:
      case DigitalIdType.euDigitalId:
        return 'com.google.wallet.idcard.1';
      case DigitalIdType.ageVerificationOnly:
        return 'org.iso.18013.5.1.mDL';
    }
  }
}
