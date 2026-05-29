//
// Generated file. Do not edit.
// This file is generated from template in file `flutter_tools/lib/src/flutter_plugins.dart`.
//

// @dart = 3.10

import 'dart:io'; // flutter_ignore: dart_io_import.
import 'package:flutter_digital_id_android/flutter_digital_id_android.dart' as flutter_digital_id_android;

@pragma('vm:entry-point')
class _PluginRegistrant {

  @pragma('vm:entry-point')
  static void register() {
    if (Platform.isAndroid) {
      try {
        flutter_digital_id_android.FlutterDigitalIdAndroid.registerWith();
      } catch (err) {
        print(
          '`flutter_digital_id_android` threw an error: $err. '
          'The app may not function as expected until you remove this plugin from pubspec.yaml'
        );
      }

    } else if (Platform.isIOS) {
    } else if (Platform.isLinux) {
    } else if (Platform.isMacOS) {
    } else if (Platform.isWindows) {
    }
  }
}
