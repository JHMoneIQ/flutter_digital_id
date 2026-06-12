# flutter_digital_id_platform_interface

Shared platform interface, data models, and serialization contract for the `flutter_digital_id` federated plugin.

## Purpose

This package defines the common vocabulary used across all platforms (Android, iOS, Web, and the companion `DigitalId.Net` server library):

- `DigitalIdCredential` — the result type containing both **structured claims** (for immediate UI pre-fill) and the **raw cryptographic proof** (`rawCredential` + `credentialFormat`) that must be sent to a backend for verification.
- `DigitalIdRequestOptions` — selective disclosure controls (required vs optional claims, `intentToRetain`, `nonce`, `platformOptions` escape hatch).
- `ClaimPath` — type-safe builders for mdoc / OpenID4VP claim paths (`familyName()`, `ageOver(18)`, `portrait()`, etc.) with value equality.
- `DigitalIdType` — passport, driversLicense, euDigitalId, ageVerificationOnly.

All models use **hand-coded** `toMap`/`fromMap` + `toJson`/`fromJson` (no build_runner) to guarantee stable, reviewable serialization shapes that stay in exact parity with `DigitalId.Net`.

## For consumers

Application developers normally depend on the main `flutter_digital_id` package only. This interface package is pulled in transitively.

Server/backend developers and advanced plugin authors may depend on this package directly for the model definitions when they want to avoid pulling in Flutter.

## Versioning

All five Flutter packages (`flutter_digital_id*`) are released in lockstep. See the root `release.md` for the required publish order.

## Related

- Main plugin: `flutter_digital_id`
- Server verification: `DigitalId.Net` (NuGet)
- Full docs: root README, `TESTING.md`, `release.md`
