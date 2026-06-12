# flutter_digital_id_example

Demonstration app for the `flutter_digital_id` Flutter plugin.

## What it shows

- High-level usage of `DigitalId.instance.getDigitalId(...)`, the convenience methods (`verifyWithPassport`, `verifyAge`, etc.), and `DigitalIdRequestOptions`.
- "Use test vector" mode — lets you exercise the full UI + serialization + backend handoff flow with no native entitlements or devices. This is the fastest way to develop KYC screens and wire up your server verification.
- Display of both the structured fields (for pre-fill) and the raw proof bytes / format (what you send to your backend).

## Running

```bash
cd flutter_digital_id/example
flutter run
```

On iOS simulator (after installing Apple's Wallet developer profile + sample data), the "Try real native flow" buttons can exercise the PassKit consent sheet.

See the root README for setup. Use the `test_harness` for the richest cross-platform testing experience.

## Important security note

The structured data shown in the app is **not trustworthy** until your backend has validated the accompanying `rawCredential` using something like `DigitalId.Net` (or equivalent mdoc / COSE / Apple response decryption logic) plus issuer trust anchors.

Never create accounts or persist identity data based only on the client-side structured fields.
