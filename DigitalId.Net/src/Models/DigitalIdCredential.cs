using System.Text.Json;
using System.Text.Json.Serialization;

namespace DigitalId;

/// <summary>
/// The result of a successful digital identity presentation.
/// Contains both structured fields (for immediate frontend use) and the raw cryptographic proof (for backend validation).
/// Hand-coded serialization + attributes produce exact camelCase + base64/ISO shape matching Flutter/Dart.
/// </summary>
public sealed record DigitalIdCredential
{
    // --- Structured fields (nullable - only populated when disclosed) ---

    [JsonPropertyName("givenName")]
    public string? GivenName { get; init; }

    [JsonPropertyName("familyName")]
    public string? FamilyName { get; init; }

    [JsonPropertyName("fullName")]
    public string? FullName { get; init; }

    [JsonPropertyName("dateOfBirth")]
    public DateTimeOffset? DateOfBirth { get; init; }

    [JsonPropertyName("birthDate")]
    public string? BirthDate { get; init; }

    [JsonPropertyName("ageOver18")]
    public bool? AgeOver18 { get; init; }

    [JsonPropertyName("ageOver21")]
    public bool? AgeOver21 { get; init; }

    [JsonPropertyName("ageInYears")]
    public int? AgeInYears { get; init; }

    [JsonPropertyName("ageBirthYear")]
    public int? AgeBirthYear { get; init; }

    [JsonPropertyName("sex")]
    public string? Sex { get; init; }

    [JsonPropertyName("nationality")]
    public string? Nationality { get; init; }

    [JsonPropertyName("placeOfBirth")]
    public string? PlaceOfBirth { get; init; }

    [JsonPropertyName("height")]
    public double? Height { get; init; }

    [JsonPropertyName("weight")]
    public double? Weight { get; init; }

    [JsonPropertyName("eyeColour")]
    public string? EyeColour { get; init; }

    [JsonPropertyName("hairColour")]
    public string? HairColour { get; init; }

    // Address / residency
    [JsonPropertyName("addressLine1")]
    public string? AddressLine1 { get; init; }

    [JsonPropertyName("addressLine2")]
    public string? AddressLine2 { get; init; }

    [JsonPropertyName("residentAddress")]
    public string? ResidentAddress { get; init; }

    [JsonPropertyName("city")]
    public string? City { get; init; }

    [JsonPropertyName("residentCity")]
    public string? ResidentCity { get; init; }

    [JsonPropertyName("state")]
    public string? State { get; init; }

    [JsonPropertyName("residentState")]
    public string? ResidentState { get; init; }

    [JsonPropertyName("postalCode")]
    public string? PostalCode { get; init; }

    [JsonPropertyName("residentPostalCode")]
    public string? ResidentPostalCode { get; init; }

    [JsonPropertyName("country")]
    public string? Country { get; init; }

    [JsonPropertyName("residentCountry")]
    public string? ResidentCountry { get; init; }

    [JsonPropertyName("formattedAddress")]
    public string? FormattedAddress { get; init; }

    // Document metadata
    [JsonPropertyName("documentNumber")]
    public string? DocumentNumber { get; init; }

    [JsonPropertyName("documentType")]
    public string? DocumentType { get; init; }

    [JsonPropertyName("issuingAuthority")]
    public string? IssuingAuthority { get; init; }

    [JsonPropertyName("issuingCountry")]
    public string? IssuingCountry { get; init; }

    [JsonPropertyName("issueDate")]
    public DateTimeOffset? IssueDate { get; init; }

    [JsonPropertyName("expirationDate")]
    public DateTimeOffset? ExpirationDate { get; init; }

    [JsonPropertyName("drivingPrivileges")]
    public string? DrivingPrivileges { get; init; }

    // Portrait / biometrics
    [JsonPropertyName("portrait")]
    public byte[]? Portrait { get; init; }

    [JsonPropertyName("portraitMetadata")]
    public Dictionary<string, object?>? PortraitMetadata { get; init; }

    // Other KYC signals
    [JsonPropertyName("organDonor")]
    public bool? OrganDonor { get; init; }

    [JsonPropertyName("veteranStatus")]
    public string? VeteranStatus { get; init; }

    [JsonPropertyName("dhsCompliance")]
    public string? DhsCompliance { get; init; }

    [JsonPropertyName("temporaryLawfulStatus")]
    public string? TemporaryLawfulStatus { get; init; }

    [JsonPropertyName("drivingPrivilegesDetails")]
    public string? DrivingPrivilegesDetails { get; init; }

    /// <summary>
    /// Raw map of every claim that was actually disclosed.
    /// </summary>
    [JsonPropertyName("allDisclosedClaims")]
    public Dictionary<string, object?> AllDisclosedClaims { get; init; } = new();

    // --- Cryptographic proof (always present on success) ---

    /// <summary>
    /// The full verifiable presentation / encrypted blob / mdoc device response.
    /// This is what must be sent to your backend for validation.
    /// </summary>
    [JsonPropertyName("rawCredential")]
    public required byte[] RawCredential { get; init; }

    [JsonPropertyName("credentialFormat")]
    public required string CredentialFormat { get; init; }

    [JsonPropertyName("disclosedClaimPaths")]
    public IReadOnlyList<string> DisclosedClaimPaths { get; init; } = Array.Empty<string>();

    [JsonPropertyName("metadata")]
    public Dictionary<string, object?> Metadata { get; init; } = new();

    /// <summary>
    /// Hand-coded serialization (no source generators at runtime).
    /// Produces exact camelCase + base64/ISO matching the Dart toJson()/toMap().
    /// </summary>
    public string ToJson() => JsonSerializer.Serialize(this, DigitalIdJsonContext.Default.DigitalIdCredential);

    public static DigitalIdCredential FromJson(string json) =>
        JsonSerializer.Deserialize(json, DigitalIdJsonContext.Default.DigitalIdCredential) ?? throw new ArgumentException("Invalid DigitalIdCredential JSON");

    /// <summary>
    /// Produces a map with exact camelCase keys and base64/ISO values matching Dart toMap().
    /// </summary>
    public Dictionary<string, object?> ToMap()
    {
        static string? ToIso(DateTimeOffset? dt) => dt?.ToString("O");
        static string? ToB64(byte[]? b) => b != null ? Convert.ToBase64String(b) : null;

        return new Dictionary<string, object?>
        {
            ["givenName"] = GivenName,
            ["familyName"] = FamilyName,
            ["fullName"] = FullName,
            ["dateOfBirth"] = ToIso(DateOfBirth),
            ["birthDate"] = BirthDate,
            ["ageOver18"] = AgeOver18,
            ["ageOver21"] = AgeOver21,
            ["ageInYears"] = AgeInYears,
            ["ageBirthYear"] = AgeBirthYear,
            ["sex"] = Sex,
            ["nationality"] = Nationality,
            ["placeOfBirth"] = PlaceOfBirth,
            ["height"] = Height,
            ["weight"] = Weight,
            ["eyeColour"] = EyeColour,
            ["hairColour"] = HairColour,
            ["addressLine1"] = AddressLine1,
            ["addressLine2"] = AddressLine2,
            ["residentAddress"] = ResidentAddress,
            ["city"] = City,
            ["residentCity"] = ResidentCity,
            ["state"] = State,
            ["residentState"] = ResidentState,
            ["postalCode"] = PostalCode,
            ["residentPostalCode"] = ResidentPostalCode,
            ["country"] = Country,
            ["residentCountry"] = ResidentCountry,
            ["formattedAddress"] = FormattedAddress,
            ["documentNumber"] = DocumentNumber,
            ["documentType"] = DocumentType,
            ["issuingAuthority"] = IssuingAuthority,
            ["issuingCountry"] = IssuingCountry,
            ["issueDate"] = ToIso(IssueDate),
            ["expirationDate"] = ToIso(ExpirationDate),
            ["drivingPrivileges"] = DrivingPrivileges,
            ["portrait"] = ToB64(Portrait),
            ["portraitMetadata"] = PortraitMetadata,
            ["organDonor"] = OrganDonor,
            ["veteranStatus"] = VeteranStatus,
            ["dhsCompliance"] = DhsCompliance,
            ["temporaryLawfulStatus"] = TemporaryLawfulStatus,
            ["drivingPrivilegesDetails"] = DrivingPrivilegesDetails,
            ["allDisclosedClaims"] = AllDisclosedClaims,
            ["rawCredential"] = Convert.ToBase64String(RawCredential),
            ["credentialFormat"] = CredentialFormat,
            ["disclosedClaimPaths"] = DisclosedClaimPaths.ToList(),
            ["metadata"] = Metadata,
        };
    }

    public static DigitalIdCredential FromMap(Dictionary<string, object?> map)
    {
        static byte[]? DecodeB64(string? s) => s != null ? Convert.FromBase64String(s) : null;
        static DateTimeOffset? ParseIso(string? s) => s != null ? DateTimeOffset.Parse(s) : null;

        byte[] raw = DecodeB64(map.TryGetValue("rawCredential", out var rawObj) ? rawObj as string : null)
                     ?? throw new ArgumentException("Missing or invalid rawCredential (base64 expected)");

        string credFormat = (map.TryGetValue("credentialFormat", out var cf) ? cf as string : null) ?? "unknown";

        var disclosed = (map.TryGetValue("disclosedClaimPaths", out var dcp) && dcp is IEnumerable<object> dcpl)
            ? dcpl.Select(o => o?.ToString() ?? "").ToList()
            : new List<string>();

        var allClaims = map.TryGetValue("allDisclosedClaims", out var adc) && adc is Dictionary<string, object?> adcd ? adcd : new Dictionary<string, object?>();
        var meta = map.TryGetValue("metadata", out var m) && m is Dictionary<string, object?> md ? md : new Dictionary<string, object?>();

        return new DigitalIdCredential
        {
            GivenName = map.TryGetValue("givenName", out var v) ? v as string : null,
            FamilyName = map.TryGetValue("familyName", out v) ? v as string : null,
            FullName = map.TryGetValue("fullName", out v) ? v as string : null,
            DateOfBirth = ParseIso(map.TryGetValue("dateOfBirth", out v) ? v as string : null),
            BirthDate = map.TryGetValue("birthDate", out v) ? v as string : null,
            AgeOver18 = map.TryGetValue("ageOver18", out v) ? v as bool? : null,
            AgeOver21 = map.TryGetValue("ageOver21", out v) ? v as bool? : null,
            AgeInYears = map.TryGetValue("ageInYears", out v) ? v as int? : null,
            AgeBirthYear = map.TryGetValue("ageBirthYear", out v) ? v as int? : null,
            Sex = map.TryGetValue("sex", out v) ? v as string : null,
            Nationality = map.TryGetValue("nationality", out v) ? v as string : null,
            PlaceOfBirth = map.TryGetValue("placeOfBirth", out v) ? v as string : null,
            Height = map.TryGetValue("height", out v) && v is IConvertible cH ? cH.ToDouble(null) : null,
            Weight = map.TryGetValue("weight", out v) && v is IConvertible cW ? cW.ToDouble(null) : null,
            EyeColour = map.TryGetValue("eyeColour", out v) ? v as string : null,
            HairColour = map.TryGetValue("hairColour", out v) ? v as string : null,
            AddressLine1 = map.TryGetValue("addressLine1", out v) ? v as string : null,
            AddressLine2 = map.TryGetValue("addressLine2", out v) ? v as string : null,
            ResidentAddress = map.TryGetValue("residentAddress", out v) ? v as string : null,
            City = map.TryGetValue("city", out v) ? v as string : null,
            ResidentCity = map.TryGetValue("residentCity", out v) ? v as string : null,
            State = map.TryGetValue("state", out v) ? v as string : null,
            ResidentState = map.TryGetValue("residentState", out v) ? v as string : null,
            PostalCode = map.TryGetValue("postalCode", out v) ? v as string : null,
            ResidentPostalCode = map.TryGetValue("residentPostalCode", out v) ? v as string : null,
            Country = map.TryGetValue("country", out v) ? v as string : null,
            ResidentCountry = map.TryGetValue("residentCountry", out v) ? v as string : null,
            FormattedAddress = map.TryGetValue("formattedAddress", out v) ? v as string : null,
            DocumentNumber = map.TryGetValue("documentNumber", out v) ? v as string : null,
            DocumentType = map.TryGetValue("documentType", out v) ? v as string : null,
            IssuingAuthority = map.TryGetValue("issuingAuthority", out v) ? v as string : null,
            IssuingCountry = map.TryGetValue("issuingCountry", out v) ? v as string : null,
            IssueDate = ParseIso(map.TryGetValue("issueDate", out v) ? v as string : null),
            ExpirationDate = ParseIso(map.TryGetValue("expirationDate", out v) ? v as string : null),
            DrivingPrivileges = map.TryGetValue("drivingPrivileges", out v) ? v as string : null,
            Portrait = DecodeB64(map.TryGetValue("portrait", out v) ? v as string : null),
            PortraitMetadata = map.TryGetValue("portraitMetadata", out var pm) && pm is Dictionary<string, object?> pmd ? pmd : null,
            OrganDonor = map.TryGetValue("organDonor", out v) ? v as bool? : null,
            VeteranStatus = map.TryGetValue("veteranStatus", out v) ? v as string : null,
            DhsCompliance = map.TryGetValue("dhsCompliance", out v) ? v as string : null,
            TemporaryLawfulStatus = map.TryGetValue("temporaryLawfulStatus", out v) ? v as string : null,
            DrivingPrivilegesDetails = map.TryGetValue("drivingPrivilegesDetails", out v) ? v as string : null,
            AllDisclosedClaims = allClaims,
            RawCredential = raw,
            CredentialFormat = credFormat,
            DisclosedClaimPaths = disclosed,
            Metadata = meta
        };
    }
}
