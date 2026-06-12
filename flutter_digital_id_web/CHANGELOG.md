# Changelog

All notable changes to `flutter_digital_id_web` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025

### Added
- Initial Web implementation targeting the W3C Digital Credentials API (`navigator.credentials.get({ digital: ... })`).
- Pure-Dart `WebRequestBuilder` for DCQL/OpenID4VP request construction and defensive raw response extraction (covers `data`, `response`, `vp_token`, `deviceResponse`, base64, map fallbacks, etc.).
- Full `getDigitalId` interop implementation using `package:web`.
- `isDigitalIdAvailable` basic feature detection.
- `requestPermission` no-op (consent is one-shot).

### Changed / Strengthened
- Response extraction hardened with additional real-world response shape coverage (nested objects, list bytes, direct base64, non-base64 strings).
- Stronger error surface: user/abort cancels return `null` per contract; other interop failures now throw `DigitalIdException` (requestFailed) instead of silently collapsing. Improves debuggability for browser/wallet matrix testing.
- Updated docs to reflect implemented (not stub) interop path.
- Fixed web plugin registration for compatibility with Flutter's generated web plugin registrant (now accepts optional `Registrar?` while preserving `dartPluginClass` support). This allows `flutter build web` and running the test harness on the web for actual browser interoperability testing.

### Notes
- Web support targets the emerging W3C Digital Credentials API. The client implementation is complete (hardened extraction, expanded tests, stronger errors, web build support). Real matrix validation against shipping browser + wallet combinations remains environment-specific.
- Requires secure context.
- The builder/extractor logic is unit-testable on VM; full navigator interop is validated via `flutter run -d chrome` (test_harness now web-enabled).
