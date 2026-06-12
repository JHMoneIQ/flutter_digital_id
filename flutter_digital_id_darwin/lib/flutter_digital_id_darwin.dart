import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_digital_id_platform_interface/flutter_digital_id_platform_interface.dart';

/// iOS + macOS (darwin) implementation entrypoint.
///
/// Communicates with the thin native plugin via a MethodChannel for PassKit
/// identity document operations. We keep the native surface as small as possible.
class FlutterDigitalIdDarwin extends DigitalIdPlatform {
  static const MethodChannel _channel = MethodChannel(
    'flutter_digital_id/darwin',
  );

  static void registerWith() {
    DigitalIdPlatform.instance = FlutterDigitalIdDarwin._();
  }

  FlutterDigitalIdDarwin._();

  FlutterDigitalIdDarwin() : this._();

  @override
  Future<bool> isDigitalIdAvailable(
    DigitalIdType type, {
    DigitalIdRequestOptions? options,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('isDigitalIdAvailable', {
        'type': type.index,
        'options': options?.toMap(),
      });
      return result ?? false;
    } on PlatformException {
      // On macOS or unsupported iOS versions this will fail gracefully.
      return false;
    }
  }

  @override
  Future<bool> requestPermission(
    DigitalIdType type, {
    DigitalIdRequestOptions? options,
  }) async {
    // On iOS the consent UI is shown as part of the actual document request.
    // See platform interface docs for details on this compatibility no-op.
    return true;
  }

  @override
  Future<DigitalIdCredential?> getDigitalId(
    DigitalIdType type, {
    DigitalIdRequestOptions? options,
  }) async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'getDigitalId',
        {'type': type.index, 'options': options?.toMap()},
      );

      if (result == null) return null;

      final rawBase64 = result['rawCredential'] as String?;
      if (rawBase64 == null) return null;

      final rawBytes = base64Decode(rawBase64);

      final metadata = <String, dynamic>{
        'source': 'ios-passkit',
        'optionsUsed': options?.toMap(),
      };

      final nativeMetadata = result['metadata'];
      if (nativeMetadata is Map) {
        metadata.addAll(Map<String, dynamic>.from(nativeMetadata));
      }

      return DigitalIdCredential(
        rawCredential: rawBytes,
        credentialFormat:
            result['credentialFormat'] as String? ?? 'apple-encrypted',
        disclosedClaimPaths: (result['disclosedClaimPaths'] as List? ?? [])
            .cast<String>(),
        metadata: metadata,
        // Note: On real Apple Verify with Wallet responses, the app receives
        // primarily an encrypted blob. Rich structured fields should typically
        // be produced by your backend after decryption and verification.
      );
    } on PlatformException catch (e) {
      if (e.code == 'REQUEST_FAILED' || e.code == 'userCancelled') {
        return null;
      }
      if (e.code == 'NOT_ENTITLED') {
        throw DigitalIdException(
          code: DigitalIdErrorCode.notEntitled,
          message:
              e.message ??
              'Missing entitlement for digital ID request. See Apple Developer portal.',
        );
      }
      if (e.code == 'PLATFORM_UNSUPPORTED') {
        throw DigitalIdException(
          code: DigitalIdErrorCode.platformUnsupported,
          message: e.message,
        );
      }
      rethrow;
    }
  }
}
