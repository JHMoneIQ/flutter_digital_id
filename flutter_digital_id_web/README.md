# flutter_digital_id_web

Web implementation of `flutter_digital_id` targeting the W3C Digital Credentials API.

## Current state

- Builds OpenID4VP / DCQL requests (`mso_mdoc` credentials) via the pure `WebRequestBuilder` (unit testable).
- Implements `navigator.credentials.get({ digital: ... })` using `package:web` for the full flow.
- Extracts raw response bytes using a defensive, hardened heuristic covering common and nested shapes (`response`, `vp_token`, `deviceResponse`, direct base64, lists, maps, etc.).
- `isDigitalIdAvailable` does basic Credentials API presence detection.
- `requestPermission` is a no-op (consent is shown as part of the one-shot `get()` call on Web).
- Non-cancel failures now surface as `DigitalIdException` for better diagnostics during interop testing.

## Interoperability

Support depends on the browser implementing the Digital Credentials API and on wallets / credential managers exposing compatible OpenID4VP or mdoc presentations.

The request/response shapes are best-effort against current drafts. Real validation against shipping browser + wallet combinations is required before production use.

**Stronger validation path:** Run `flutter run -d chrome` (localhost or HTTPS) + a test wallet/harness. The `WebRequestBuilder` tests provide regression coverage for extraction logic independent of browser.

## Testing recommendation

Use `flutter run -d chrome` (must be a secure context) together with a test harness or wallet that supports the API (e.g. the digital-credentials.dev tools or equivalent). The cross-platform `test_harness` can also be used for manual web flows.

## Notes

This package is not meant to be used directly by apps. Depend on `flutter_digital_id` instead.

Web support targets an emerging standard (Digital Credentials API); the client implementation and response handling in this package are complete and hardened.
