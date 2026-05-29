import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../flutter_digital_id_platform_interface.dart';

/// The interface that every platform implementation of flutter_digital_id must implement.
abstract class DigitalIdPlatform extends PlatformInterface {
  DigitalIdPlatform() : super(token: _token);

  static final Object _token = Object();

  static DigitalIdPlatform _instance = _DigitalIdPlatformStub();

  static DigitalIdPlatform get instance => _instance;

  static set instance(DigitalIdPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Returns true if a digital identity document of the given type is
  /// present and can be requested without immediately triggering a user
  /// consent prompt (where the platform supports a silent check).
  Future<bool> isDigitalIdAvailable(
    DigitalIdType type, {
    DigitalIdRequestOptions? options,
  });

  /// Triggers the platform consent UI for the requested document type and
  /// options. Returns true if the user granted the request.
  ///
  /// NOTE: On Android, iOS, and Web the actual consent UI is typically shown
  /// inside the [getDigitalId] flow (one-shot presentation). This method is
  /// provided for API compatibility and pre-flight checks; current platform
  /// implementations treat it as a no-op that returns `true` (meaning "the
  /// platform will request consent at presentation time").
  ///
  /// On desktop / unsupported platforms it returns false.
  Future<bool> requestPermission(
    DigitalIdType type, {
    DigitalIdRequestOptions? options,
  });

  /// The core method. Requests the digital identity document using the
  /// supplied options (selective disclosure).
  ///
  /// On success returns a [DigitalIdCredential] containing both the
  /// structured fields (for immediate frontend use) and the raw
  /// cryptographic proof (to be sent to the backend for validation).
  ///
  /// Returns null on user cancellation or failure (inspect the thrown
  /// exception for details).
  Future<DigitalIdCredential?> getDigitalId(
    DigitalIdType type, {
    DigitalIdRequestOptions? options,
  });
}

/// Default stub used before any platform registers itself.
class _DigitalIdPlatformStub extends DigitalIdPlatform {
  @override
  Future<bool> isDigitalIdAvailable(
    DigitalIdType type, {
    DigitalIdRequestOptions? options,
  }) =>
      Future.value(false);

  @override
  Future<bool> requestPermission(
    DigitalIdType type, {
    DigitalIdRequestOptions? options,
  }) =>
      Future.value(false);

  @override
  Future<DigitalIdCredential?> getDigitalId(
    DigitalIdType type, {
    DigitalIdRequestOptions? options,
  }) =>
      Future.error(
        UnsupportedError(
          'No implementation of DigitalIdPlatform has been registered. '
          'Make sure the platform-specific package is added as a dependency.',
        ),
      );
}
