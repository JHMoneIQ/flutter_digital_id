import 'package:flutter_digital_id_platform_interface/flutter_digital_id_platform_interface.dart';

/// High-level, ergonomic API for requesting digital identity documents.
///
/// This is the class most application developers will use.
///
/// Example (bank KYC / signup flow):
/// ```dart
/// final credential = await DigitalId.instance.verifyWithPassport(
///   options: DigitalIdRequestOptions(
///     requiredClaims: [ClaimPath.familyName(), ClaimPath.givenName(), ClaimPath.nationality()],
///   ),
/// );
///
/// if (credential != null) {
///   // 1. Pre-fill form immediately using the structured fields
///   nameController.text = credential.fullName ?? '';
///   // ...
///
///   // 2. Send both the structured values and the raw proof to your backend
///   await myKycService.submit(credential);
/// }
/// ```
class DigitalId {
  DigitalId._();

  static final DigitalId instance = DigitalId._();

  DigitalIdPlatform get _platform => DigitalIdPlatform.instance;

  Future<bool> isAvailable(
    DigitalIdType type, {
    DigitalIdRequestOptions? options,
  }) =>
      _platform.isDigitalIdAvailable(type, options: options);

  Future<bool> requestPermission(
    DigitalIdType type, {
    DigitalIdRequestOptions? options,
  }) =>
      _platform.requestPermission(type, options: options);

  Future<DigitalIdCredential?> getDigitalId(
    DigitalIdType type, {
    DigitalIdRequestOptions? options,
  }) =>
      _platform.getDigitalId(type, options: options);

  // Convenience helpers for the most common KYC / age-verification flows
  Future<DigitalIdCredential?> verifyWithPassport({
    DigitalIdRequestOptions? options,
  }) =>
      getDigitalId(DigitalIdType.passport, options: options);

  Future<DigitalIdCredential?> verifyWithDriversLicense({
    DigitalIdRequestOptions? options,
  }) =>
      getDigitalId(DigitalIdType.driversLicense, options: options);

  Future<DigitalIdCredential?> verifyWithEuDigitalId({
    DigitalIdRequestOptions? options,
  }) =>
      getDigitalId(DigitalIdType.euDigitalId, options: options);

  /// Pure age verification with the smallest possible data disclosure.
  ///
  /// Honors [minimumAge] by selecting the appropriate age_over_NN claim
  /// (supports dynamic thresholds via ClaimPath.ageOver()).
  Future<DigitalIdCredential?> verifyAge({int minimumAge = 18}) {
    final options = DigitalIdRequestOptions(
      requiredClaims: [ClaimPath.ageOver(minimumAge)],
    );
    return getDigitalId(DigitalIdType.ageVerificationOnly, options: options);
  }
}
