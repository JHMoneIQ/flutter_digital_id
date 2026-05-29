import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_digital_id/flutter_digital_id.dart';

const statusTextKey = ValueKey('status_text');
const lastCredentialCardKey = ValueKey('last_credential_card');
const loadTestVectorButtonKey = ValueKey('load_test_vector_button');

ValueKey<String> availabilityButtonKey(DigitalIdType type) =>
    ValueKey<String>('check_${type.name}_button');

ValueKey<String> requestButtonKey(DigitalIdType type) =>
    ValueKey<String>('request_${type.name}_button');

void main() {
  runApp(const DigitalIdTestHarnessApp());
}

class DigitalIdTestHarnessApp extends StatelessWidget {
  const DigitalIdTestHarnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital ID Test Harness',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: const HarnessHomePage(),
    );
  }
}

class HarnessHomePage extends StatefulWidget {
  const HarnessHomePage({super.key});

  @override
  State<HarnessHomePage> createState() => _HarnessHomePageState();
}

class _HarnessHomePageState extends State<HarnessHomePage> {
  String _status =
      'Ready. Run on iOS simulator with the Apple mDL developer profile for real PassKit testing.';
  DigitalIdCredential? _lastCredential;
  bool _isLoading = false;

  Future<void> _checkAvailability(DigitalIdType type) async {
    setState(() {
      _isLoading = true;
      _status = 'Checking availability for ${type.name}...';
    });

    try {
      final available = await DigitalId.instance.isAvailable(type);
      setState(() {
        _status = available
            ? '${type.name} is reported as available (or cannot be silently checked on this platform).'
            : '${type.name} is not available.';
      });
    } catch (e) {
      setState(() => _status = 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _requestReal(DigitalIdType type) async {
    setState(() {
      _isLoading = true;
      _status = 'Requesting real ${type.name} from wallet...';
      _lastCredential = null;
    });

    try {
      final cred = await DigitalId.instance.getDigitalId(
        type,
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
        setState(() => _status = 'User cancelled or no credential returned.');
        return;
      }

      setState(() {
        _lastCredential = cred;
        _status =
            'SUCCESS! Received credential from native wallet.\n'
            'Format: ${cred.credentialFormat}\n'
            'Raw proof size: ${cred.rawCredential.length} bytes\n\n'
            'Structured fields available for UI pre-fill:\n'
            'Name: ${cred.fullName ?? "${cred.givenName} ${cred.familyName}"}\n'
            'DOB: ${cred.dateOfBirth}\n'
            'Nationality: ${cred.nationality}';
      });
    } catch (e) {
      setState(
        () => _status =
            'Error during real request: $e\n\n'
            'On iOS simulator: Make sure you have installed the Apple "Wallet and Apple mDL Developer Integrator profile" and are using a supported simulator.',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _loadTestVector() {
    final vector = DigitalIdCredential(
      givenName: 'Jane',
      familyName: 'Doe',
      fullName: 'Jane Doe',
      dateOfBirth: DateTime(1990, 5, 15),
      ageOver18: true,
      ageOver21: true,
      nationality: 'US',
      documentNumber: 'A12345678',
      rawCredential: base64Decode('dGVzdC1wcm9vZi1ieXRlcy1mb3ItYmFja2VuZA=='),
      credentialFormat: 'test-vector',
      metadata: {'source': 'harness_test_vector'},
    );

    setState(() {
      _lastCredential = vector;
      _status =
          'Loaded test vector (no native call).\n'
          'This demonstrates the exact shape your frontend and backend will receive.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Digital ID Test Harness')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _status,
                key: statusTextKey,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              const Text('1. Check Availability (no prompt)'),
              Wrap(
                spacing: 8,
                children: DigitalIdType.values
                    .map(
                      (t) => ElevatedButton(
                        key: availabilityButtonKey(t),
                        onPressed: _isLoading
                            ? null
                            : () => _checkAvailability(t),
                        child: Text('Check ${t.name}'),
                      ),
                    )
                    .toList(),
              ),

              const SizedBox(height: 24),
              const Text(
                '2. Real Native Request (shows wallet UI on supported devices)',
              ),
              Wrap(
                spacing: 8,
                children: DigitalIdType.values
                    .map(
                      (t) => FilledButton(
                        key: requestButtonKey(t),
                        onPressed: _isLoading ? null : () => _requestReal(t),
                        child: Text('Request ${t.name} (Real)'),
                      ),
                    )
                    .toList(),
              ),

              const SizedBox(height: 24),
              OutlinedButton(
                key: loadTestVectorButtonKey,
                onPressed: _isLoading ? null : _loadTestVector,
                child: const Text('Load Test Vector (no native call)'),
              ),

              const SizedBox(height: 32),
              if (_lastCredential != null) ...[
                const Text('Last Credential Received:'),
                Card(
                  key: lastCredentialCardKey,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Name: ${_lastCredential!.fullName ?? "${_lastCredential!.givenName} ${_lastCredential!.familyName}"}',
                        ),
                        if (_lastCredential!.dateOfBirth != null)
                          Text('DOB: ${_lastCredential!.dateOfBirth}'),
                        if (_lastCredential!.nationality != null)
                          Text('Nationality: ${_lastCredential!.nationality}'),
                        Text(
                          'Raw proof length: ${_lastCredential!.rawCredential.length} bytes',
                        ),
                        Text('Format: ${_lastCredential!.credentialFormat}'),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),
              const Text(
                'Platform Testing Notes:\n'
                '• iOS Simulator: Needs Apple mDL developer profile + sample data (see TESTING.md)\n'
                '• Android: Use emulator + test wallet (CMWallet or Google sandbox)\n'
                '• Web: Run with `flutter run -d chrome` (secure context required)\n'
                '• Test vectors always available as fallback.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
