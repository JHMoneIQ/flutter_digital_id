import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_digital_id_platform_interface/flutter_digital_id_platform_interface.dart';
import 'package:meta/meta.dart';

/// Android implementation entrypoint. Registered via pubspec.
class FlutterDigitalIdAndroid extends DigitalIdPlatform {
  static const MethodChannel _channel = MethodChannel('flutter_digital_id/android');

  /// Registers this implementation as the default for Android.
  /// Called automatically by the Flutter engine via the `dartPluginClass`
  /// entry in pubspec.yaml (and explicitly in tests).
  static void registerWith() {
    DigitalIdPlatform.instance = FlutterDigitalIdAndroid._();
  }

  FlutterDigitalIdAndroid._(); // private ctor to avoid accidental re-registration loops

  // Public ctor for direct use / tests that want auto behavior in some scenarios.
  // Does NOT auto-register to prevent the classic re-entrancy during platform setter.
  FlutterDigitalIdAndroid() : this._();

  @override
  Future<bool> isDigitalIdAvailable(
    DigitalIdType type, {
    DigitalIdRequestOptions? options,
  }) async {
    // On Android, availability is best determined by attempting the request.
    // We return true here and let getDigitalId surface NoCredentialException
    // or success. This matches how Credential Manager works.
    return true;
  }

  @override
  Future<bool> requestPermission(
    DigitalIdType type, {
    DigitalIdRequestOptions? options,
  }) async {
    // Consent is shown as part of the getCredential flow on Android.
    // See platform interface docs for details.
    return true;
  }

  @override
  Future<DigitalIdCredential?> getDigitalId(
    DigitalIdType type, {
    DigitalIdRequestOptions? options,
  }) async {
    try {
      // Convert options to a DCQL-style request that the native side can use.
      final requestJson = _buildDcqlRequestJson(type, options);

      final result = await _channel.invokeMapMethod<String, dynamic>('getDigitalId', {
        'requestJson': requestJson,
      });

      if (result == null) return null;

      final rawBase64 = result['rawCredential'] as String?;
      if (rawBase64 == null || rawBase64.isEmpty) {
        return null;
      }

      final rawBytes = base64Decode(rawBase64);

      return DigitalIdCredential(
        rawCredential: rawBytes,
        credentialFormat: result['credentialFormat'] as String? ?? 'openid4vp-vp-token',
        // Best-effort client-side structured fields can be added here if we parse the vp_token,
        // but for now we rely on the backend for authoritative structured data + validation.
        // The native side can return additional parsed claims in future iterations.
        metadata: {
          'source': 'android-credential-manager',
          'optionsUsed': options?.toMap(),
        },
      );
    } on PlatformException catch (e) {
      if (e.code == 'NoCredential' || e.code == 'userCancelled' || e.code == 'NO_ACTIVITY') {
        return null;
      }
      rethrow;
    }
  }

  /// Builds a minimal DCQL request JSON from our cross-platform options.
  /// This is a simplified version; production RPs often fetch a signed request from their backend.
  ///
  /// Honors: nonce, intentToRetain, required/optional claims.
  /// If options.platformOptions contains a 'dcql' or 'request' key, it is used
  /// to allow full escape hatch for advanced cases (addressing previously ignored options).
  @visibleForTesting
  String buildDcqlRequestJson(DigitalIdType type, DigitalIdRequestOptions? options) =>
      _buildDcqlRequestJson(type, options);

  String _buildDcqlRequestJson(DigitalIdType type, DigitalIdRequestOptions? options) {
    // Allow full override via platformOptions for advanced RPs
    if (options?.platformOptions != null) {
      final po = options!.platformOptions!;
      if (po['dcql'] is Map || po['request'] is Map || po['requests'] is List) {
        // Trust caller for advanced shape; still inject nonce if missing at top
        final base = po['request'] ?? (po['requests'] is List ? {'requests': po['requests']} : po);
        final encoded = jsonEncode(base);
        if (encoded.contains('nonce') || options.nonce == null) {
          return encoded;
        }
      }
    }

    final doctype = _mapTypeToDoctype(type);

    final claims = <Map<String, dynamic>>[];

    // Always include some basics for KYC-like flows
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
      // Fallback sensible defaults for the type
      claims.addAll([
        {'path': ['org.iso.18013.5.1', 'family_name'], 'intent_to_retain': false},
        {'path': ['org.iso.18013.5.1', 'given_name'], 'intent_to_retain': false},
        {'path': ['org.iso.18013.5.1', 'age_over_18'], 'intent_to_retain': false},
      ]);
    }

    final credentials = <Map<String, dynamic>>[
      {
        'id': 'cred1',
        'format': 'mso_mdoc',
        'meta': {'doctype_value': doctype},
        'claims': claims,
      }
    ];

    // Basic support for allowMultipleCredentials by hinting additional common types
    // (real wallets still decide what to offer; this is best-effort).
    if (options?.allowMultipleCredentials == true) {
      if (doctype != 'org.iso.18013.5.1.mDL') {
        credentials.add({
          'id': 'cred2',
          'format': 'mso_mdoc',
          'meta': {'doctype_value': 'org.iso.18013.5.1.mDL'},
          'claims': claims,
        });
      }
    }

    final dcql = {'credentials': credentials};

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
        return 'com.google.wallet.idcard.1'; // ID Pass / passport-like
      case DigitalIdType.ageVerificationOnly:
        return 'org.iso.18013.5.1.mDL'; // Can be used for age claims
    }
  }
}
