# flutter_digital_id

Flutter plugin for requesting digital identity documents (passports, EU Digital Identity / PID, driver's licenses / mDL) directly from the user's native wallet using the platform's secure APIs.

**Primary use case:** Frictionless KYC and signup flows (e.g. opening a bank account) by having the user present a government-issued digital ID in one consent flow.

The plugin returns a `DigitalIdCredential` containing:

- Rich **structured fields** (name, address, DOB, age flags, portrait, etc.) that your frontend can immediately use to pre-fill forms.
- The **raw cryptographic proof** (encrypted blob on iOS, mdoc / vp_token on Android/Web) that your backend **must** validate before trusting any data or creating an account.

## Supported Platforms (Implementation Status)

**IMPORTANT: The public Dart API and data model are in good shape, but native wallet support is still uneven. Current status:**

- **iOS** — **Experimental scaffold**. The Darwin package now uses the documented PassKit types (`PKIdentityAuthorizationController`, `PKIdentityRequest`, `PKIdentityDriversLicenseDescriptor`, etc.) instead of speculative selector-based calls. It is intended to support simulator/device testing once your Apple entitlement, merchant ID, and `NSIdentityUsageDescription` are configured. This path still needs real-world validation against an entitled app.
- **Android** — **Implemented via Credential Manager**. The plugin uses an `ActivityAware` Kotlin implementation with `CredentialManager.getCredential(...)` and `GetDigitalCredentialOption`. The Dart layer builds the DCQL-style request and the native plugin returns the wallet response payload for backend verification. This still needs real wallet / RP validation in practice, but it is no longer a stub.
- **Web** — **Experimental / stub**. Feature detection exists, but `getDigitalId()` still returns `null`.
- **macOS / Windows / Linux** — Graceful degradation only.

**Bottom line:** You can build and test UI/backend handoff flows today with test vectors. Real native wallet support is still a work in progress.

## Key Features

- Silent availability check (`isDigitalIdAvailable`) — implemented in Dart layer; native behavior depends on platform wiring.
- Selective disclosure via `DigitalIdRequestOptions` (required vs optional claims, `intentToRetain`, `nonce`, `platformOptions` escape hatch).
- Rich structured response model designed for real KYC / signup use cases.
- Minimal dependencies philosophy.
- Hand-coded serialization (no code generation).

## Installation

```yaml
dependencies:
  flutter_digital_id: ^0.1.0
```

## Quick Start

```dart
import 'package:flutter_digital_id/flutter_digital_id.dart';

final credential = await DigitalId.instance.getDigitalId(
  DigitalIdType.passport,
  options: DigitalIdRequestOptions(
    requiredClaims: [
      ClaimPath.familyName(),
      ClaimPath.givenName(),
      ClaimPath.birthDate(),
      ClaimPath.nationality(),
    ],
    optionalClaims: [ClaimPath.portrait()],
  ),
);

if (credential != null) {
  // Use structured fields immediately in your UI
  nameController.text = credential.fullName ?? '';
  // ...

  // Send both the structured values AND the raw proof to your backend
  await myKycService.submitDigitalId(credential);
}
```

See the `example/` app for a more complete bank-style signup flow demonstration (including test vector mode).

## iOS Setup (Critical)

iOS requires special entitlements from Apple. This is **not** automatic.

### 1. Request the Entitlement

Go to the [Verify with Wallet entitlement request form](https://developer.apple.com/contact/request/verify-with-wallet/).

You will need to justify your use case (Financial Services, Age Verification, etc. are common approved categories).

### 2. Configure Your App ID and Merchant ID

1. Create a **Merchant ID** (if you don't already have one for Apple Pay).
2. Create an **Identity Access Certificate** for that Merchant ID. Download the certificate and keep the private key secure — this is used by **your server** to decrypt responses.
3. Enable the **"In App Identity Presentment"** capability on your App ID.
4. Add your Merchant ID under the **"In App Identity Presentment Merchant IDs"** capability.

### 3. Add Entitlements to Your App

Create (or merge into) `ios/Runner/Runner.entitlements`:

```xml
<key>com.apple.developer.in-app-identity-presentment</key>
<dict>
  <key>document-types</key>
  <array>
    <string>us-drivers-license</string>
    <string>passport-digital-id</string>
  </array>
  <key>elements</key>
  <array>
    <string>given-name</string>
    <string>family-name</string>
    <string>portrait</string>
    <string>address</string>
    <string>date-of-birth</string>
    <string>document-number</string>
  </array>
</dict>

<key>com.apple.developer.in-app-identity-presentment.merchant-identifiers</key>
<array>
  <string>merchant.com.yourcompany.digitalid</string>
</array>
```

Reference the template in `test_harness/ios/Runner/Runner.entitlements` (or your own app's entitlements file).

### 3.5 Add iOS Usage Text and Merchant Identifier

Your iOS app's `Info.plist` must include an `NSIdentityUsageDescription` string.

If you use the default Darwin scaffold in this repo, it also looks for a custom
`DigitalIdMerchantIdentifier` key in `Info.plist` unless you pass
`platformOptions['merchantIdentifier']` at request time.

### 4. Testing on iOS Simulator (Recommended Starting Point)

1. Install Apple's **"Wallet and Apple mDL Developer Integrator profile"** (available via Feedback Assistant / bug reporting).
2. Download Apple's **sample data and simulator keys** bundle (linked from the [Verify with Wallet documentation](https://developer.apple.com/wallet/get-started-with-verify-with-wallet/)).
3. Run the example on an iOS simulator. It comes with pre-loaded mock identity documents.

The plugin can return mock data carrying simulator/developer-profile signatures,
which is enough to exercise the consent flow and backend handoff.

**Important:** Real production use still requires the entitlement to be granted by Apple and your server to perform decryption + IACA validation. The Flutter plugin should be treated as **experimental on iOS** until you validate it with your own entitled app.

## Android Setup

- Minimum SDK 28.
- For production: Register as a Relying Party with Google Wallet (sandbox available).
- The Android plugin uses `CredentialManager.getCredential(...)` with a real `Activity` context and returns wallet response data when available.
- For production: validate your relying-party registration and wallet compatibility with real credentials.

See the plugin source + Google's "Online Acceptance of Digital Credentials" guide.

## Web Setup

The Web implementation is currently a feature-detection shell around the W3C Digital Credentials API.

- `isDigitalIdAvailable()` does a loose support check.
- `getDigitalId()` currently returns `null`.
- Treat web support as experimental until the JS interop and response mapping are completed.

## Backend Verification (Required)

**Never trust the structured fields alone.**

You must send the `rawCredential` (plus the elements you requested) to your backend. Your backend is responsible for:

- Decrypting (iOS) or validating the presentation (Android/Web mdoc / SD-JWT).
- Verifying the issuer signature using the appropriate IACA / root certificates.
- Checking holder binding, nonce, etc.

Only after successful server-side validation should you treat the data as authoritative and create accounts or store identity documents.

The plugin is deliberately designed so the frontend gets usable structured data quickly, while the security-critical verification always happens on your backend.

## Testing & Development

- Use the "Use test vector" mode in the example for UI development without any native setup.
- For real iOS simulator testing, follow the steps in the "iOS Setup" section above.
- Android: Use Google's sandbox / CMWallet test wallet.
- Web: Use `flutter run -d chrome` (must be secure context) with a supporting wallet.

See `TESTING.md` (if present) or the plugin source for more details on golden test vectors.

## Architecture Notes

- iOS responses are expected to be primarily encrypted. Most structured data for your UI should come from your backend after decryption and verification.
- Android and Web responses (OpenID4VP / mdoc) allow more client-side parsing of disclosed claims while still requiring backend validation of the proof.
- The `DigitalIdCredential` model is designed to work uniformly across all three platforms.

## License

MIT (or BSD-style — see LICENSE file).

## Contributing

Contributions are welcome, especially additional platform support, more element mappings, and improvements to the example / documentation.

---

**Status:** The Dart API, models, serialization, error handling, and test vectors are the strongest part of the codebase. Android now has a real Credential Manager integration, Web is still stubbed, and iOS now has a documented typed PassKit scaffold that should still be considered experimental until validated against a real entitled app. Feedback and contributions for the native layers are especially welcome.
