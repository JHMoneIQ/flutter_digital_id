import 'dart:convert';

/// Represents a path to a specific claim inside a digital credential.
///
/// For mdoc / ISO 18013-5 credentials this is typically a list such as
/// `['org.iso.18013.5.1', 'family_name']`.
///
/// For Apple PassKit identity descriptors the path is mapped internally to
/// the corresponding `PKIdentityElement`.
///
/// Using a typed path object gives us future-proofing and nice APIs for
/// common claims while still allowing fully custom paths for advanced RPs.
class ClaimPath {
  const ClaimPath(this.segments);

  /// Convenience constructors for the most common claims.
  factory ClaimPath.familyName() => const ClaimPath(['org.iso.18013.5.1', 'family_name']);
  factory ClaimPath.givenName() => const ClaimPath(['org.iso.18013.5.1', 'given_name']);
  factory ClaimPath.birthDate() => const ClaimPath(['org.iso.18013.5.1', 'birth_date']);
  factory ClaimPath.ageOver18() => const ClaimPath(['org.iso.18013.5.1', 'age_over_18']);
  factory ClaimPath.ageOver21() => const ClaimPath(['org.iso.18013.5.1', 'age_over_21']);
  /// Returns a path for age_over_NN. Many wallets support dynamic age thresholds
  /// (e.g. age_over_16, age_over_25). Falls back to closest standard for 18/21.
  factory ClaimPath.ageOver(int age) {
    if (age <= 18) return ClaimPath.ageOver18();
    if (age <= 21) return ClaimPath.ageOver21();
    return ClaimPath(['org.iso.18013.5.1', 'age_over_$age']);
  }

  factory ClaimPath.portrait() => const ClaimPath(['org.iso.18013.5.1', 'portrait']);
  factory ClaimPath.documentNumber() => const ClaimPath(['org.iso.18013.5.1', 'document_number']);

  final List<String> segments;

  @override
  String toString() => segments.join('.');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClaimPath &&
          runtimeType == other.runtimeType &&
          _listEquals(segments, other.segments);

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(segments);

  /// Hand-coded serialization (no code generation).
  Map<String, dynamic> toMap() => {'segments': segments};

  factory ClaimPath.fromMap(Map<String, dynamic> map) {
    final raw = map['segments'];
    if (raw is List) {
      return ClaimPath(raw.whereType<String>().toList());
    }
    return const ClaimPath([]);
  }

  String toJson() => jsonEncode(toMap());

  factory ClaimPath.fromJson(String source) =>
      ClaimPath.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
