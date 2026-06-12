# flutter_digital_id

A Flutter plugin for requesting digital identity credentials (passports, driver's licenses / mDL, EU Digital ID / PID, and age verification) directly from the user's native wallet using the platform's secure APIs.

The plugin returns a `DigitalIdCredential` containing:

- Rich **structured fields** (name, DOB, portrait, etc.) you can use immediately to pre-fill forms in your UI.
- The **raw cryptographic proof** (`rawCredential`) that **your backend must verify** before trusting any of the data.

## Installation

```yaml
dependencies:
  flutter_digital_id: ^0.1.0
```

## Quick Start

```dart
import 'package:flutter_digital_id/flutter_digital_id.dart';

final credential = await DigitalId.instance.verifyWithPassport(
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
  // Use structured fields for UI immediately
  nameController.text = credential.fullName ?? '';

  // ALWAYS send the raw proof to your backend for verification
  await myBackend.submitDigitalId(credential);
}
```

See the `test_harness` and `flutter_digital_id/example` for a complete bank-style KYC demo (including "test vector" mode that works without any platform setup).

## Core API

### DigitalId

```dart
final DigitalId id = DigitalId.instance;

Future<bool> isAvailable(DigitalIdType type, {DigitalIdRequestOptions? options});
Future<bool> requestPermission(DigitalIdType type, {DigitalIdRequestOptions? options});
Future<DigitalIdCredential?> getDigitalId(DigitalIdType type, {DigitalIdRequestOptions? options});
```

Convenience methods:

- `verifyWithPassport(...)`
- `verifyWithDriversLicense(...)`
- `verifyWithEuDigitalId(...)`
- `verifyAge(minimumAge: 18)`

### DigitalIdType

- `passport`
- `driversLicense`
- `euDigitalId`
- `ageVerificationOnly`

### ClaimPath (selective disclosure)

```dart
ClaimPath.familyName()
ClaimPath.givenName()
ClaimPath.birthDate()
ClaimPath.portrait()
ClaimPath.nationality()
ClaimPath.ageOver(21)           // or ageOver18(), ageOver21(), ageOver(25), etc.
ClaimPath(['org.iso.18013.5.1', 'custom_element'])
```

### DigitalIdRequestOptions

```dart
DigitalIdRequestOptions(
  requiredClaims: [...],
  optionalClaims: [...],
  intentToRetain: false,
  nonce: 'your-nonce-here',
  allowMultipleCredentials: false,
  platformOptions: { /* escape hatch for platform-specific data */ },
)
```

### DigitalIdCredential (response)

```dart
final String? givenName;
final String? familyName;
final String? fullName;
final DateTime? dateOfBirth;
final bool? ageOver18;
final bool? ageOver21;
final Uint8List? portrait;
final String? nationality;
final String? documentNumber;
// ... other fields

final Uint8List rawCredential;      // THE PROOF - send this to your backend
final String credentialFormat;      // 'apple-encrypted', 'openid4vp-vp-token', 'digital-credentials-api', etc.
final List<String> disclosedClaimPaths;
final Map<String, dynamic> metadata;
```

**Never trust the structured fields until your backend has validated `rawCredential`.**

## Platform Setup

### iOS (PassKit Verify with Wallet)

1. Request the **"In-App Identity Presentment"** entitlement from Apple (<https://developer.apple.com/contact/request/verify-with-wallet/>).

2. Create a Merchant ID and an Identity Access Certificate (the private key is used by **your server** to decrypt responses).

3. Add the entitlement to your app (see the complete template in `flutter_digital_id/example/ios/Runner/Runner.entitlements` and `test_harness/ios/Runner/Runner.entitlements`).

4. Your `Info.plist` must include:

   ```xml
   <key>NSIdentityUsageDescription</key>
   <string>Digital ID is used to verify your age or identity with IDs stored in Apple Wallet.</string>
   <key>DigitalIdMerchantIdentifier</key>
   <string>merchant.com.yourcompany.digitalid</string>
   ```

   (The example and test harness already include this.)

5. For simulator testing (highly recommended first step):
   - Install Apple's "Wallet and Apple mDL Developer Integrator profile".
   - Download the sample data bundle from Apple's docs.
   - Run on an iPhone simulator. The consent sheet will appear using mock data.

Real production use on devices requires the approved entitlement.

### Android (Credential Manager)

- Minimum SDK 28 (or as required by your `CredentialManager` dependency).
- For production: Register as a Relying Party with Google Wallet (sandbox available).
- The plugin uses a real `ActivityAware` implementation.

See Google's "Online Acceptance of Digital Credentials" documentation for Relying Party setup and test wallets (e.g. CMWallet).

### Web (Digital Credentials API)

- Your app must be served over HTTPS or `localhost` (secure context).
- The implementation builds OpenID4VP + DCQL requests and extracts the raw response.

**To test the Web path:**

- Run `flutter run -d chrome` (or build and serve the web output).
- Use a browser that supports the Digital Credentials API + a test wallet/harness (e.g. <https://digital-credentials.dev/> or equivalent CMWallet-style tools).
- The `test_harness` can be used for manual end-to-end Web flows (it supports web builds).

Response extraction is hardened for common shapes returned by current implementations.

## Sending the Result to Your Backend

```dart
// Example payload you should POST to your server
final payload = {
  'rawCredential': base64Encode(credential.rawCredential),
  'credentialFormat': credential.credentialFormat,
  'disclosedClaimPaths': credential.disclosedClaimPaths,
  'structuredClaims': credential.toMap(), // optional, for convenience only
  'nonce': options?.nonce,
};

// Your backend must:
 // 1. Decrypt (Apple) or parse + validate MSO digests + issuer signature (mdoc / OpenID4VP)
 // 2. Verify nonce / transcript binding
 // 3. Check issuer against trusted IACA / root certificates
 // 4. Only then create the user account or complete KYC
```

Use the companion library `DigitalId.Net` (included in this repo) for server-side verification in .NET, or implement equivalent logic using the same test vectors for parity.

See `DigitalId.Net/samples/DigitalIdSample` for a working console example that performs real BouncyCastle-based verification (including attack matrix tests).

## Recommended Minimal Claims

For common flows:

- **Age verification only**: `ClaimPath.ageOver(18)`
- **Basic KYC**: family name, given name, birth date, nationality, portrait
- **Full driver's license**: add document number, expiration, issuing authority, driving privileges, portrait, address

Always request the smallest set of claims that satisfies your compliance requirements.

## Test Vector Mode (No Entitlements Required)

Both the example app and test harness have a "Use test vector" button. This lets you develop your complete UI + backend handoff flow immediately using realistic golden vectors that match the .NET verifier.

This is the fastest way to integrate while you obtain Apple entitlements or Google RP registration.

## Full Demo

- `flutter_digital_id/example` — simple usage demo
- `test_harness` — comprehensive cross-platform test app with widget + integration tests

Run:

```bash
cd test_harness
flutter run
```

## Backend Verification

**This library only collects the proof. Verification is your responsibility.**

Recommended: `DigitalId.Net` (companion library in this repository) — full MSO digest validation, COSE signature checks, Apple response decryption, transcript binding, and a complete set of golden vectors + attack tests.

## License

MIT

For additional platform notes see the `flutter_digital_id` package README. For simulator/harness workflows see `TESTING.md`. For server-side verification details see `DigitalId.Net/README.md`.
