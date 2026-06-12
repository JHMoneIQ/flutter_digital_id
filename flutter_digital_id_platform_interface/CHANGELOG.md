# Changelog

All notable changes to `flutter_digital_id_platform_interface` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025

### Added
- Core data models with hand-coded `toMap`/`fromMap` + `toJson`/`fromJson` (no code generation):
  - `DigitalIdCredential` — rich structured fields + `rawCredential` + `credentialFormat` for backend verification.
  - `DigitalIdRequestOptions` — selective disclosure control.
  - `ClaimPath` — with factory helpers (`familyName()`, `givenName()`, `ageOver18()`, `ageOver()`, `portrait()`, etc.) and equality.
  - `DigitalIdType` (passport, driversLicense, euDigitalId, ageVerificationOnly).
  - `DigitalIdException` (reserved for future typed errors).
- `DigitalIdPlatform` abstract interface + stub.
- Comprehensive golden vector tests for serialization roundtrips (rich passport, minimal, error cases, ClaimPath equality).
- `verifyAge(minimumAge)` semantics honored in options building (via the main facade).

### Notes
- Hand-coded serialization is the source of truth for Dart <-> .NET / backend parity.
- All publishable Flutter packages must stay in version lockstep with this package.
- Added `requestFailed` error code to support better surfacing of transient/interop failures (used by Web implementation).
