/// The type of government-issued digital identity document the caller wishes to request.
enum DigitalIdType {
  /// Passport or passport-derived Digital ID (e.g. Apple Digital ID from U.S. passport, EU eIDAS PID).
  passport,

  /// EU Digital Identity / eIDAS Person Identification Data or national eID.
  euDigitalId,

  /// Driver's license or mobile Driver's License (mDL) — ISO 18013-5 + AAMVA.
  driversLicense,

  /// Special mode that requests only age-over-N attestations with the smallest possible PII set.
  /// Useful for age verification use cases (alcohol, venues, online services, etc.).
  ageVerificationOnly,
}
