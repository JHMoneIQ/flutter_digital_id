import 'dart:convert';
import 'dart:typed_data';

/// The result of a successful digital identity presentation.
///
/// Contains two parts that serve different consumers:
///
/// 1. **Structured fields** — immediately usable by the Flutter frontend to
///    pre-fill forms (name, address, DOB, age flags, portrait, etc.).
/// 2. **Raw cryptographic proof** (`rawCredential` + format) — must be sent
///    to the app's backend for signature validation, issuer trust, and
///    authoritative storage of the identity document before any account is
///    created or KYC record is persisted. The backend MUST NOT trust the
///    structured fields without validating the accompanying proof.
///
/// This design works across Apple (encrypted blob), Google Wallet / Web
/// (OpenID4VP vp_token / mdoc device response), and the companion C# library.
class DigitalIdCredential {
  const DigitalIdCredential({
    // Structured fields for frontend form pre-fill
    this.givenName,
    this.familyName,
    this.fullName,
    this.dateOfBirth,
    this.birthDate,
    this.ageOver18,
    this.ageOver21,
    this.ageInYears,
    this.ageBirthYear,
    this.sex,
    this.nationality,
    this.placeOfBirth,
    this.height,
    this.weight,
    this.eyeColour,
    this.hairColour,

    // Address / residency (especially valuable from DL)
    this.addressLine1,
    this.addressLine2,
    this.residentAddress,
    this.city,
    this.residentCity,
    this.state,
    this.residentState,
    this.postalCode,
    this.residentPostalCode,
    this.country,
    this.residentCountry,
    this.formattedAddress,

    // Document metadata
    this.documentNumber,
    this.documentType,
    this.issuingAuthority,
    this.issuingCountry,
    this.issueDate,
    this.expirationDate,
    this.drivingPrivileges,

    // Portrait / biometrics
    this.portrait,
    this.portraitMetadata,

    // Other high-value KYC signals
    this.organDonor,
    this.veteranStatus,
    this.dhsCompliance,
    this.temporaryLawfulStatus,
    this.drivingPrivilegesDetails,

    // Everything else the wallet actually disclosed (for future-proofing)
    this.allDisclosedClaims = const {},

    // Cryptographic proof for backend validation + storage
    required this.rawCredential,
    required this.credentialFormat,
    this.disclosedClaimPaths = const [],
    this.metadata = const {},
  });

  // --- Structured fields (nullable — only populated when disclosed) ---

  final String? givenName;
  final String? familyName;
  final String? fullName;
  final DateTime? dateOfBirth;
  final String? birthDate; // raw string form if needed
  final bool? ageOver18;
  final bool? ageOver21;
  final int? ageInYears;
  final int? ageBirthYear;
  final String? sex;
  final String? nationality;
  final String? placeOfBirth;
  final double? height;
  final double? weight;
  final String? eyeColour;
  final String? hairColour;

  final String? addressLine1;
  final String? addressLine2;
  final String? residentAddress;
  final String? city;
  final String? residentCity;
  final String? state;
  final String? residentState;
  final String? postalCode;
  final String? residentPostalCode;
  final String? country;
  final String? residentCountry;
  final String? formattedAddress;

  final String? documentNumber;
  final String? documentType;
  final String? issuingAuthority;
  final String? issuingCountry;
  final DateTime? issueDate;
  final DateTime? expirationDate;
  final String? drivingPrivileges;

  final Uint8List? portrait;
  final Map<String, dynamic>? portraitMetadata;

  final bool? organDonor;
  final String? veteranStatus;
  final String? dhsCompliance;
  final String? temporaryLawfulStatus;
  final String? drivingPrivilegesDetails;

  /// Raw map of every claim path + value that the wallet actually disclosed.
  /// Use this for fields not yet modeled above or for jurisdiction-specific data.
  final Map<String, dynamic> allDisclosedClaims;

  // --- Cryptographic proof (always present on success) ---

  /// The full verifiable presentation / encrypted blob / mdoc device response.
  /// This is what the app must send to its backend.
  final Uint8List rawCredential;

  /// Discriminator for the proof format, e.g. "apple-encrypted", "mdoc-device-response", "openid4vp-vp-token".
  final String credentialFormat;

  /// The exact set of claims the wallet returned (for audit / reconstruction).
  final List<String> disclosedClaimPaths;

  /// Additional metadata (nonce, issuer, timestamp, platform, session transcript, etc.).
  final Map<String, dynamic> metadata;

  @override
  String toString() =>
      'DigitalIdCredential($givenName $familyName, doc=$documentNumber, format=$credentialFormat, proofBytes=${rawCredential.length})';

  /// Hand-coded serialization (no code generation).
  /// This is the shape that should be sent to your backend along with the raw proof.
  Map<String, dynamic> toMap() => {
        'givenName': givenName,
        'familyName': familyName,
        'fullName': fullName,
        'dateOfBirth': dateOfBirth?.toIso8601String(),
        'birthDate': birthDate,
        'ageOver18': ageOver18,
        'ageOver21': ageOver21,
        'ageInYears': ageInYears,
        'ageBirthYear': ageBirthYear,
        'sex': sex,
        'nationality': nationality,
        'placeOfBirth': placeOfBirth,
        'height': height,
        'weight': weight,
        'eyeColour': eyeColour,
        'hairColour': hairColour,
        'addressLine1': addressLine1,
        'addressLine2': addressLine2,
        'residentAddress': residentAddress,
        'city': city,
        'residentCity': residentCity,
        'state': state,
        'residentState': residentState,
        'postalCode': postalCode,
        'residentPostalCode': residentPostalCode,
        'country': country,
        'residentCountry': residentCountry,
        'formattedAddress': formattedAddress,
        'documentNumber': documentNumber,
        'documentType': documentType,
        'issuingAuthority': issuingAuthority,
        'issuingCountry': issuingCountry,
        'issueDate': issueDate?.toIso8601String(),
        'expirationDate': expirationDate?.toIso8601String(),
        'drivingPrivileges': drivingPrivileges,
        'portrait': portrait != null ? base64Encode(portrait!) : null,
        'portraitMetadata': portraitMetadata,
        'organDonor': organDonor,
        'veteranStatus': veteranStatus,
        'dhsCompliance': dhsCompliance,
        'temporaryLawfulStatus': temporaryLawfulStatus,
        'drivingPrivilegesDetails': drivingPrivilegesDetails,
        'allDisclosedClaims': allDisclosedClaims,
        'rawCredential': base64Encode(rawCredential),
        'credentialFormat': credentialFormat,
        'disclosedClaimPaths': disclosedClaimPaths,
        'metadata': metadata,
      };

  factory DigitalIdCredential.fromMap(Map<String, dynamic> map) {
    Uint8List? decodeBase64(String? value) =>
        value != null ? base64Decode(value) : null;

    return DigitalIdCredential(
      givenName: map['givenName'] as String?,
      familyName: map['familyName'] as String?,
      fullName: map['fullName'] as String?,
      dateOfBirth: map['dateOfBirth'] != null
          ? DateTime.tryParse(map['dateOfBirth'] as String)
          : null,
      birthDate: map['birthDate'] as String?,
      ageOver18: map['ageOver18'] as bool?,
      ageOver21: map['ageOver21'] as bool?,
      ageInYears: map['ageInYears'] as int?,
      ageBirthYear: map['ageBirthYear'] as int?,
      sex: map['sex'] as String?,
      nationality: map['nationality'] as String?,
      placeOfBirth: map['placeOfBirth'] as String?,
      height: (map['height'] as num?)?.toDouble(),
      weight: (map['weight'] as num?)?.toDouble(),
      eyeColour: map['eyeColour'] as String?,
      hairColour: map['hairColour'] as String?,
      addressLine1: map['addressLine1'] as String?,
      addressLine2: map['addressLine2'] as String?,
      residentAddress: map['residentAddress'] as String?,
      city: map['city'] as String?,
      residentCity: map['residentCity'] as String?,
      state: map['state'] as String?,
      residentState: map['residentState'] as String?,
      postalCode: map['postalCode'] as String?,
      residentPostalCode: map['residentPostalCode'] as String?,
      country: map['country'] as String?,
      residentCountry: map['residentCountry'] as String?,
      formattedAddress: map['formattedAddress'] as String?,
      documentNumber: map['documentNumber'] as String?,
      documentType: map['documentType'] as String?,
      issuingAuthority: map['issuingAuthority'] as String?,
      issuingCountry: map['issuingCountry'] as String?,
      issueDate: map['issueDate'] != null
          ? DateTime.tryParse(map['issueDate'] as String)
          : null,
      expirationDate: map['expirationDate'] != null
          ? DateTime.tryParse(map['expirationDate'] as String)
          : null,
      drivingPrivileges: map['drivingPrivileges'] as String?,
      portrait: decodeBase64(map['portrait'] as String?),
      portraitMetadata: map['portraitMetadata'] != null
          ? Map<String, dynamic>.from(map['portraitMetadata'] as Map)
          : null,
      organDonor: map['organDonor'] as bool?,
      veteranStatus: map['veteranStatus'] as String?,
      dhsCompliance: map['dhsCompliance'] as String?,
      temporaryLawfulStatus: map['temporaryLawfulStatus'] as String?,
      drivingPrivilegesDetails: map['drivingPrivilegesDetails'] as String?,
      allDisclosedClaims: map['allDisclosedClaims'] != null
          ? Map<String, dynamic>.from(map['allDisclosedClaims'] as Map)
          : const {},
      rawCredential: decodeBase64(map['rawCredential'] as String) ?? Uint8List(0),
      credentialFormat: map['credentialFormat'] as String? ?? 'unknown',
      disclosedClaimPaths: (map['disclosedClaimPaths'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : const {},
    );
  }

  String toJson() => jsonEncode(toMap());

  factory DigitalIdCredential.fromJson(String source) =>
      DigitalIdCredential.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
