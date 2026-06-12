# Changelog

All notable changes to `flutter_digital_id` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025

### Added
- Federated Flutter plugin entry point with convenient high-level API (`DigitalId.instance`).
- Convenience methods: `verifyWithPassport`, `verifyWithDriversLicense`, `verifyWithEuDigitalId`, `verifyAge(minimumAge)`.
- Full support for `DigitalIdRequestOptions` (required/optional claims, intentToRetain, nonce, platformOptions, allowMultipleCredentials).
- Platform interface registration for Android, iOS/macOS (darwin), and Web.
- Test vector mode support for UI/backend development without native entitlements.

### Changed
- Delegates all calls to the platform interface implementation.

### Notes
- This package has no native code of its own. Real behavior depends on the platform packages.
- See `flutter_digital_id_platform_interface` for the shared models and serialization contract.
- iOS support requires Apple "Verify with Wallet" entitlement (see README). The darwin implementation is the production client path.
- Web support targets the emerging standard (client interop implemented + hardened with expanded shape coverage, error surfacing, and registration fix to enable web builds; see flutter_digital_id_web changelog).
