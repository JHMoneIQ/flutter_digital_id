import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_digital_id_platform_interface/flutter_digital_id_platform_interface.dart';

/// Golden test vectors (seeds) used for unit testing the data models and
/// serialization without requiring real hardware or wallets.
///
/// These represent realistic responses from different platforms.
class DigitalIdTestVectors {
  /// Minimal successful response (common for age verification flows).
  static final minimalAgeVerification = DigitalIdCredential(
    ageOver18: true,
    ageOver21: true,
    rawCredential: base64Decode('dGVzdC1yYXctcHJvb2YtYnl0ZXM='), // "test-raw-proof-bytes" base64
    credentialFormat: 'mdoc-device-response',
    metadata: {'testVector': 'minimal-age'},
  );

  /// Rich passport response (what a bank KYC flow would typically want).
  static final richPassport = DigitalIdCredential(
    givenName: 'Jane',
    familyName: 'Doe',
    fullName: 'Jane A. Doe',
    dateOfBirth: DateTime(1990, 5, 15),
    ageOver18: true,
    ageOver21: true,
    nationality: 'US',
    placeOfBirth: 'New York, NY, USA',
    documentNumber: 'A12345678',
    documentType: 'passport',
    issuingAuthority: 'US Department of State',
    issuingCountry: 'US',
    issueDate: DateTime(2020, 1, 10),
    expirationDate: DateTime(2030, 1, 10),
    rawCredential: base64Decode('dGVzdC1hcHBsZS1lbmNyeXB0ZWQtYmxvYg=='),
    credentialFormat: 'apple-encrypted',
    metadata: {
      'issuer': 'us-passport-issuer',
      'testVector': 'rich-passport',
    },
  );

  /// Response with portrait (useful for visual verification flows).
  static final withPortrait = DigitalIdCredential(
    givenName: 'John',
    familyName: 'Smith',
    portrait: Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]), // fake JPEG header
    rawCredential: Uint8List.fromList([1, 2, 3, 4]),
    credentialFormat: 'mdoc-device-response',
  );

  /// User cancellation case (represented as null from getDigitalId).
  static const userCancelled = null;

  /// Error case seed.
  static final notEntitledError = DigitalIdException(
    code: DigitalIdErrorCode.notEntitled,
    message: 'App is not entitled for this document type. Request entitlement from Apple.',
  );

  /// Simulates a response from iOS PassKit (encrypted blob + limited metadata).
  /// In real usage, the rawCredential must be sent to your backend for decryption.
  static final iosEncryptedPassport = DigitalIdCredential(
    rawCredential: base64Decode('dGVzdC1hcHBsZS1lbmNyeXB0ZWQtYmxvYi1mb3Itc2ltdWxhdG9y'),
    credentialFormat: 'apple-encrypted',
    disclosedClaimPaths: [
      'givenName',
      'familyName',
      'portrait',
      'documentNumber',
    ],
    metadata: {
      'source': 'ios-passkit-simulator',
      'note': 'Most structured data comes from server-side decryption of rawCredential',
    },
  );

  /// Simulates a successful Android response (vp_token style with raw proof).
  static final androidMdlSuccess = DigitalIdCredential(
    givenName: 'John',
    familyName: 'Smith',
    ageOver18: true,
    state: 'CA',
    rawCredential: base64Decode('YW5kcm9pZC12cC10b2tlbi1wcm9vZg=='),
    credentialFormat: 'openid4vp-vp-token',
    metadata: {
      'source': 'android-credential-manager',
      'doctype': 'org.iso.18013.5.1.mDL',
    },
  );

  /// Simulates a Web Digital Credentials API response.
  static final webDigitalCredentialsSuccess = DigitalIdCredential(
    givenName: 'Alex',
    familyName: 'Rivera',
    nationality: 'US',
    rawCredential: base64Decode('d2ViLWRpZ2l0YWwtY3JlZGVudGlhbHMtcmF3'),
    credentialFormat: 'digital-credentials-api',
    metadata: {
      'source': 'web-digital-credentials-api',
      'protocol': 'openid4vp-v1-unsigned',
    },
  );

  /// Negative case: No credential available (common Android/Web error path).
  static final noCredentialError = DigitalIdException(
    code: DigitalIdErrorCode.noCredential,
    message: 'No matching digital ID found in any wallet.',
  );
}
