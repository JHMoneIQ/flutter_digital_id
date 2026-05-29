import 'package:flutter_digital_id_platform_interface/flutter_digital_id_platform_interface.dart';

/// In-memory mock implementation useful for unit testing the public API
/// and serialization without requiring a physical device or simulator.
class MockDigitalIdPlatform extends DigitalIdPlatform {
  bool _available = true;
  DigitalIdCredential? _nextResult;
  Object? _nextError;

  void setAvailable(bool value) => _available = value;

  void setNextResult(DigitalIdCredential? credential) {
    _nextResult = credential;
    _nextError = null;
  }

  void setNextError(Object error) {
    _nextError = error;
    _nextResult = null;
  }

  @override
  Future<bool> isDigitalIdAvailable(
    DigitalIdType type, {
    DigitalIdRequestOptions? options,
  }) async {
    return _available;
  }

  @override
  Future<bool> requestPermission(
    DigitalIdType type, {
    DigitalIdRequestOptions? options,
  }) async {
    return _available;
  }

  @override
  Future<DigitalIdCredential?> getDigitalId(
    DigitalIdType type, {
    DigitalIdRequestOptions? options,
  }) async {
    if (_nextError != null) {
      // Simulate user cancellation or expected failure by returning null
      // (this matches the public API contract in the plan).
      if (_nextError.toString().contains('cancel')) {
        return null;
      }
      throw _nextError!;
    }
    return _nextResult;
  }
}
