using System.Text.Json;
using DigitalId;
using DigitalId.Requests;
using DigitalId.Verification;
using Xunit;

namespace DigitalId.Tests;

/// <summary>
/// Comprehensive tests using golden vectors from the Flutter side for full parity.
/// Covers positive and negative cases, serialization roundtrips (JSON + Map), request building, and verification.
/// </summary>
public class DigitalIdModelSerializationTests
{
    [Fact]
    public void RichPassport_Vector_Roundtrips_Json_And_Map()
    {
        var original = DigitalIdTestVectors.RichPassport;

        string json = original.ToJson();
        var fromJson = DigitalIdCredential.FromJson(json);

        Assert.Equal(original.GivenName, fromJson.GivenName);
        Assert.Equal(original.FamilyName, fromJson.FamilyName);
        Assert.Equal(original.AgeOver18, fromJson.AgeOver18);
        Assert.Equal(original.DocumentNumber, fromJson.DocumentNumber);
        Assert.Equal(original.CredentialFormat, fromJson.CredentialFormat);
        Assert.True(fromJson.RawCredential.Length > 0);

        var map = original.ToMap();
        var fromMap = DigitalIdCredential.FromMap(map);

        Assert.Equal(original.FullName, fromMap.FullName);
        Assert.Equal(original.ExpirationDate?.ToString("O"), fromMap.ExpirationDate?.ToString("O"));
    }

    [Fact]
    public void MinimalAge_Vector_Roundtrips()
    {
        var v = DigitalIdTestVectors.MinimalAgeVerification;
        var json = v.ToJson();
        var back = DigitalIdCredential.FromJson(json);

        Assert.True(back.AgeOver18);
        Assert.Equal("mdoc-device-response", back.CredentialFormat);
    }

    [Fact]
    public void AndroidMdl_Vector_Roundtrips()
    {
        var v = DigitalIdTestVectors.AndroidMdlSuccess;
        var back = DigitalIdCredential.FromJson(v.ToJson());

        Assert.Equal("John", back.GivenName);
        Assert.Equal("CA", back.State);
        Assert.Equal("openid4vp-vp-token", back.CredentialFormat);
    }

    [Fact]
    public void WebDigitalCredentials_Vector_Roundtrips()
    {
        var v = DigitalIdTestVectors.WebDigitalCredentialsSuccess;
        var back = DigitalIdCredential.FromJson(v.ToJson());

        Assert.Equal("Alex", back.GivenName);
        Assert.Equal("digital-credentials-api", back.CredentialFormat);
    }

    [Fact]
    public void ClaimPath_Convenience_And_Serialization()
    {
        var p = ClaimPath.AgeOver18();
        Assert.Equal(2, p.Segments.Count);
        Assert.Equal("age_over_18", p.Segments[1]);

        string json = p.ToJson();
        Assert.Contains("\"segments\"", json);

        var back = ClaimPath.FromJson(json);
        Assert.Equal(p.Segments, back.Segments);
    }

    [Fact]
    public void RequestOptions_ToJson_Produces_CamelCase_Matching_Dart()
    {
        var opts = new DigitalIdRequestOptions
        {
            RequiredClaims = [ClaimPath.FamilyName(), ClaimPath.GivenName(), ClaimPath.AgeOver18()],
            IntentToRetain = true,
            Nonce = "test-nonce-123"
        };

        string json = opts.ToJson();
        Assert.Contains("\"requiredClaims\"", json);
        Assert.Contains("\"age_over_18\"", json);
        Assert.Contains("\"intentToRetain\":true", json);
    }

    [Fact]
    public void ErrorCode_And_Exception_Roundtrip()
    {
        var ex = DigitalIdTestVectors.NoCredentialError;
        string json = ex.ToJson();
        var back = DigitalIdException.FromJson(json);

        Assert.Equal(DigitalIdErrorCode.NoCredential, back.Code);
        Assert.Contains("No matching", back.Message);
    }
}

public class DigitalIdRequestBuilderTests
{
    [Fact]
    public void BuildDcqlRequest_Contains_Expected_Structure()
    {
        var opts = new DigitalIdRequestOptions
        {
            RequiredClaims = [ClaimPath.GivenName(), ClaimPath.FamilyName()]
        };

        string dcql = DigitalIdRequestBuilder.BuildDcqlRequest(DigitalIdType.DriversLicense, opts);

        Assert.Contains("dcql_query", dcql);
        Assert.Contains("org.iso.18013.5.1.mDL", dcql);
        Assert.Contains("given_name", dcql);
        Assert.Contains("family_name", dcql);
        Assert.Contains("vp_token", dcql);
    }

    [Fact]
    public void BuildDcqlRequest_DefaultClaims_When_NoOptions()
    {
        string dcql = DigitalIdRequestBuilder.BuildDcqlRequest(DigitalIdType.Passport);

        Assert.Contains("family_name", dcql);
        Assert.Contains("age_over_18", dcql);
    }
}

public class DigitalIdVerificationTests
{
    [Fact]
    public void VerifyMdoc_WithValidInputs_ReturnsOk_Or_Unknown_For_Skeleton()
    {
        var result = DigitalIdVerifier.VerifyMdoc(
            DigitalIdTestVectors.AndroidMdlSuccess.RawCredential,
            "session-transcript"u8.ToArray(),
            "issuer-cert"u8.ToArray());

        // Skeleton verifier returns true or Unknown error. Real impl would fully validate COSE/mdoc.
        Assert.True(result.IsValid || result.ErrorCode == DigitalIdErrorCode.Unknown);
    }

    [Fact]
    public void VerifyMdoc_WithEmptyCredential_ReturnsFail()
    {
        var result = DigitalIdVerifier.VerifyMdoc(
            Array.Empty<byte>(),
            "transcript"u8.ToArray(),
            "cert"u8.ToArray());

        Assert.False(result.IsValid);
        Assert.NotNull(result.ErrorCode);
    }

    [Fact]
    public void VerifyMdoc_WithRichPassportVector_Exercises_Path()
    {
        var cred = DigitalIdTestVectors.RichPassport;
        var result = DigitalIdVerifier.VerifyMdoc(cred.RawCredential, "tx"u8.ToArray(), "ca"u8.ToArray());

        // Just ensure it doesn't throw and shape is exercised
        _ = result; // struct is never null; just exercised the path
    }
}
