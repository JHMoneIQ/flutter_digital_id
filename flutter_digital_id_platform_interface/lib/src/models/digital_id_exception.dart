import 'dart:convert';

/// Represents an error that occurred while requesting a digital identity document.
class DigitalIdException implements Exception {
  const DigitalIdException({
    required this.code,
    this.message,
    this.details,
  });

  final DigitalIdErrorCode code;
  final String? message;
  final Object? details;

  @override
  String toString() => 'DigitalIdException($code${message != null ? ": $message" : ""})';

  Map<String, dynamic> toMap() => {
        'code': code.name,
        'message': message,
        'details': details?.toString(),
      };

  factory DigitalIdException.fromMap(Map<String, dynamic> map) {
    return DigitalIdException(
      code: DigitalIdErrorCode.values.firstWhere(
        (e) => e.name == map['code'],
        orElse: () => DigitalIdErrorCode.unknown,
      ),
      message: map['message'] as String?,
      details: map['details'],
    );
  }

  String toJson() => jsonEncode(toMap());

  factory DigitalIdException.fromJson(String source) =>
      DigitalIdException.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

/// Error codes for digital ID operations.
enum DigitalIdErrorCode {
  /// No digital ID of the requested type is available.
  notAvailable,

  /// The user cancelled the consent flow.
  userCancelled,

  /// The app is not entitled to request this type of document (Apple) or not registered as RP (Google).
  notEntitled,

  /// No matching credential was found (common on Android/Web).
  noCredential,

  /// The platform does not support this operation (e.g. desktop, unsupported browser).
  platformUnsupported,

  /// An unexpected error occurred.
  unknown,
}
