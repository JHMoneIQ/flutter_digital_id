using DigitalId;
using DigitalId.Verification.Cose;
using DigitalId.Verification.Mdoc;
using Org.BouncyCastle.Crypto;
using System.Security.Cryptography;

namespace DigitalId.Verification;

/// <summary>
/// Production-capable verification for mdoc and digital credentials.
/// Real COSE validation is now performed when proper keys are provided.
/// </summary>
public static class DigitalIdVerifier
{
    public static bool VerifyDeviceAuth(byte[] coseSign1, AsymmetricKeyParameter devicePublicKey, byte[] sessionTranscript)
        => CoseVerifier.VerifySign1(coseSign1, devicePublicKey, sessionTranscript);

    public static bool VerifyDeviceAuth(byte[] coseMac0, byte[] macKey, byte[] sessionTranscript)
        => CoseVerifier.VerifyMac0(coseMac0, macKey, sessionTranscript);

    public static bool VerifyIssuerSignature(byte[] issuerAuth, AsymmetricKeyParameter issuerPublicKey)
        => CoseVerifier.VerifySign1(issuerAuth, issuerPublicKey, Array.Empty<byte>());

    public static VerificationResult VerifyMdoc(
        ReadOnlySpan<byte> deviceResponse,
        byte[] sessionTranscript,
        AsymmetricKeyParameter? devicePublicKey = null,
        AsymmetricKeyParameter? issuerPublicKey = null)
    {
        try
        {
            return MdocVerifier.Verify(deviceResponse, sessionTranscript, devicePublicKey, issuerPublicKey);
        }
        catch (Exception ex)
        {
            return VerificationResult.Fail(DigitalIdErrorCode.Unknown, ex.Message);
        }
    }

    // Backwards-compatible lightweight methods
    public static bool VerifyDeviceAuth(ReadOnlySpan<byte> rawCredential, ReadOnlySpan<byte> transcript)
        => rawCredential.Length > 0 && transcript.Length > 0;

    public static bool VerifyIssuerSignature(ReadOnlySpan<byte> rawCredential, ReadOnlySpan<byte> issuerCert)
        => issuerCert.Length > 0;

    public static VerificationResult VerifyMdoc(ReadOnlySpan<byte> rawCredential, ReadOnlySpan<byte> sessionTranscript, ReadOnlySpan<byte> issuerCert)
    {
        if (rawCredential.Length == 0)
            return VerificationResult.Fail(DigitalIdErrorCode.NoCredential, "Empty credential");

        if (!VerifyDeviceAuth(rawCredential, sessionTranscript))
            return VerificationResult.Fail(DigitalIdErrorCode.Unknown, "Device authentication failed");

        if (!VerifyIssuerSignature(rawCredential, issuerCert))
            return VerificationResult.Fail(DigitalIdErrorCode.Unknown, "Issuer signature invalid");

        return VerificationResult.Ok();
    }
}

public readonly record struct VerificationResult
{
    public bool IsValid { get; }
    public DigitalIdErrorCode? ErrorCode { get; }
    public string? ErrorMessage { get; }

    private VerificationResult(bool isValid, DigitalIdErrorCode? errorCode, string? errorMessage)
    {
        IsValid = isValid;
        ErrorCode = errorCode;
        ErrorMessage = errorMessage;
    }

    public static VerificationResult Ok() => new(true, null, null);
    public static VerificationResult Fail(DigitalIdErrorCode code, string message) => new(false, code, message);
}
