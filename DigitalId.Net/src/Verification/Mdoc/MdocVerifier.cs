using DigitalId.Verification.Cose;
using Org.BouncyCastle.Crypto;
using PeterO.Cbor;
using System;

namespace DigitalId.Verification.Mdoc;

/// <summary>
/// Production-oriented mdoc verifier (ISO 18013-5).
/// Performs real COSE cryptographic validation (Sign1 for issuer + device auth) +
/// critical MSO digest validation proving the issuer authorized the exact disclosed claim values.
/// </summary>
public static class MdocVerifier
{
    /// <summary>
    /// Verifies a device response (mdoc) using optional device public key (for transcript binding)
    /// and/or issuer public key (for MSO signature + digest validation).
    /// </summary>
    public static VerificationResult Verify(
        ReadOnlySpan<byte> deviceResponse,
        byte[] sessionTranscript,
        AsymmetricKeyParameter? expectedDevicePublicKey = null,
        AsymmetricKeyParameter? issuerPublicKey = null)
    {
        try
        {
            var doc = MdocParser.ParseDeviceResponse(deviceResponse);

            // Device authentication (transcript binding) is only enforced when the caller supplies the device public key.
            // This allows pure issuer-side validation (MSO signature + digest checks) when only the issuer key is available.
            if (expectedDevicePublicKey != null)
            {
                bool deviceAuthOk = VerifyDeviceAuth(doc, sessionTranscript, expectedDevicePublicKey);
                if (!deviceAuthOk)
                    return VerificationResult.Fail(DigitalIdErrorCode.Unknown, "Device authentication failed (transcript binding or key mismatch)");
            }

            if (issuerPublicKey != null)
            {
                bool issuerSigOk = VerifyIssuerAuth(doc, issuerPublicKey);
                if (!issuerSigOk)
                    return VerificationResult.Fail(DigitalIdErrorCode.Unknown, "Issuer signature on MSO invalid");

                // NEW: Full MSO content validation — the heart of mdoc security
                var (digestsOk, digestError) = MdocParser.ValidateDigests(doc);
                if (!digestsOk)
                    return VerificationResult.Fail(DigitalIdErrorCode.Unknown, $"MSO digest validation failed: {digestError}");
            }
            else if (doc.Mso != null)
            {
                // Even without explicit issuer key, if MSO present we still enforce digest self-consistency
                // (caller can separately verify the outer COSE sig on IssuerAuth using key from MSO cert)
                var (digestsOk, digestError) = MdocParser.ValidateDigests(doc);
                if (!digestsOk)
                    return VerificationResult.Fail(DigitalIdErrorCode.Unknown, $"MSO digest validation failed: {digestError}");
            }

            return VerificationResult.Ok();
        }
        catch (Exception ex)
        {
            return VerificationResult.Fail(DigitalIdErrorCode.Unknown, ex.Message);
        }
    }

    private static bool VerifyDeviceAuth(MdocDocument doc, byte[] sessionTranscript, AsymmetricKeyParameter? devicePublicKey)
    {
        if (doc.DeviceAuth == null) return false;
        if (devicePublicKey == null) return false; // Can't verify without key

        var deviceAuth = doc.DeviceAuth;

        if (deviceAuth.ContainsKey("deviceSignature"))
        {
            byte[] coseBytes = deviceAuth["deviceSignature"].GetByteString();
            return CoseVerifier.VerifySign1(coseBytes, devicePublicKey, sessionTranscript);
        }

        if (deviceAuth.ContainsKey("deviceMac"))
        {
            // Mac0 requires ECDH + HKDF key derivation per ISO 18013-5 (reader ephemeral + device key)
            // Production implementations should derive the session MAC key and call CoseVerifier.VerifyMac0
            return false;
        }

        return false;
    }

    private static bool VerifyIssuerAuth(MdocDocument doc, AsymmetricKeyParameter issuerPublicKey)
    {
        if (doc.IssuerAuth == null) return false;

        // Per ISO 18013-5: issuerAuth is COSE_Sign1 over the MSO; external_aad is typically empty
        return CoseVerifier.VerifySign1(doc.IssuerAuth, issuerPublicKey, Array.Empty<byte>());
    }
}
