# Digital ID Test Harness

This is a full cross-platform Flutter application for testing `flutter_digital_id`.

## Purpose

- Exercise the real native implementations on iOS and Android.
- Provide a clean UI to test availability checks and real document requests.
- Include test vector fallback for development without hardware/wallets.
- Serve as the primary way to validate the plugin on simulators and physical devices.

## Running on iOS Simulator (Recommended for iOS testing)

1. Make sure you have the Apple "Wallet and Apple mDL Developer Integrator profile" installed (see main TESTING.md).
2. Boot a simulator or use an already running one.
3. From the repo root:

```bash
cd test_harness
flutter run -d <simulator-udid>
```

Example (using the currently booted iPhone 16):

```bash
flutter run -d B56FBBFB-21B4-4BFA-95CD-C219566D4B9D
```

The app will let you:
- Check availability (calls the real `isDigitalIdAvailable`).
- Trigger real PassKit flows (will show the system consent sheet on supported simulators).
- Load test vectors as a fallback.

## Running on Android Emulator

```bash
flutter run -d <emulator-id>
```

## Notes

- This harness lives outside the main `flutter_digital_id` package so it can have its own full platform folders and be used for realistic integration testing.
- It is included in the workspace for easy `dart pub get` from the root.
- For the most realistic iOS testing, use a simulator that supports the digital ID features (iOS 17+ / 26.x recommended) + Apple's developer profile.

See the main project `TESTING.md` for full setup instructions (especially the Apple profile and sample data).
