# flutter_digital_id_darwin

iOS (and macOS graceful-degrade) implementation of `flutter_digital_id` using PassKit Verify with Wallet.

## Implementation

Uses the documented public APIs:
- `PKIdentityAuthorizationController`
- `PKIdentityRequest`
- Typed descriptors (`PKIdentityDriversLicenseDescriptor`, `PKIdentityNationalIDCardDescriptor`, `PKIdentityPhotoIDDescriptor` on iOS 26+)

Claim paths are mapped to the corresponding `PKIdentityElement` values (including dynamic `age(atLeast:)`).

Merchant identifier is resolved from `platformOptions['merchantIdentifier']` or the `Info.plist` key `DigitalIdMerchantIdentifier`.

## Entitlement requirement (critical)

Real use on iOS requires an approved "In-App Identity Presentment" entitlement from Apple, a Merchant ID + Identity Access Certificate, and correct entitlements + `NSIdentityUsageDescription` in your app.

See the main `flutter_digital_id` package README and Apple's Verify with Wallet documentation for the full setup.

On simulator you can exercise the flow with Apple's "Wallet and Apple mDL Developer Integrator profile" + sample data (mock signatures). The returned `rawCredential` will be an encrypted blob (`credentialFormat: "apple-encrypted"`) that your backend must decrypt and validate.

## macOS

Returns clear "PLATFORM_UNSUPPORTED" errors. No silent degradation to false for the main flow.

## Notes

This package is not meant to be used directly by apps. Depend on `flutter_digital_id` instead.

The implementation uses the real public PassKit Verify with Wallet APIs (`PKIdentity*`). It is ready for integration into an entitled app (requires Apple "In-App Identity Presentment" entitlement approval, Merchant ID, and Identity Access Certificate).

- Simulator testing: use Apple's developer profile + sample data (see TESTING.md).
- Device / production: full entitled provisioning required; the plugin surfaces `NOT_ENTITLED` via `DigitalIdException` when misconfigured.
- Server decryption of the `apple-encrypted` blob is mandatory (use DigitalId.Net or equivalent).

iOS support is no longer a speculative scaffold; the native code path is the production-intent implementation. End-to-end cryptographic validation in a fully entitled consumer app is the remaining integrator responsibility.
