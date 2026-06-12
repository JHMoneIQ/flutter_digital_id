# Changelog

All notable changes to `flutter_digital_id_darwin` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025

### Added
- iOS implementation using the documented PassKit Verify with Wallet APIs:
  - `PKIdentityAuthorizationController`
  - `PKIdentityRequest` + typed descriptors (`PKIdentityDriversLicenseDescriptor`, `PKIdentityNationalIDCardDescriptor`, `PKIdentityPhotoIDDescriptor` for iOS 26+).
- Claim path to `PKIdentityElement` mapping for common KYC elements (name, DOB, portrait, address, document fields, age thresholds, sex, eye/hair color, height/weight, organ donor, etc.).
- Merchant identifier resolution via `platformOptions` or `Info.plist` key `DigitalIdMerchantIdentifier`.
- Nonce handling.
- Proper error mapping (userCancelled, NOT_ENTITLED, REQUEST_FAILED, PLATFORM_UNSUPPORTED).
- macOS returns clear "unsupported" errors (no silent false).
- Simulator profile testing path documented (Wallet developer profile + sample data).

### Notes
- Uses the documented PassKit Verify with Wallet production APIs (no speculative dynamic calls).
- iOS 16+ (drivers license/age), iOS 18+ (EU national ID), iOS 26+ (passport/photo ID) availability gates are enforced in code.
- Requires Apple "In-App Identity Presentment" entitlement + merchant configuration for real use. The library correctly surfaces `NOT_ENTITLED` errors.
- Simulator path (developer profile + sample data) allows exercising the consent + encrypted response flow.
- Returns `credentialFormat: "apple-encrypted"` with `rawCredential` containing the encrypted blob for server-side decryption (DigitalId.Net AppleResponseDecryptor recommended).
- The repo provides the complete client implementation; full entitled-app + server-decrypt validation is performed by integrating apps.
