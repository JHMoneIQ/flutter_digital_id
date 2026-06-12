import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_digital_id_platform_interface/flutter_digital_id_platform_interface.dart';

/// Pure Dart logic for building DCQL-style requests and extracting raw credential
/// bytes from Web Digital Credentials API responses.
///
/// This file has **no** dependency on `package:web` or DOM interop so it can be
/// unit tested with the Dart VM (`flutter test` / `dart test`) without requiring
/// a browser or JS runtime.
///
/// The actual `FlutterDigitalIdWeb` plugin imports and delegates to these helpers
/// while adding the thin JS interop layer on top.
class WebRequestBuilder {
  /// Builds the inner request JSON (the value that goes inside `data` for an
  /// `openid4vp` protocol request in the Digital Credentials API).
  ///
  /// The surrounding wrapper `{"requests": [ ... ]}` is also produced here for
  /// convenience (matches what the current interop path sends).
  static String buildRequest(DigitalIdType type, DigitalIdRequestOptions? options) {
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

  /// Given whatever object the Credentials.get() promise resolved to, attempt to
  /// pull out a Uint8List that represents the raw presentation / vp_token / mdoc bytes.
  ///
  /// This is intentionally defensive and heuristic because real browser + wallet
  /// implementations are still evolving.
  ///
  /// The method accepts both:
  /// - JS interop objects with dynamic `.data`, `.response` etc. properties (real path)
  /// - Plain Dart Maps (for unit tests and some fallback serialization paths)
  static Uint8List? extractRaw(dynamic credential) {
    if (credential == null) return null;

    dynamic data;

    // Prefer map access first (covers test data and some deserialized shapes)
    if (credential is Map) {
      data = credential['data'] ??
          credential['response'] ??
          credential['vp_token'] ??
          credential['deviceResponse'] ??
          credential['vpToken'];
    } else {
      // Dynamic property access for real JS interop objects from package:web
      try {
        // ignore: avoid_dynamic_calls
        data = credential.data;
      } catch (_) {}
      if (data == null) {
        try {
          // ignore: avoid_dynamic_calls
          data = credential.response ?? credential.vp_token ?? credential.deviceResponse;
        } catch (_) {}
      }
    }

    if (data == null) {
      // Last resort stringify for unknown interop objects.
      // But: an empty plain map or a map whose only keys point to null/empty
      // (e.g. {'data': null}) should yield null for "no credential".
      if (credential is Map) {
        final m = credential;
        if (m.isEmpty) return null;
        final hasAnyPayload = m.values.any((v) => v != null && v.toString().trim().isNotEmpty);
        if (!hasAnyPayload) return null;
      }
      try {
        final s = credential.toString();
        if (s.isNotEmpty && s != '[object Object]' && s != '{}') {
          data = s;
        }
      } catch (_) {}
    }

    if (data == null) return null;

    if (data is Uint8List) return data;
    if (data is List<int>) return Uint8List.fromList(data);

    if (data is String) {
      final s = data.trim();
      if (s.isEmpty) return null;

      if (_looksLikeBase64(s)) {
        try {
          return base64Decode(s);
        } catch (_) {}
      }
      return Uint8List.fromList(utf8.encode(s));
    }

    if (data is Map) {
      final m = data;
      var candidate = m['response'] ?? m['vp_token'] ?? m['deviceResponse'] ?? m['vpToken'];
      if (candidate is Map) {
        // Drill one level for common nested shapes: { response: { vp_token: '...' } }
        candidate = candidate['response'] ?? candidate['vp_token'] ?? candidate['deviceResponse'] ?? candidate['vpToken'] ?? candidate;
      }
      if (candidate is String) {
        final s = candidate.trim();
        if (_looksLikeBase64(s)) {
          try {
            return base64Decode(s);
          } catch (_) {}
        }
        return Uint8List.fromList(utf8.encode(s));
      }
      if (candidate is Uint8List) return candidate;
      if (candidate is List<int>) return Uint8List.fromList(candidate);

      // If we ended up with a map (after possible drill), try to stringify a useful payload or the map
      if (candidate is Map) {
        final inner = candidate['response'] ?? candidate['vp_token'] ?? candidate['deviceResponse'] ?? candidate;
        if (inner is String) {
          final s = inner.trim();
          if (_looksLikeBase64(s)) {
            try { return base64Decode(s); } catch (_) {}
          }
          return Uint8List.fromList(utf8.encode(s));
        }
        if (inner is Uint8List) return inner;
        if (inner is List<int>) return Uint8List.fromList(inner);
        return Uint8List.fromList(utf8.encode(jsonEncode(inner)));
      }

      return Uint8List.fromList(utf8.encode(jsonEncode(m)));
    }

    try {
      final s = data.toString();
      if (s.isNotEmpty && s != '[object Object]') {
        return Uint8List.fromList(utf8.encode(s));
      }
    } catch (_) {}
    return null;
  }

  static bool _looksLikeBase64(String s) {
    if (s.length < 8) return false;
    if (s.contains(' ') || s.contains('\n')) return false;
    final base64Like = RegExp(r'^[A-Za-z0-9+/]+=*$');
    return base64Like.hasMatch(s);
  }

  static String _mapTypeToDoctype(DigitalIdType type) {
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

// No extension here to avoid pulling FlutterDigitalIdWeb (which depends on package:web)
// into pure test / VM contexts. Consumers that need the old test surface can call
// WebRequestBuilder directly or the main plugin can expose thin forwarding methods.
