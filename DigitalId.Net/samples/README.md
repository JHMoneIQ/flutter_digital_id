# DigitalId.Net Samples

This folder contains runnable examples that go beyond the minimal core library.

## DigitalIdSample (Console App)

Demonstrates:

- Building DCQL/OpenID4VP requests
- Consuming `DigitalIdCredential` objects (using golden vectors)
- Performing stronger cryptographic verification using **BouncyCastle.Cryptography** (the library already used throughout ProjectFulcrum for identity, signatures, and advanced crypto work)

### Why BouncyCastle?

`DigitalId.Net` itself has **zero external dependencies** (true minimal surface).

When you need real mdoc device authentication or issuer signature verification, the recommended path (consistent with the rest of your .NET platform) is to bring in `BouncyCastle.Cryptography` (already on your approved list) plus a CBOR library.

This sample shows exactly how to do that without polluting the core NuGet package.

### Running the sample

```bash
cd samples/DigitalIdSample
dotnet run
```

It will reference the local `DigitalId.Net` project + pull BouncyCastle 2.6.2.

### Production guidance

For a complete production verifier you will also need:

- A CBOR parser (many teams already have one; PeterO.Cbor is common and lightweight)
- Logic to parse `DeviceResponse` → `Document` → `IssuerSigned` + `DeviceSigned`
- Extraction of the device public key (COSE_Key)
- Verification of the MSO (Mobile Security Object) signature against your trusted IACA certificate(s)

The core `DigitalIdVerifier` in the main library remains a lightweight skeleton so the package stays minimal. Use (or copy) the patterns from this sample when you need the real thing.

---

See the main [README.md](../README.md) for general usage of `DigitalId.Net`.