import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_digital_id/flutter_digital_id.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DigitalIdExampleApp());
}

class DigitalIdExampleApp extends StatelessWidget {
  const DigitalIdExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutter_digital_id Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _status = 'Ready';
  DigitalIdCredential? _lastCredential;

  Future<void> _checkAvailability(DigitalIdType type) async {
    setState(() => _status = 'Checking availability for $type...');
    try {
      final available = await DigitalId.instance.isAvailable(type);
      setState(() {
        _status = available
            ? '$type appears to be available (or platform cannot silently check).'
            : '$type is not available on this device/platform.';
      });
    } catch (e) {
      setState(() => _status = 'Error checking availability: $e');
    }
  }

  Future<void> _requestDigitalId(DigitalIdType type) async {
    setState(() => _status = 'Requesting $type...');

    try {
      final cred = await DigitalId.instance.getDigitalId(
        type,
        options: DigitalIdRequestOptions(
          requiredClaims: [
            ClaimPath.familyName(),
            ClaimPath.givenName(),
            ClaimPath.birthDate(),
          ],
          optionalClaims: [
            ClaimPath.portrait(),
          ],
        ),
      );

      if (cred == null) {
        setState(() => _status = 'User cancelled or no credential returned.');
        return;
      }

      setState(() {
        _lastCredential = cred;
        _status = 'Credential received! Structured fields populated: '
            '${cred.givenName != null || cred.familyName != null ? "name " : ""}'
            '${cred.dateOfBirth != null ? "DOB " : ""}'
            'Raw proof: ${cred.rawCredential.length} bytes (${cred.credentialFormat})';
      });
    } catch (e) {
      setState(() => _status = 'Error during request: $e');
    }
  }

  void _useTestVector() {
    // This demonstrates the exact data shape the library will deliver:
    // rich structured fields for the frontend to immediately pre-fill forms,
    // plus the raw cryptographic proof that must be sent to the backend.
    final testCredential = DigitalIdCredential(
      givenName: 'Jane',
      familyName: 'Doe',
      fullName: 'Jane Doe',
      dateOfBirth: DateTime(1990, 5, 15),
      ageOver18: true,
      ageOver21: true,
      nationality: 'US',
      documentNumber: 'A12345678',
      documentType: 'passport',
      issuingCountry: 'US',
      expirationDate: DateTime(2035, 5, 15),
      addressLine1: '123 Main St',
      city: 'Anytown',
      state: 'CA',
      postalCode: '90210',
      country: 'US',
      rawCredential: Uint8List.fromList([0xDE, 0xAD, 0xBE, 0xEF, 0x01, 0x02, 0x03]), // fake proof bytes
      credentialFormat: 'test-vector',
      metadata: {'source': 'local_test_vector'},
    );

    setState(() {
      _lastCredential = testCredential;
      _status = 'Test vector loaded. In a real flow this would come from the wallet '
          'with a valid cryptographic proof that your backend must validate.';
    });
  }

  Future<void> _tryRealNativeFlow() async {
    setState(() => _status = 'Attempting real native flow...');

    try {
      // This will use the real implementation on iOS/Android if available,
      // or the current stub on other platforms.
      final cred = await DigitalId.instance.getDigitalId(
        DigitalIdType.passport,
        options: DigitalIdRequestOptions(
          requiredClaims: [
            ClaimPath.familyName(),
            ClaimPath.givenName(),
            ClaimPath.birthDate(),
          ],
          optionalClaims: [ClaimPath.portrait()],
        ),
      );

      if (cred == null) {
        setState(() => _status = 'Native flow returned null (user cancelled or not available).');
        return;
      }

      setState(() {
        _lastCredential = cred;
        _status = 'Real native credential received!\n'
            'Format: ${cred.credentialFormat}\n'
            'Proof size: ${cred.rawCredential.length} bytes\n'
            'Note: On iOS, rich structured fields usually come from your backend after decrypting the raw proof.';
      });
    } catch (e) {
      setState(() => _status = 'Real native flow error: $e\n\n'
          'Common on iOS simulator without proper entitlements or developer profile.\n'
          'See README for setup instructions.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('flutter_digital_id Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_status, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Availability checks (no prompt):'),
                    Wrap(
                      spacing: 8,
                      children: DigitalIdType.values.map((t) {
                        return ElevatedButton(
                          onPressed: () => _checkAvailability(t),
                          child: Text('Check ${t.name}'),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text('Request credential (consent shown where native supported):'),
                    Wrap(
                      spacing: 8,
                      children: DigitalIdType.values.map((t) {
                        return FilledButton(
                          onPressed: () => _requestDigitalId(t),
                          child: Text('Request ${t.name}'),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _useTestVector,
                      child: const Text('Use test vector (no native call)'),
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: _tryRealNativeFlow,
                      child: const Text('Try real native flow on this device (iOS simulator / Android)'),
                    ),
                    const SizedBox(height: 24),
                    if (_lastCredential != null) ...[
                      const Text('Last credential (structured fields):'),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Name: ${_lastCredential!.fullName ?? "${_lastCredential!.givenName} ${_lastCredential!.familyName}"}'),
                              if (_lastCredential!.dateOfBirth != null)
                                Text('DOB: ${_lastCredential!.dateOfBirth}'),
                              if (_lastCredential!.nationality != null)
                                Text('Nationality: ${_lastCredential!.nationality}'),
                              Text('Raw proof length: ${_lastCredential!.rawCredential.length} bytes'),
                              Text('Format: ${_lastCredential!.credentialFormat}'),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    const Text(
                      'Note: Real functionality requires entitlements (Apple) / RP registration (Google) '
                      'and a device with test or real digital IDs. Native layers are currently stubs — see README.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
