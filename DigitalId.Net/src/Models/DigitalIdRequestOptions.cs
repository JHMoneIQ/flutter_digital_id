using System.Text.Json;
using System.Text.Json.Serialization;

namespace DigitalId;

/// <summary>
/// Controls what data is requested from a digital identity document (selective disclosure).
/// Matches Dart DigitalIdRequestOptions exactly for cross-platform use.
/// </summary>
public sealed record DigitalIdRequestOptions
{
    [JsonPropertyName("requiredClaims")]
    public IReadOnlyList<ClaimPath> RequiredClaims { get; init; } = [];

    [JsonPropertyName("optionalClaims")]
    public IReadOnlyList<ClaimPath> OptionalClaims { get; init; } = [];

    [JsonPropertyName("intentToRetain")]
    public bool IntentToRetain { get; init; }

    [JsonPropertyName("nonce")]
    public string? Nonce { get; init; }

    [JsonPropertyName("allowMultipleCredentials")]
    public bool AllowMultipleCredentials { get; init; }

    /// <summary>
    /// Platform-specific escape hatch (advanced use only).
    /// </summary>
    [JsonPropertyName("platformOptions")]
    public Dictionary<string, object?>? PlatformOptions { get; init; }

    /// <summary>
    /// Hand-coded serialization producing camelCase JSON matching Flutter toJson().
    /// </summary>
    public string ToJson() => JsonSerializer.Serialize(this, DigitalIdJsonContext.Default.DigitalIdRequestOptions);

    public static DigitalIdRequestOptions FromJson(string json) =>
        JsonSerializer.Deserialize(json, DigitalIdJsonContext.Default.DigitalIdRequestOptions) ?? throw new ArgumentException("Invalid DigitalIdRequestOptions JSON");

    /// <summary>
    /// Map using exact camelCase keys from Dart toMap().
    /// </summary>
    public Dictionary<string, object?> ToMap() => new()
    {
        ["requiredClaims"] = RequiredClaims.Select(c => c.ToMap()).ToList(),
        ["optionalClaims"] = OptionalClaims.Select(c => c.ToMap()).ToList(),
        ["intentToRetain"] = IntentToRetain,
        ["nonce"] = Nonce,
        ["allowMultipleCredentials"] = AllowMultipleCredentials,
        ["platformOptions"] = PlatformOptions
    };

    public static DigitalIdRequestOptions FromMap(Dictionary<string, object?> map)
    {
        var reqClaims = new List<ClaimPath>();
        if (map.TryGetValue("requiredClaims", out var req) && req is IEnumerable<object> reqList)
        {
            reqClaims = reqList
                .OfType<Dictionary<string, object?>>()
                .Select(ClaimPath.FromMap)
                .ToList();
        }

        var optClaims = new List<ClaimPath>();
        if (map.TryGetValue("optionalClaims", out var opt) && opt is IEnumerable<object> optList)
        {
            optClaims = optList
                .OfType<Dictionary<string, object?>>()
                .Select(ClaimPath.FromMap)
                .ToList();
        }

        return new DigitalIdRequestOptions
        {
            RequiredClaims = reqClaims,
            OptionalClaims = optClaims,
            IntentToRetain = map.TryGetValue("intentToRetain", out var ir) && ir is bool b && b,
            Nonce = map.TryGetValue("nonce", out var n) ? n?.ToString() : null,
            AllowMultipleCredentials = map.TryGetValue("allowMultipleCredentials", out var amc) && amc is bool b2 && b2,
            PlatformOptions = map.TryGetValue("platformOptions", out var po) && po is Dictionary<string, object?> pod ? pod : null
        };
    }
}
