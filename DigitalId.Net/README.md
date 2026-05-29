# DigitalId.Net

**Official C# companion to `flutter_digital_id` Flutter plugin.**

Minimal-dependency .NET 10 library for building OpenID4VP / DCQL requests and verifying digital identity credentials (passports, mDL, EU eID / PID, age verification) from Apple PassKit, Android Credential Manager, and the Web Digital Credentials API.

Shares identical data models, hand-coded serialization shapes (camelCase, base64 bytes, ISO dates), and golden test vectors with the Flutter library for perfect interoperability between mobile/web apps and .NET backends doing KYC / identity verification.

## Features

- Rich `DigitalIdCredential` (structured fields for UI + `RawCredential` bytes for backend cryptographic validation)
- `ClaimPath`, `DigitalIdRequestOptions`, `DigitalIdException` with full parity
- DCQL / OpenID4VP request builder (`DigitalIdRequestBuilder`)
- Verification primitives (`DigitalIdVerifier` - mdoc device auth + issuer signature skeletons; extend with real COSE/mdoc parser in production)
- Hand-coded `ToJson`/`FromJson` + `ToMap`/`FromMap` on every model (plus source-generated `JsonSerializerContext` for AOT)
- Same golden test vectors as Flutter side (positive + negative seeds)

No abstractions layer (per requirements) - everything in one focused package.

## Installation (NuGet)

```bash
dotnet add package DigitalId.Net
```

Once published, it will be available at https://www.nuget.org/packages/DigitalId.Net

## Quick Start

### 1. Build a request (to send to Flutter app or wallet)

```csharp
using DigitalId;
using DigitalId.Requests;

var options = new DigitalIdRequestOptions
{
    RequiredClaims = [ClaimPath.GivenName(), ClaimPath.FamilyName(), ClaimPath.AgeOver18()],
    OptionalClaims = [ClaimPath.Portrait()],
    IntentToRetain = false,
    Nonce = Guid.NewGuid().ToString("N")
};

string dcqlJson = DigitalIdRequestBuilder.BuildDcqlRequest(
    DigitalIdType.DriversLicense, 
    options);

// Send dcqlJson to your Flutter app (or use directly with Android CredentialManager / Web Digital Credentials API)
```

### 2. Handle a successful response from Flutter / wallet

```csharp
// The rawCredential + format come back from the Flutter plugin (or directly from Android/Web)
var credential = new DigitalIdCredential
{
    GivenName = "Jane",
    FamilyName = "Doe",
    AgeOver18 = true,
    DocumentNumber = "A12345678",
    IssuingCountry = "US",
    RawCredential = Convert.FromBase64String("...base64 mdoc or encrypted blob from wallet..."),
    CredentialFormat = "mdoc-device-response" // or "apple-encrypted", "openid4vp-vp-token", etc.
};

// Serialize exactly as Flutter would for your backend API
string payloadForYourApi = credential.ToJson();
// or credential.ToMap() for Dictionary form
```

### 3. Verify on the backend (before trusting any claims)

```csharp
using DigitalId.Verification;

var result = DigitalIdVerifier.VerifyMdoc(
    credential.RawCredential,
    sessionTranscript: /* transcript you generated for the session */,
    issuerCert: /* IACA or equivalent cert chain bytes */);

if (result.IsValid)
{
    // Safe to use credential.GivenName, AgeOver18, DocumentNumber etc. for KYC
}
else
{
    // result.ErrorCode, result.ErrorMessage
}
```

## Models & Serialization

Every model has:

- `string ToJson()` / `static T FromJson(string)`
- `Dictionary<string, object?> ToMap()` / `static T FromMap(...)`

All produce/consume the exact camelCase + base64 + ISO shapes used by the Dart `flutter_digital_id_platform_interface` models.

A `DigitalIdJsonContext` (source-generated) is also provided for high-performance AOT scenarios.

## Test Vectors & Parity

`DigitalIdTestVectors` contains the same seeds used by the Flutter tests (rich passport, minimal age, Android mDL, Web, error cases).

All vectors are exercised in the test suite (`dotnet test`) for roundtrips, builder output, and verifier paths.

## Building & Publishing

```bash
cd DigitalId.Net
dotnet build -c Release
dotnet pack -c Release -o ./artifacts
# Then: dotnet nuget push ./artifacts/DigitalId.Net.*.nupkg -k <your-key> -s https://api.nuget.org/v3/index.json
```

## License

MIT (see LICENSE file)

## Related

- Flutter plugin: https://github.com/jameshancock/flutter_digital_id
- iOS: Apple PassKit Verify with Wallet (PKIdentity* APIs)
- Android: Credential Manager + OpenID4VP / Digital Credentials
- Web: navigator.credentials.get({digital: ...})

**Production mdoc validation with full encryption integrity is now supported.**

The library performs real COSE_Sign1 verification (RFC 8152/9052 Sig_structure with external_aad for transcript binding), MSO digest validation (SHA-256 over disclosed claim values exactly as signed by the issuer), issuer signature on the MSO, and Apple PassKit encrypted response decryption (ECDH + AES-GCM).

Key production types:
- `MdocVerifier.Verify(...)` — full DeviceResponse validation (device auth optional, issuer + MSO digest required when keys supplied)
- `CoseVerifier.VerifySign1` / `VerifyMac0`
- `MdocParser` + `ValidateDigests` (exposed for advanced scenarios)
- `AppleResponseDecryptor.Decrypt`
- `DigitalIdVerifier` facade

See `samples/DigitalIdSample` (runnable end-to-end with live keygen, realistic mdoc construction, success + 4 attack scenarios blocked). All 25 tests (including 8+ new attack vectors) pass in Release.

See the `samples/DigitalIdSample` project (in this repo) for a concrete, runnable example that uses **BouncyCastle.Cryptography** (the crypto library already used across ProjectFulcrum for signatures and identity work) to perform stronger device authentication checks. The core `DigitalId.Net` package stays completely dependency-free; the sample shows the recommended production pattern.
