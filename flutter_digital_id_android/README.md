# flutter_digital_id_android

Android implementation of `flutter_digital_id` using the Credential Manager + Digital Credentials API.

## What it does

- Receives a DCQL-style request JSON from the Dart side.
- Calls `CredentialManager.getCredential(...)` with a `GetDigitalCredentialOption`.
- Maps successful `DigitalCredential` responses (looking for `response` / `vp_token`) into a `rawCredential` (base64) + `credentialFormat`.
- Surfaces cancellation and no-credential cases as structured errors the Dart layer can turn into `null` returns or exceptions.

## Requirements

- Android 14+ (or earlier with Credential Manager updates via Google Play services).
- A wallet / credential provider that supports the Digital Credentials API (e.g. Google Wallet in supported regions, or test harnesses such as CMWallet).

## For production

Register as a Relying Party with Google Wallet / Android Identity credentials as appropriate for your use case. The bytes returned by this plugin are intended to be forwarded to a backend (e.g. `DigitalId.Net`) for cryptographic validation before any trust decision.

## Notes

This package is not meant to be used directly by apps. Depend on `flutter_digital_id` instead.
