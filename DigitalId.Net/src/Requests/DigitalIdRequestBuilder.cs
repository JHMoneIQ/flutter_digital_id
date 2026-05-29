using System.Text.Json;

namespace DigitalId.Requests;

/// <summary>
/// Builds OpenID4VP / DCQL requests from the cross-platform options.
/// </summary>
public static class DigitalIdRequestBuilder
{
    public static string BuildDcqlRequest(
        DigitalIdType type,
        DigitalIdRequestOptions? options = null,
        bool unsigned = true)
    {
        var doctype = MapTypeToDoctype(type);

        var claims = new List<object>();

        var required = options?.RequiredClaims ?? Array.Empty<ClaimPath>();
        var optional = options?.OptionalClaims ?? Array.Empty<ClaimPath>();

        foreach (var claim in required.Concat(optional))
        {
            claims.Add(new
            {
                path = claim.Segments,
                intent_to_retain = options?.IntentToRetain ?? false
            });
        }

        if (claims.Count == 0)
        {
            claims.AddRange(new object[]
            {
                new { path = new[] { "org.iso.18013.5.1", "family_name" }, intent_to_retain = false },
                new { path = new[] { "org.iso.18013.5.1", "given_name" }, intent_to_retain = false },
                new { path = new[] { "org.iso.18013.5.1", "age_over_18" }, intent_to_retain = false }
            });
        }

        var dcql = new
        {
            response_type = "vp_token",
            dcql_query = new
            {
                credentials = new[]
                {
                    new
                    {
                        id = "cred1",
                        format = "mso_mdoc",
                        meta = new { doctype_value = doctype },
                        claims = claims
                    }
                }
            }
        };

        if (unsigned)
        {
            return JsonSerializer.Serialize(new { requests = new[] { dcql } });
        }

        // Signed request (JAR) would go here - placeholder for now
        throw new NotImplementedException("Signed requests not yet implemented in this skeleton.");
    }

    private static string MapTypeToDoctype(DigitalIdType type) => type switch
    {
        DigitalIdType.DriversLicense => "org.iso.18013.5.1.mDL",
        DigitalIdType.Passport or DigitalIdType.EuDigitalId => "com.google.wallet.idcard.1",
        DigitalIdType.AgeVerificationOnly => "org.iso.18013.5.1.mDL",
        _ => "org.iso.18013.5.1.mDL"
    };
}
