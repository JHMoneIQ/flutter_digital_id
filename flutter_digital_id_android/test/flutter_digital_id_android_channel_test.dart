import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_digital_id_android/flutter_digital_id_android.dart';
import 'package:flutter_digital_id_platform_interface/flutter_digital_id_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('flutter_digital_id/android');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() async {
    messenger.setMockMethodCallHandler(channel, null);
  });

  tearDown(() async {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('maps native successful response into DigitalIdCredential', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'getDigitalId');
      return <String, dynamic>{
        'rawCredential': base64Encode(Uint8List.fromList([1, 2, 3, 4])),
        'credentialFormat': 'openid4vp-vp-token',
      };
    });

    final impl = FlutterDigitalIdAndroid();
    final credential = await impl.getDigitalId(DigitalIdType.driversLicense);

    expect(credential, isNotNull);
    expect(credential!.rawCredential, Uint8List.fromList([1, 2, 3, 4]));
    expect(credential.credentialFormat, 'openid4vp-vp-token');
    expect(credential.metadata['source'], 'android-credential-manager');
  });

  test(
    'returns null for NoCredential, userCancelled, and NO_ACTIVITY errors',
    () async {
      final impl = FlutterDigitalIdAndroid();

      for (final code in ['NoCredential', 'userCancelled', 'NO_ACTIVITY']) {
        messenger.setMockMethodCallHandler(channel, (call) async {
          throw PlatformException(code: code, message: 'simulated');
        });

        final credential = await impl.getDigitalId(
          DigitalIdType.driversLicense,
        );
        expect(credential, isNull, reason: 'expected null for code $code');
      }
    },
  );

  test('passes through unexpected platform exceptions', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'UNKNOWN', message: 'boom');
    });

    final impl = FlutterDigitalIdAndroid();

    expect(
      () => impl.getDigitalId(DigitalIdType.passport),
      throwsA(isA<PlatformException>()),
    );
  });

  test(
    'request payload sent to native side contains wrapped requests JSON',
    () async {
      String? requestJson;
      messenger.setMockMethodCallHandler(channel, (call) async {
        requestJson =
            (call.arguments as Map<dynamic, dynamic>)['requestJson'] as String?;
        return <String, dynamic>{
          'rawCredential': base64Encode(Uint8List.fromList([9])),
        };
      });

      final impl = FlutterDigitalIdAndroid();
      await impl.getDigitalId(
        DigitalIdType.ageVerificationOnly,
        options: const DigitalIdRequestOptions(nonce: 'nonce-123'),
      );

      expect(requestJson, isNotNull);
      final decoded = jsonDecode(requestJson!) as Map<String, dynamic>;
      expect(decoded['requests'], isA<List<dynamic>>());
    },
  );
}
