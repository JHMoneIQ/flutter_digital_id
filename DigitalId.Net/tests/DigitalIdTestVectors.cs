using DigitalId;
using System.Text.Json;

namespace DigitalId.Tests;

/// <summary>
/// Golden test vectors ported from the Flutter side for parity testing.
/// </summary>
public static class DigitalIdTestVectors
{
    public static readonly DigitalIdCredential RichPassport = new()
    {
        GivenName = "Jane",
        FamilyName = "Doe",
        FullName = "Jane A. Doe",
        DateOfBirth = new DateTimeOffset(1990, 5, 15, 0, 0, 0, TimeSpan.Zero),
        AgeOver18 = true,
        AgeOver21 = true,
        Nationality = "US",
        PlaceOfBirth = "New York, NY, USA",
        DocumentNumber = "A12345678",
        DocumentType = "passport",
        IssuingAuthority = "US Department of State",
        IssuingCountry = "US",
        IssueDate = new DateTimeOffset(2020, 1, 10, 0, 0, 0, TimeSpan.Zero),
        ExpirationDate = new DateTimeOffset(2030, 1, 10, 0, 0, 0, TimeSpan.Zero),
        RawCredential = Convert.FromBase64String("dGVzdC1hcHBsZS1lbmNyeXB0ZWQtYmxvYg=="),
        CredentialFormat = "apple-encrypted",
        Metadata = new Dictionary<string, object?>
        {
            ["issuer"] = "us-passport-issuer",
            ["testVector"] = "rich-passport"
        }
    };

    public static readonly DigitalIdCredential MinimalAgeVerification = new()
    {
        AgeOver18 = true,
        AgeOver21 = true,
        RawCredential = Convert.FromBase64String("dGVzdC1yYXctcHJvb2YtYnl0ZXM="),
        CredentialFormat = "mdoc-device-response",
        Metadata = new Dictionary<string, object?> { ["testVector"] = "minimal-age" }
    };

    public static readonly DigitalIdCredential AndroidMdlSuccess = new()
    {
        GivenName = "John",
        FamilyName = "Smith",
        AgeOver18 = true,
        State = "CA",
        RawCredential = Convert.FromBase64String("YW5kcm9pZC12cC10b2tlbi1wcm9vZg=="),
        CredentialFormat = "openid4vp-vp-token",
        Metadata = new Dictionary<string, object?>
        {
            ["source"] = "android-credential-manager",
            ["doctype"] = "org.iso.18013.5.1.mDL"
        }
    };

    public static readonly DigitalIdCredential WebDigitalCredentialsSuccess = new()
    {
        GivenName = "Alex",
        FamilyName = "Rivera",
        Nationality = "US",
        RawCredential = Convert.FromBase64String("d2ViLWRpZ2l0YWwtY3JlZGVudGlhbHMtcmF3"),
        CredentialFormat = "digital-credentials-api",
        Metadata = new Dictionary<string, object?>
        {
            ["source"] = "web-digital-credentials-api",
            ["protocol"] = "openid4vp-v1-unsigned"
        }
    };

    public static readonly DigitalIdException NoCredentialError = new()
    {
        Code = DigitalIdErrorCode.NoCredential,
        Message = "No matching digital ID found in any wallet."
    };

    // =====================================================================
    // REALISTIC mdoc CRYPTO VECTORS (for end-to-end encryption validation tests)
    // These are minimal but structurally valid DeviceResponse CBORs containing
    // IssuerAuth (COSE_Sign1 with embedded MSO) + disclosed issuerNameSpaces.
    // Used by RealCryptoMdocVerificationTests for digest + signature attacks.
    // Full generation happens at test runtime via MdocParser test helpers for freshness.
    // =====================================================================

    // Realistic mdoc binary vectors for cryptographic validation (MSO + digests + COSE)
    // are generated at runtime inside RealCryptoMdocVerificationTests (BuildMinimalMdocWithMsoAndDisclosed + tamper helpers)
    // so that every test run uses fresh, correctly signed, and correctly digested structures.
    // This guarantees the attack tests (digest mismatch, missing digest entry, bad sig, wrong transcript) are meaningful.
}
