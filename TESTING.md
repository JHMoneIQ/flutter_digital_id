# Testing flutter_digital_id

**Current status note:** Android now has a real Credential Manager integration, Web is still stubbed, and iOS now has a typed PassKit scaffold that still needs validation with an entitled Apple app. The golden test vectors + "test vector mode" in the example/harness remain the most reliable way to build UI, model, serialization, and backend handoff flows.

This document focuses on practical testing, especially on iOS simulator (the highest-value path you can exercise without production approval once your Apple-side setup is in place).

## iOS Simulator Testing (Recommended Starting Point)

### 1. Prerequisites

- Xcode + iOS Simulator (iOS 17+ or 26.x recommended for best mock support).
- Apple Developer access suitable for installing the developer profile and configuring your test app. Apple’s docs allow mock testing on simulator/device, while the real entitled path requires Apple Developer Program access and an approved entitlement.

### 2. Install Apple's Developer Profile

1. Go to Apple's bug reporting / profiles page:  
   <https://developer.apple.com/bug-reporting/profiles-and-logs/>

2. Search for and install the profile named:  
   **"Wallet and Apple mDL Developer Integrator profile"**

This profile enables mock identity documents in the simulator and on devices.

### 3. Download Apple's Sample Data + Simulator Keys

From the official docs:  
<https://developer.apple.com/wallet/get-started-with-verify-with-wallet/>

Download the **"Sample data and simulator keys"** bundle.  
It contains:

- Mock identity documents pre-loaded in the simulator.
- Private keys and certificates you can use locally to validate responses.

### 4. Configure Your Example App (or consuming app)

Use the template entitlements file included in the example:

```text
flutter_digital_id/example/ios/Runner/Runner.entitlements
```

Update the Merchant ID to something like:

- `merchant.com.yourcompany.digitalid` (or any valid string for simulator testing).

For simulator/mock testing you do **not** need production approval from Apple. For the real entitled flow in your own app, you still need the Apple Developer Program setup, merchant ID, and entitlement approval described in the main README.

### 5. Run the Example on Simulator

```bash
cd flutter_digital_id/example
flutter run -d <simulator-udid-or-name>
```

In the app:

- Tap **"Try real native flow on this device"** for passport or driver's license.
- With the typed PassKit scaffold in place, the goal is that a correctly configured entitled build will show the genuine PassKit consent sheet.
- In this repo, treat that path as **experimental until you validate it in your own Apple environment**.
- The "Use test vector (no native call)" button is still useful for pure UI/backend development without any device setup.

**Note:** The data is mock data signed by a real device key. It will **not** have a valid issuer signature. This is expected and sufficient for exercising the full consent + response flow.

### 6. What to Verify

- `isDigitalIdAvailable(...)` reflects the result of PassKit's `checkCanRequestDocument(...)` on supported iPhone builds.
- The consent sheet appears and lists the requested elements.
- User cancellation returns `null`.
- Successful response contains:
  - `rawCredential` (the encrypted data)
  - `credentialFormat` = `apple-encrypted`
  - Any `disclosedClaimPaths` returned by the system

### Common Issues

- Consent sheet does not appear → Missing or incorrect entitlements in the app.
- `notEntitled` error → Profile not installed or wrong document types in entitlements.
- No mock data → Simulator does not have the developer profile applied (restart simulator after installing profile).

## Android Testing

The Android plugin now uses a real `CredentialManager.getCredential(...)` flow.

For practical Android validation:

- use a device or emulator with a wallet that supports digital credentials;
- ensure your relying-party request shape is accepted by the wallet;
- verify cancellation, no-credential, and success paths;
- inspect the returned raw payload on your backend.

See the main README for links to Google's sandbox and CMWallet test wallet.

## Web Testing

Run with `flutter run -d chrome` (must be served over HTTPS or localhost).

Use a browser that supports the Digital Credentials API + a test wallet (e.g. CMWallet or the digital-credentials.dev harness).

## Golden Test Vectors (No Device Required)

The plugin includes seed-based unit tests using realistic vectors for:

- Rich passport responses
- Minimal age verification
- iOS-style encrypted responses
- Error cases (user cancelled, not entitled, etc.)

Run them with:

```bash
cd flutter_digital_id_platform_interface
flutter test
```

These are useful for UI development and backend integration testing without any native setup.

## Full End-to-End KYC Flow Testing

For true end-to-end testing you will eventually need:

- Production entitlements / RP registration (Apple + Google).
- Your backend performing real decryption + signature validation using the merchant private key and IACA certificates.

The example deliberately includes a "Use test vector" mode so you can develop the full frontend + backend handoff without waiting for entitlements.
