using System.Text.Json;
using System.Text.Json.Serialization;

namespace DigitalId;

/// <summary>
/// Represents a path to a specific claim inside a digital credential (mdoc style).
/// Matches the Dart ClaimPath shape exactly for interoperability.
/// </summary>
[JsonSourceGenerationOptions(PropertyNamingPolicy = JsonKnownNamingPolicy.CamelCase)]
public sealed record ClaimPath
{
    [JsonPropertyName("segments")]
    public IReadOnlyList<string> Segments { get; }

    public ClaimPath(params string[] segments)
    {
        Segments = segments ?? throw new ArgumentNullException(nameof(segments));
    }

    public ClaimPath(IEnumerable<string> segments)
    {
        Segments = segments?.ToArray() ?? throw new ArgumentNullException(nameof(segments));
    }

    [JsonConstructor]
    public ClaimPath(IReadOnlyList<string> segments)
    {
        Segments = segments ?? throw new ArgumentNullException(nameof(segments));
    }

    // Convenience constructors for common claims (mdoc / ISO 18013-5.1)
    public static ClaimPath FamilyName() => new("org.iso.18013.5.1", "family_name");
    public static ClaimPath GivenName() => new("org.iso.18013.5.1", "given_name");
    public static ClaimPath BirthDate() => new("org.iso.18013.5.1", "birth_date");
    public static ClaimPath AgeOver18() => new("org.iso.18013.5.1", "age_over_18");
    public static ClaimPath AgeOver21() => new("org.iso.18013.5.1", "age_over_21");
    public static ClaimPath Portrait() => new("org.iso.18013.5.1", "portrait");
    public static ClaimPath DocumentNumber() => new("org.iso.18013.5.1", "document_number");

    /// <summary>
    /// Hand-coded serialization (no reflection-heavy generators at runtime).
    /// Produces camelCase JSON matching the Flutter/Dart side exactly.
    /// </summary>
    public string ToJson() => JsonSerializer.Serialize(this, DigitalIdJsonContext.Default.ClaimPath);

    public static ClaimPath FromJson(string json) =>
        JsonSerializer.Deserialize(json, DigitalIdJsonContext.Default.ClaimPath) ?? throw new ArgumentException("Invalid ClaimPath JSON");

    /// <summary>
    /// Map form using the same camelCase keys as Dart toMap().
    /// </summary>
    public Dictionary<string, object?> ToMap() => new()
    {
        ["segments"] = Segments.ToList()
    };

    public static ClaimPath FromMap(Dictionary<string, object?> map)
    {
        if (map.TryGetValue("segments", out var segmentsObj) && segmentsObj is IEnumerable<object> segments)
        {
            return new ClaimPath(segments.Select(s => s.ToString()!).ToArray());
        }
        throw new ArgumentException("Invalid ClaimPath map");
    }
}
