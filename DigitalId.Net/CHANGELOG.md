# Changelog

All notable changes to `DigitalId.Net` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025

### Added
- Full `DigitalIdCredential`, `ClaimPath`, `DigitalIdRequestOptions`, `DigitalIdType` models with hand-coded `ToJson`/`FromJson` + `ToMap`/`FromMap` for exact parity with the Flutter `flutter_digital_id_platform_interface` package.
- `DigitalIdRequestBuilder` for producing DCQL / OpenID4VP request JSON from high-level options (matches what the Flutter plugin sends to wallets).
- `DigitalIdVerifier` facade + real verification primitives:
  - `MdocVerifier` with MSO digest validation (SHA-256 over disclosed values), issuer MSO signature validation (COSE_Sign1), optional device authentication.
  - `CoseVerifier` for Sign1 / Mac0.
  - `MdocParser`, `ValidateDigests`.
  - `AppleResponseDecryptor` for PassKit encrypted response (ECDH + AES-GCM).
- Golden test vectors (same seeds as Flutter side): rich passport, minimal age verification, Android mDL-style, Web, plus a full attack matrix (digest mismatch, missing digest, bad issuer sig, wrong transcript, truncated data, Apple decrypt failures, etc.).
- `samples/DigitalIdSample` demonstrating end-to-end with BouncyCastle (recommended production crypto) including key generation and attack scenario blocking.
- Source-generated `DigitalIdJsonContext` for AOT / NativeAOT scenarios.
- Strong packaging: README + LICENSE included in NuGet, XML docs generated, MIT license expression.

### Notes
- The core library depends on `PeterO.Cbor` and `BouncyCastle.Cryptography` to deliver production-grade mdoc + COSE + Apple response handling. The "minimal dependency" goal is achieved relative to what is required for trustworthy verification; no unnecessary transitive bloat.
- 25+ tests must pass in Release (`dotnet test -c Release`).
- This library is the official server-side companion for `flutter_digital_id`. Use it (or a port with equivalent crypto) to validate `rawCredential` before trusting any claims.
