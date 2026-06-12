using System.Text.Json;
using System.Text.Json.Serialization;

namespace DigitalId;

/// <summary>
/// Represents an error that occurred during a digital identity request or verification.
/// </summary>
public sealed record DigitalIdException
{
    /// <summary>
    /// The machine-readable error code.
    /// </summary>
    [JsonPropertyName("code")]
    public required DigitalIdErrorCode Code { get; init; }

    /// <summary>
    /// Human-readable description of the error.
    /// </summary>
    [JsonPropertyName("message")]
    public string? Message { get; init; }

    /// <summary>
    /// Additional diagnostic details (if any).
    /// </summary>
    [JsonPropertyName("details")]
    public object? Details { get; init; }

    /// <summary>
    /// Hand-coded JSON matching Dart DigitalIdException.toJson() shape.
    /// </summary>
    public string ToJson() => JsonSerializer.Serialize(this, DigitalIdJsonContext.Default.DigitalIdException);

    public static DigitalIdException FromJson(string json) =>
        JsonSerializer.Deserialize(json, DigitalIdJsonContext.Default.DigitalIdException) ?? throw new ArgumentException("Invalid DigitalIdException JSON");

    public Dictionary<string, object?> ToMap() => new()
    {
        ["code"] = Code.ToString(),
        ["message"] = Message,
        ["details"] = Details
    };

    public static DigitalIdException FromMap(Dictionary<string, object?> map) => new()
    {
        Code = Enum.TryParse<DigitalIdErrorCode>(map.TryGetValue("code", out var c) ? c?.ToString() : null, out var code) ? code : DigitalIdErrorCode.Unknown,
        Message = map.TryGetValue("message", out var m) ? m?.ToString() : null,
        Details = map.TryGetValue("details", out var d) ? d : null
    };
}

/// <summary>
/// Error codes matching the Dart DigitalIdErrorCode enum.
/// </summary>
[JsonConverter(typeof(JsonStringEnumConverter<DigitalIdErrorCode>))]
public enum DigitalIdErrorCode
{
    /// <summary>No digital ID of the requested type is available on this device/platform.</summary>
    NotAvailable,

    /// <summary>The user explicitly cancelled the identity presentation.</summary>
    UserCancelled,

    /// <summary>The app is not entitled (Apple) or not registered as a relying party (Google) for this feature.</summary>
    NotEntitled,

    /// <summary>No matching credential was found for the request.</summary>
    NoCredential,

    /// <summary>The current platform or OS version does not support digital identity presentment.</summary>
    PlatformUnsupported,

    /// <summary>An unexpected or unknown error occurred.</summary>
    Unknown
}
