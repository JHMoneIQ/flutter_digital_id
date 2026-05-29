using System.Text.Json;
using System.Text.Json.Serialization;

namespace DigitalId;

public sealed record DigitalIdException
{
    [JsonPropertyName("code")]
    public required DigitalIdErrorCode Code { get; init; }

    [JsonPropertyName("message")]
    public string? Message { get; init; }

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
    NotAvailable,
    UserCancelled,
    NotEntitled,
    NoCredential,
    PlatformUnsupported,
    Unknown
}
