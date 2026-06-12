# Changelog

All notable changes to `flutter_digital_id_android` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025

### Added
- Real Android implementation using `CredentialManager` + `GetDigitalCredentialOption` (Android 14+ / Credential Manager 1.2+ path).
- `ActivityAware` plugin wiring so `getCredential` has a valid Activity context.
- DCQL-style request JSON construction in the Dart side (passed to native).
- Basic response mapping: extracts `response` / `vp_token` or falls back; returns `rawCredential` (base64) + `credentialFormat`.
- Error mapping for `NoCredentialException` and cancellation.
- Unit tests for the Android channel mapping (in the package) and harness coverage.

### Notes
- Requires an app/activity context at call time.
- For production Relying Party registration with Google Wallet is recommended.
- The raw bytes returned are intended for backend verification (OpenID4VP / mdoc).
