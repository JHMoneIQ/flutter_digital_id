import 'dart:convert';

import 'claim_path.dart';

/// Controls what data is requested from a digital identity document.
///
/// This enables selective disclosure: the caller can specify exactly which
/// claims are required (must be returned or the user cannot approve) versus
/// optional (the wallet/user may omit them).
///
/// The same options object works across iOS (PassKit descriptors), Android/Web
/// (OpenID4VP / DCQL), and the C# companion.
class DigitalIdRequestOptions {
  const DigitalIdRequestOptions({
    this.requiredClaims = const [],
    this.optionalClaims = const [],
    this.intentToRetain = false,
    this.nonce,
    this.allowMultipleCredentials = false,
    this.platformOptions,
  });

  /// Claims that must be present in the response. The user will not be able
  /// to approve the request unless all of these can be provided.
  ///
  /// Example (mdoc path style):
  /// ```dart
  /// ClaimPath(['org.iso.18013.5.1', 'family_name'])
  /// ```
  final List<ClaimPath> requiredClaims;

  /// Claims the caller would like but that are not mandatory for approval.
  final List<ClaimPath> optionalClaims;

  /// When true, the wallet should retain the disclosed values (subject to
  /// local privacy rules). Most privacy-respecting flows set this to false.
  final bool intentToRetain;

  /// Optional nonce for replay protection / binding to a specific session.
  final String? nonce;

  /// If true, the user may be offered multiple matching credentials (e.g.
  /// passport vs. driver's license) and can choose which one to present.
  ///
  /// NOTE: Currently passed through to native layers but full support depends
  /// on the platform implementation (Android DCQL can express this; iOS PassKit
  /// behavior depends on the entitlement + descriptors).
  final bool allowMultipleCredentials;

  /// Platform-specific escape hatch for advanced use cases (raw DCQL JSON,
  /// custom Apple descriptor tweaks, etc.). Use with caution — prefer the
  /// cross-platform fields above when possible.
  final Map<String, dynamic>? platformOptions;

  @override
  String toString() =>
      'DigitalIdRequestOptions(required: $requiredClaims, optional: $optionalClaims, retain: $intentToRetain)';

  /// Hand-coded serialization (no code generation).
  Map<String, dynamic> toMap() => {
        'requiredClaims': requiredClaims.map((e) => e.toMap()).toList(),
        'optionalClaims': optionalClaims.map((e) => e.toMap()).toList(),
        'intentToRetain': intentToRetain,
        'nonce': nonce,
        'allowMultipleCredentials': allowMultipleCredentials,
        'platformOptions': platformOptions,
      };

  factory DigitalIdRequestOptions.fromMap(Map<String, dynamic> map) {
    return DigitalIdRequestOptions(
      requiredClaims: (map['requiredClaims'] as List? ?? [])
          .map((e) => ClaimPath.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      optionalClaims: (map['optionalClaims'] as List? ?? [])
          .map((e) => ClaimPath.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      intentToRetain: map['intentToRetain'] as bool? ?? false,
      nonce: map['nonce'] as String?,
      allowMultipleCredentials: map['allowMultipleCredentials'] as bool? ?? false,
      platformOptions: map['platformOptions'] != null
          ? Map<String, dynamic>.from(map['platformOptions'] as Map)
          : null,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory DigitalIdRequestOptions.fromJson(String source) =>
      DigitalIdRequestOptions.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
