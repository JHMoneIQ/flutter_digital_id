import 'package:flutter/services.dart';
import 'package:flutter_digital_id_darwin/flutter_digital_id_darwin.dart';
import 'package:flutter_digital_id_platform_interface/flutter_digital_id_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FlutterDigitalIdDarwin channel contract + mapping', () {
    const channel = MethodChannel('flutter_digital_id/darwin');
    final responses = <String, dynamic>{};

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (responses.containsKey(call.method)) {
          return responses[call.method];
        }
        if (call.method == 'isDigitalIdAvailable') {
          return true;
        }
        if (call.method == 'getDigitalId') {
          return {
            'credentialFormat': 'apple-encrypted',
            'rawCredential': 'aGVsbG8td29ybGQ=', // base64 "hello-world"
            'disclosedClaimPaths': <String>[],
          };
        }
        return null;
      });

      FlutterDigitalIdDarwin.registerWith();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('isDigitalIdAvailable forwards to channel and returns mapped value', () async {
      final impl = FlutterDigitalIdDarwin();
      final available = await impl.isDigitalIdAvailable(DigitalIdType.passport);
      expect(available, isTrue);
    });

    test('getDigitalId maps native response to DigitalIdCredential', () async {
      final impl = FlutterDigitalIdDarwin();
      final cred = await impl.getDigitalId(
        DigitalIdType.driversLicense,
        options: DigitalIdRequestOptions(requiredClaims: [ClaimPath.givenName()]),
      );

      expect(cred, isNotNull);
      expect(cred!.credentialFormat, 'apple-encrypted');
      expect(cred.rawCredential, isNotEmpty);
      expect(cred.metadata['source'], 'ios-passkit');
    });

    test('getDigitalId returns null on native null (user cancel simulation)', () async {
      responses['getDigitalId'] = null;

      final impl = FlutterDigitalIdDarwin();
      final cred = await impl.getDigitalId(DigitalIdType.passport);
      expect(cred, isNull);
    });

    test('getDigitalId throws DigitalIdException on NOT_ENTITLED', () async {
      responses['getDigitalId'] = null; // reset
      // Simulate the PlatformException the Swift side can throw
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'getDigitalId') {
          throw PlatformException(code: 'NOT_ENTITLED', message: 'Missing entitlement');
        }
        return true;
      });

      final impl = FlutterDigitalIdDarwin();
      expect(
        () => impl.getDigitalId(DigitalIdType.passport),
        throwsA(isA<DigitalIdException>().having((e) => e.code, 'code', DigitalIdErrorCode.notEntitled)),
      );
    });
  });

  group('FlutterDigitalIdDarwin registration', () {
    test('registerWith installs the darwin implementation', () {
      DigitalIdPlatform.instance = _Stub();
      FlutterDigitalIdDarwin.registerWith();
      expect(DigitalIdPlatform.instance, isA<FlutterDigitalIdDarwin>());
    });
  });
}

class _Stub extends DigitalIdPlatform {
  @override
  Future<bool> isDigitalIdAvailable(DigitalIdType type, {DigitalIdRequestOptions? options}) async => false;
  @override
  Future<bool> requestPermission(DigitalIdType type, {DigitalIdRequestOptions? options}) async => false;
  @override
  Future<DigitalIdCredential?> getDigitalId(DigitalIdType type, {DigitalIdRequestOptions? options}) async => null;
}
