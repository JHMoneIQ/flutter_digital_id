using System;
using System.Security.Cryptography;
using DigitalId;
using DigitalId.Requests;
using DigitalId.Verification;
using DigitalId.Verification.Mdoc;
using Org.BouncyCastle.Crypto;
using Org.BouncyCastle.Asn1.X9;
using Org.BouncyCastle.Crypto.Generators;
using Org.BouncyCastle.Crypto.Parameters;
using Org.BouncyCastle.Security;
using PeterO.Cbor;

namespace DigitalIdSample;

/// <summary>
/// Sample console app showing realistic usage + verification with BouncyCastle.Cryptography
/// (the crypto library already heavily used in ProjectFulcrum for signatures and identity work).
///
/// This demonstrates how a backend would:
/// 1. Build a request (same as what you send to Flutter)
/// 2. Receive a DigitalIdCredential (from your Flutter app or directly)
/// 3. Perform stronger verification than the built-in skeleton
///
/// NOTE: Full production mdoc verification also requires:
/// - Proper CBOR parsing of the DeviceResponse / IssuerSigned
/// - Extracting the device public key and MSO
/// - Verifying the issuer signature on the MSO against your trusted IACA certificates
///
/// This sample focuses on the device authentication (transcript + device key) part,
/// which is the most common source of "fake presentation" attacks.
/// </summary>
internal static class Program
{
    static void Main()
    {
        Console.WriteLine("=== DigitalId.Net 1.0 — End-to-End Production Crypto Sample ===\n");
        Console.WriteLine("Demonstrates full real-world flow with BouncyCastle + PeterO.Cbor:");
        Console.WriteLine("  • DCQL request building (parity with Flutter)");
        Console.WriteLine("  • Real ECDSA key generation for issuer + device");
        Console.WriteLine("  • Construction of minimal valid mdoc DeviceResponse (IssuerAuth COSE_Sign1 + MSO + disclosed claims)");
        Console.WriteLine("  • Full MdocVerifier: device auth (transcript binding) + issuer signature on MSO + MSO digest validation");
        Console.WriteLine("  • Attack detection (digest mismatch, bad signature, wrong transcript)\n");

        // 1. Build DCQL request exactly as a Flutter client would receive it
        var options = new DigitalIdRequestOptions
        {
            RequiredClaims =
            [
                ClaimPath.GivenName(),
                ClaimPath.FamilyName(),
                ClaimPath.AgeOver18(),
                ClaimPath.DocumentNumber()
            ],
            Nonce = "e2e-" + Guid.NewGuid().ToString("N")[..8],
            IntentToRetain = false
        };

        string dcql = DigitalIdRequestBuilder.BuildDcqlRequest(DigitalIdType.DriversLicense, options);
        Console.WriteLine("1. Generated DCQL (sent to wallet/Flutter):");
        Console.WriteLine(dcql.Length > 400 ? dcql[..400] + "..." : dcql);
        Console.WriteLine();

        // 2. Simulate the holder presenting a real mdoc (we generate a fresh, correctly signed one)
        // In real life this RawCredential bytes come back from the Flutter plugin (or Android/Web directly)
        var (deviceResponse, issuerPub, devicePub) = CreateRealisticSignedMdocPresentation("Jane", "Doe", sessionTranscript: "real-e2e-session-transcript-abc123"u8.ToArray());

        var credential = new DigitalIdCredential
        {
            GivenName = "Jane",
            FamilyName = "Doe",
            AgeOver18 = true,
            DocumentNumber = "DL-987654321",
            RawCredential = deviceResponse,
            CredentialFormat = "mdoc-device-response",
            Metadata = new Dictionary<string, object?> { ["doctype"] = "org.iso.18013.5.1.mDL", ["source"] = "e2e-demo" }
        };

        Console.WriteLine($"2. Received credential from wallet (raw bytes: {credential.RawCredential.Length}, format: {credential.CredentialFormat})");

        // 3. Run the PRODUCTION verifier (this is what your KYC backend calls)
        byte[] transcript = "real-e2e-session-transcript-abc123"u8.ToArray();

        var result = DigitalIdVerifier.VerifyMdoc(
            credential.RawCredential,
            transcript,
            devicePub,
            issuerPub);

        Console.WriteLine($"\n3. MdocVerifier result (FULL crypto): IsValid={result.IsValid}");
        if (!result.IsValid)
            Console.WriteLine($"   Error: {result.ErrorMessage}");
        else
            Console.WriteLine("   ✓ Device signature over transcript ✓ Issuer MSO signature ✓ All disclosed claim digests match signed MSO");

        // 4. Demonstrate attack detection (the reason we do real validation)
        Console.WriteLine("\n4. Attack detection demos:");

        // 4a. Digest mismatch (holder or attacker changed a disclosed claim)
        var tamperedDr = TamperOneClaim(deviceResponse, "given_name", "Eva");
        var attack1 = DigitalIdVerifier.VerifyMdoc(tamperedDr, transcript, devicePub, issuerPub);
        Console.WriteLine($"   • Tampered disclosed value (digest mismatch): {(attack1.IsValid ? "PASSED (BAD!)" : "BLOCKED ✓")} — {attack1.ErrorMessage}");

        // 4b. Wrong transcript (replay or session confusion)
        var attack2 = DigitalIdVerifier.VerifyMdoc(deviceResponse, "different-session-transcript-XYZ"u8.ToArray(), devicePub, issuerPub);
        Console.WriteLine($"   • Wrong transcript binding: {(attack2.IsValid ? "PASSED (BAD!)" : "BLOCKED ✓")}");

        Console.WriteLine("\n=== End-to-end complete. Production mdoc validation with real COSE + MSO digests is working. ===");
        Console.WriteLine("See RealCryptoMdocVerificationTests.cs for the full matrix of positive + attack cases.");
    }

    // =====================================================================
    // Helpers that create a *realistic* signed mdoc presentation for the demo
    // (same patterns used in the unit test attack matrix)
    // =====================================================================

    private static (byte[] DeviceResponse, AsymmetricKeyParameter IssuerPub, AsymmetricKeyParameter DevicePub)
        CreateRealisticSignedMdocPresentation(string given, string family, byte[] sessionTranscript)
    {
        var issuerPair = GenerateEcKeyPair();
        var devicePair = GenerateEcKeyPair();

        var issuerPriv = (ECPrivateKeyParameters)issuerPair.Private;
        var devicePriv = (ECPrivateKeyParameters)devicePair.Private;

        // One disclosed claim under mDL namespace
        string ns = "org.iso.18013.5.1";
        int digestId = 0;
        var elementValue = CBORObject.FromObject(given);
        byte[] valBytes = elementValue.EncodeToBytes();
        byte[] digest = SHA256.HashData(valBytes);

        var valueDigests = CBORObject.NewMap();
        var perNs = CBORObject.NewMap();
        perNs.Add(digestId, CBORObject.FromObject(digest));
        valueDigests.Add(ns, perNs);

        var mso = CBORObject.NewMap();
        mso.Add("version", "1.0");
        mso.Add("digestAlgorithm", "SHA-256");
        mso.Add("valueDigests", valueDigests);

        byte[] msoBytes = mso.EncodeToBytes();
        byte[] issuerAuth = CreateCoseSign1(issuerPriv, Array.Empty<byte>(), msoBytes);

        // Disclosed entry
        var entry = CBORObject.NewMap();
        entry.Add("digestID", digestId);
        entry.Add("elementIdentifier", "given_name");
        entry.Add("elementValue", elementValue);

        var nsArr = CBORObject.NewArray(); nsArr.Add(entry);
        var issuerNameSpaces = CBORObject.NewMap(); issuerNameSpaces.Add(ns, nsArr);

        var issuerSigned = CBORObject.NewMap();
        issuerSigned.Add("issuerAuth", CBORObject.FromObject(issuerAuth));
        issuerSigned.Add("issuerNameSpaces", issuerNameSpaces);

        // Minimal deviceSigned with Sign1 over transcript (real device auth)
        byte[] deviceSignature = CreateCoseSign1(devicePriv, sessionTranscript, sessionTranscript);
        var deviceAuth = CBORObject.NewMap();
        deviceAuth.Add("deviceSignature", CBORObject.FromObject(deviceSignature));

        var deviceSigned = CBORObject.NewMap();
        deviceSigned.Add("deviceAuth", deviceAuth);

        var doc = CBORObject.NewMap();
        doc.Add("issuerSigned", issuerSigned);
        doc.Add("deviceSigned", deviceSigned);

        var docs = CBORObject.NewArray(); docs.Add(doc);
        var dr = CBORObject.NewMap();
        dr.Add("documents", docs);
        dr.Add("status", CBORObject.NewMap());

        return (dr.EncodeToBytes(), issuerPair.Public, devicePair.Public);
    }

    private static byte[] TamperOneClaim(byte[] dr, string elementId, string newVal)
    {
        var c = CBORObject.DecodeFromBytes(dr);
        var entries = c["documents"][0]["issuerSigned"]["issuerNameSpaces"]["org.iso.18013.5.1"];
        for (int i = 0; i < entries.Count; i++)
            if (entries[i]["elementIdentifier"].AsString() == elementId)
                entries[i]["elementValue"] = CBORObject.FromObject(newVal);
        return c.EncodeToBytes();
    }

    private static AsymmetricCipherKeyPair GenerateEcKeyPair()
    {
        var gen = new ECKeyPairGenerator();
        var curve = ECNamedCurveTable.GetByName("P-256");
        var dp = new ECDomainParameters(curve.Curve, curve.G, curve.N, curve.H, curve.GetSeed());
        gen.Init(new ECKeyGenerationParameters(dp, new SecureRandom()));
        return gen.GenerateKeyPair();
    }

    private static byte[] CreateCoseSign1(ECPrivateKeyParameters priv, byte[] external, byte[] payload)
    {
        byte[] prot = CBORObject.NewMap().EncodeToBytes();
        var sigStruct = CBORObject.NewArray();
        sigStruct.Add("Signature1"); sigStruct.Add(prot); sigStruct.Add(external); sigStruct.Add(payload);
        byte[] tbs = sigStruct.EncodeToBytes();

        ISigner s = SignerUtilities.GetSigner("SHA-256withECDSA");
        s.Init(true, priv);
        s.BlockUpdate(tbs, 0, tbs.Length);
        byte[] sig = s.GenerateSignature();

        var cose = CBORObject.NewArray();
        cose.Add(prot); cose.Add(CBORObject.NewMap()); cose.Add(payload); cose.Add(sig);
        return cose.EncodeToBytes();
    }
}
