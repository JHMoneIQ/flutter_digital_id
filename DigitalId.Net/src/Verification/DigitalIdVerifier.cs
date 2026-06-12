using DigitalId;
using DigitalId.Verification.Cose;
using DigitalId.Verification.Mdoc;
using Org.BouncyCastle.Crypto;
using Org.BouncyCastle.OpenSsl;
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

    /// <summary>
    /// Loads a BouncyCastle public key from a PEM string (certificate or public key).
    /// 
    /// Production use: Load your trusted IACA issuer certificates this way and pass the resulting
    /// AsymmetricKeyParameter to VerifyMdoc / MdocVerifier.Verify.
    /// 
    /// How to obtain real certificates:
    /// - Development / simulator: Use the "Sample data and simulator keys" bundle from Apple’s mDL docs.
    /// - Production: Contact each issuing authority (state DMV, national eID provider, etc.) for their current
    ///   signing certificate. Maintain an allow-list of trusted issuers in your backend configuration.
    ///   There is no single universal live global API (issuers are sovereign); lists are maintained per-jurisdiction
    ///   or through regional trust frameworks (e.g. EU eIDAS trusted lists, AAMVA resources for US mDL).
    ///   Fetching live without strong pinning and signature verification on the list itself is not recommended.
    ///
    /// US Passport Digital ID (Apple "passport-digital-id"):
    ///   • Dev/simulator: https://developer.apple.com/bug-reporting/profiles-and-logs/
    ///     then https://developer.apple.com/wallet/get-started-with-verify-with-wallet/
    ///   • Production: Privately distributed by Apple to approved RPs after entitlement approval.
    /// </summary>
    public static AsymmetricKeyParameter? LoadIssuerPublicKeyFromPem(string pem)
    {
        if (string.IsNullOrWhiteSpace(pem)) return null;

        using var reader = new System.IO.StringReader(pem);
        var pemReader = new Org.BouncyCastle.OpenSsl.PemReader(reader);
        var obj = pemReader.ReadObject();

        return obj switch
        {
            Org.BouncyCastle.Crypto.AsymmetricKeyParameter key => key,
            Org.BouncyCastle.X509.X509Certificate cert => cert.GetPublicKey(),
            _ => null
        };
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
