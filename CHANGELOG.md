# Changelog (Repository)

This is the high-level changelog for the `flutter_digital_id` monorepo (Flutter federated plugin + DigitalId.Net companion).

See the per-package `CHANGELOG.md` files for detailed package-specific notes:

- `flutter_digital_id/CHANGELOG.md`
- `flutter_digital_id_platform_interface/CHANGELOG.md`
- `flutter_digital_id_android/CHANGELOG.md`
- `flutter_digital_id_darwin/CHANGELOG.md`
- `flutter_digital_id_web/CHANGELOG.md`
- `DigitalId.Net/CHANGELOG.md`

## 2025 - Initial public developer preview + production posture completion

- Core models + hand-coded serialization with Dart / .NET parity.
- Android: real Credential Manager implementation.
- iOS: typed PassKit Verify with Wallet implementation using public PKIdentity* APIs (simulator profile path exercised; complete entitlements + Info.plist templates provided).
- Web: W3C Digital Credentials API interop with hardened request builder + response extraction (many shapes covered, stronger errors, registration fixed to enable real `flutter build web`).
- `DigitalId.Net`: full verification stack (MSO digests, COSE, Apple response decryption) + golden vectors + attack matrix tests.
- Test harness with widget + integration coverage; now supports web builds for Digital Credentials API testing.
- Comprehensive usage-focused documentation (root README is now strictly library usage instructions for developers).
- Packaging and hygiene: darwin podspecs repaired, proper root .gitignore added (Flutter + .NET + security), removal of stray private key material, dry-run automation in CI.
- All "release posture" and preview hedging language removed from user-facing docs; focus is on how to use the library.

The client libraries and test harness are complete for use. Real Apple production requires standard entitlement approval. Web requires browser + wallet support for the emerging API. Backend verification of `rawCredential` is mandatory (use DigitalId.Net or equivalent). See the root README for usage.
