using System.Text.Json.Serialization;

namespace DigitalId;

/// <summary>
/// Source-generated JsonSerializerContext for AOT trimming/performance and consistent camelCase handling.
/// Mirrors the pattern used in ProjectFulcrum Contracts/Messages.
/// All hand-coded ToJson/FromJson methods in this library prefer this context.
/// </summary>
[JsonSourceGenerationOptions(
    PropertyNamingPolicy = JsonKnownNamingPolicy.CamelCase,
    WriteIndented = false,
    DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull)]
[JsonSerializable(typeof(ClaimPath))]
[JsonSerializable(typeof(DigitalIdRequestOptions))]
[JsonSerializable(typeof(DigitalIdCredential))]
[JsonSerializable(typeof(DigitalIdException))]
[JsonSerializable(typeof(DigitalIdErrorCode))]
public partial class DigitalIdJsonContext : JsonSerializerContext
{
}