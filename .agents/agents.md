# AI guide for `flutter_digital_id`

This file is for AI coding agents working in this repository.

## Mission

Maintain and improve a federated Flutter digital identity plugin workspace plus its companion .NET verification library without overstating platform completeness.

The repository is promising and substantially implemented, but some platform paths are still experimental.

## Ground truth you must preserve

### Platform status

- **Android:** real implementation exists in `flutter_digital_id_android` using Android Credential Manager.
- **iOS:** Darwin layer uses documented PassKit identity-presentment APIs and compiles, but production readiness is not proven until validated in a real entitled Apple app.
- **Web:** implementation exists in `flutter_digital_id_web`, but it remains experimental and needs broader interoperability validation.
- **Desktop:** graceful degradation only.

Do **not** describe iOS or Web as fully production-ready unless new evidence in this repo proves it.

### Strong parts of the codebase

- Shared models and serialization in `flutter_digital_id_platform_interface`
- Flutter API surface in `flutter_digital_id`
- Android native bridge and Dart mapping
- Test harness for manual/demo/integration flows
- `DigitalId.Net` verification library and tests

### Weak / incomplete areas

- Real Apple entitlement-backed validation
- Web wallet/browser interoperability hardening
- Release automation and publishing polish
- Some repo-level documentation/changelog/license packaging polish

## Repository map

```text
README.md                                root repo overview
TESTING.md                               practical testing guidance
release.md                               release checklist + publish order

flutter_digital_id/                      public Flutter package
flutter_digital_id_platform_interface/   shared models, request options, tests
flutter_digital_id_android/              Android implementation
flutter_digital_id_darwin/               iOS/macOS implementation
flutter_digital_id_web/                  Web implementation
test_harness/                            manual + automated harness app
DigitalId.Net/                           .NET verification library
.agents/skills/                          local reusable skills
```

## High-value commands

### Flutter tests

```bash
cd flutter_digital_id && flutter test
cd flutter_digital_id_platform_interface && flutter test
cd flutter_digital_id_android && flutter test
cd test_harness && flutter test test/widget_test.dart
```

### Harness integration test

Requires a supported device target, typically an iOS simulator:

```bash
cd test_harness
flutter test integration_test/harness_flow_test.dart -d <simulator-id>
```

### Static analysis

```bash
cd flutter_digital_id_android && flutter analyze
cd test_harness && flutter analyze
```

### Native build smoke tests

```bash
cd test_harness
flutter build apk --debug
flutter build ios --simulator --no-codesign
```

### .NET verification library

```bash
cd DigitalId.Net
dotnet build src/DigitalId.Net.csproj -c Release
dotnet test tests/DigitalId.Net.Tests.csproj -c Release
```

## Editing guidance

### When touching docs

- Keep README claims conservative and evidence-based.
- Distinguish between:
  - implemented,
  - experimentally validated,
  - production-proven.
- Point users to `TESTING.md` and `release.md` instead of duplicating too much detail.

### When touching Android

- Preserve the Credential Manager-based architecture.
- Be careful with Kotlin / AGP / Gradle compatibility.
- The repo has already been migrated toward Flutter’s built-in Kotlin future-compatibility path.
- Prefer validating with `flutter test`, `flutter analyze`, and a harness APK build.

### When touching iOS / Darwin

- Use only documented PassKit identity APIs.
- Do not reintroduce speculative selector-based or guessed APIs.
- Remember that simulator/mock testing is possible, but entitlement-backed validation is still the real readiness bar.

### When touching Web

- Treat current code as experimental.
- Be cautious about response parsing assumptions.
- Prefer adding interoperability tests before making stronger support claims.

### When touching shared models/API

- Maintain parity across:
  - Flutter public API
  - platform interface models
  - native metadata mapping
  - `DigitalId.Net` model expectations where applicable
- Avoid breaking serialization shapes casually.

## Known recent work

Recent repository improvements already completed include:

- `verifyAge(minimumAge)` honoring the requested threshold
- `ClaimPath` equality regression fix
- iOS Darwin rewrite to a typed PassKit scaffold
- Android dependency/tooling fixes for Credential Manager support
- harness widget keys and integration-style test coverage
- Android channel mapping tests
- Gradle/AGP updates in `test_harness`

Avoid undoing these unless you have a compelling reason.

## What “ready to roll” still means here

If asked what remains before the repo is completely ready, the honest answer is usually:

1. **Apple production validation** (human / legal process — cannot be done in code)
   - entitlement approval from Apple
   - merchant identity + cert setup
   - real end-to-end validation in an entitled app against genuine responses (not just simulator mocks)
   - backend decryption/verification exercised against real Apple responses

2. **Web hardening** (partially addressed; still needs real-world confirmation)
   - validate against actual shipping browsers + wallets
   - confirm / evolve supported request/response shapes
   - (done) stronger automated tests for the pure request builder + response extraction logic now exist and run under `flutter test`

3. **Release/publish polish** (largely completed in this pass)
   - (done) top-level LICENSE + per-package LICENSE files
   - (done) CHANGELOG.md for every publishable package (Flutter + DigitalId.Net)
   - (done) pubspec metadata (repository, issue_tracker, license, improved descriptions)
   - (done) publish dry-runs now pass the hard requirements (README + LICENSE present); full sequence exercised
   - (done) CI automation: `.github/workflows/ci.yml` + `release-check.yml` covering Flutter analyze/test/build smoke, .NET build+test+pack, and the full Flutter publish dry-run order

4. **Consumer proof** (improved)
   - (done) per-package READMEs explaining role + caveats
   - (done) improved example README
   - (done) all unit tests + harness widget tests + .NET 25-test suite passing
   - still valuable: run realistic sample/integration paths on real devices/browsers with backend verification of the raw proofs

**Note:** The code changes in this session directly addressed every item on the review list that can be completed inside the repository (CI, licensing, changelogs, metadata, dry-runs, web test coverage + hardening of the pure logic, docs). The two items that fundamentally require external approval or real hardware/wallet testing (Apple entitlement + production iOS validation, and broad browser/wallet interop) are now clearly documented as such.

## Preferred response style

When summarizing the repo:

- be precise;
- be candid about experimental areas;
- emphasize that backend verification is mandatory;
- do not equate “builds successfully” with “production ready”.

That distinction matters a lot in this repo.
