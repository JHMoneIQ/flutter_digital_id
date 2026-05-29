namespace DigitalId;

/// <summary>
/// The type of government-issued digital identity document.
/// </summary>
public enum DigitalIdType
{
    /// <summary>Passport or passport-derived Digital ID.</summary>
    Passport,

    /// <summary>EU Digital Identity / eIDAS PID or national eID.</summary>
    EuDigitalId,

    /// <summary>Driver's license or mobile Driver's License (mDL).</summary>
    DriversLicense,

    /// <summary>Special mode for age verification only (minimal disclosure).</summary>
    AgeVerificationOnly,
}
