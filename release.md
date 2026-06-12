# Release Guide for flutter_digital_id + DigitalId.Net

This document consolidates **all** release instructions for the Flutter federated plugin and its official C# companion (`DigitalId.Net`).

The two ecosystems must be released in coordination because they share identical models, test vectors, and serialization shapes for interoperability.

## 1. Pre-Release Checklist

Before any release:

- [ ] All tests pass on the Flutter side (unit tests in `flutter_digital_id_platform_interface`, example app, and especially the cross-platform `test_harness`).
- [ ] iOS simulator testing has been performed with the Wallet developer profile + sample data (see [TESTING.md](./TESTING.md)). The user must confirm a real simulator run.
- [ ] Android and Web paths exercised via the test harness.
- [ ] C# side: `dotnet test -c Release` in `DigitalId.Net` passes with 25 tests (golden model vectors + real BouncyCastle COSE roundtrips + full attack matrix: digest mismatch, missing digest entry, bad issuer sig, wrong transcript, truncated data, Apple decrypt failures). Full MSO digest validation + optional device auth + transcript binding enforced.
- [ ] The `samples/DigitalIdSample` console app builds and runs (demonstrates real verification using BouncyCastle — the crypto library you already use).
- [ ] All models have complete hand-coded `toJson`/`fromJson` + `toMap`/`fromMap` (Dart) and equivalent `ToJson`/`FromJson` + `ToMap`/`FromMap` (C#) with full parity.
- [ ] No breaking changes without a major version bump across **all** packages.
- [ ] Update cross-references (READMEs, example app pubspec if needed).
- [ ] Review and update this file + any changelogs if they exist.
- [x] Dry-run the publish commands locally where possible (and via CI `publish-dry-run` + `release-check` jobs).

## 2. Versioning Policy

- All Flutter packages are kept in lockstep: `flutter_digital_id`, `flutter_digital_id_platform_interface`, `flutter_digital_id_android`, `flutter_digital_id_darwin`, `flutter_digital_id_web`.
  - Current baseline (as of this writing): `0.1.0`.
- `DigitalId.Net` (C#) uses independent SemVer but should stay reasonably aligned for marketing/docs (e.g., 1.0.0 initial release).
- Use conventional commits or a changelog to drive version bumps.
- Patch = bug fixes / internal improvements.
- Minor = new non-breaking features (new claims, options, better error handling, new platform support).
- Major = breaking model or API changes.

**Rule:** Never publish the main `flutter_digital_id` package until the platform interface and all platform implementations with the same version are already live on pub.dev.

## 3. Releasing the Flutter / Dart Packages (Federated Plugin)

Order is **critical**. You must publish in this sequence:

### Step 1: Update versions everywhere
Bump the version in:
- `flutter_digital_id_platform_interface/pubspec.yaml`
- `flutter_digital_id_android/pubspec.yaml`
- `flutter_digital_id_darwin/pubspec.yaml`
- `flutter_digital_id_web/pubspec.yaml`
- `flutter_digital_id/pubspec.yaml`
- `flutter_digital_id/example/pubspec.yaml` (if it pins exact versions)
- Any other references (root workspace pubspec comments, READMEs, etc.)

Also update the `flutter_digital_id` dependency constraints to `^<new-version>` where appropriate.

### Step 2: Publish platform_interface first
```bash
cd flutter_digital_id_platform_interface
dart pub publish --dry-run   # review carefully
dart pub publish
```

Wait for it to appear on https://pub.dev/packages/flutter_digital_id_platform_interface.

### Step 3: Publish the platform implementation packages
```bash
cd ../flutter_digital_id_android && dart pub publish
cd ../flutter_digital_id_darwin && dart pub publish
cd ../flutter_digital_id_web && dart pub publish
```

### Step 4: Publish the main package (last)
```bash
cd ../flutter_digital_id
dart pub publish --dry-run
dart pub publish
```

### Step 5: Verify
- Check https://pub.dev/packages/flutter_digital_id
- Run the example app against the newly published versions.
- Run the `test_harness` on iOS simulator + Android emulator.

## 4. Releasing DigitalId.Net (C# / NuGet)

`DigitalId.Net` is a single focused package (no abstractions layer).

### Prerequisites
- .NET 10 SDK
- NuGet API key with push rights to the `DigitalId.Net` package ID (create on nuget.org if this is the first publish)

### Steps

1. Ensure the library builds and all tests pass in Release:
   ```bash
   cd DigitalId.Net
   dotnet clean
   dotnet build src/DigitalId.Net.csproj -c Release
   dotnet test tests/DigitalId.Net.Tests.csproj -c Release
   ```

2. Pack the release artifact:
   ```bash
   mkdir -p artifacts
   dotnet pack src/DigitalId.Net.csproj -c Release -o ./artifacts
   ```

   This produces `artifacts/DigitalId.Net.<version>.nupkg` (includes README.md, LICENSE, XML docs, and the DLL).

3. (Optional but recommended) Inspect the package:
   ```bash
   unzip -l artifacts/DigitalId.Net.*.nupkg
   unzip -p artifacts/DigitalId.Net.*.nupkg DigitalId.Net.nuspec
   ```

4. Push to NuGet:
   ```bash
   dotnet nuget push ./artifacts/DigitalId.Net.*.nupkg \
     -k <YOUR_NUGET_API_KEY> \
     -s https://api.nuget.org/v3/index.json
   ```

5. Verify on https://www.nuget.org/packages/DigitalId.Net (may take a few minutes to appear).

### Notes for DigitalId.Net
- The `.csproj` already contains full NuGet metadata (PackageId, Authors, Company, Description, Tags, License, Readme, Repository, etc.) matching ProjectFulcrum library conventions.
- `GeneratePackageOnBuild` is off by default (we control it explicitly during release).
- The package has zero external dependencies beyond the .NET 10 BCL.
- After publishing, update the version in `src/DigitalId.Net.csproj` for the next development cycle.

## 5. Git Tagging & GitHub Releases (Recommended)

After successful publishes on both sides:

```bash
git tag -a v0.1.0 -m "Release v0.1.0 - Flutter federated plugin + DigitalId.Net 1.0.0"
git push origin v0.1.0
```

Create a GitHub Release from the tag with:
- Summary of changes
- Links to pub.dev and NuGet pages
- Migration notes (if any)
- Thanks / credits

## 6. Post-Release Tasks

- [ ] Update the main README(s) with any new version-specific notes or "What's new".
- [ ] Update the example app and test harness to use the latest published versions (or `^` ranges).
- [ ] Announce (if applicable): Discord, X/Twitter, blog, internal teams.
- [ ] Monitor for issues on pub.dev, NuGet, and GitHub.
- [ ] If this was a major version, consider updating the root workspace constraints and any downstream ProjectFulcrum code that consumes either side.
- [ ] Verify that `samples/DigitalIdSample` still builds and runs cleanly (it demonstrates the recommended BouncyCastle path for real verification).
- [ ] Archive or note the exact test vectors used for this release (they live in both `flutter_digital_id_platform_interface/test/...` and `DigitalId.Net/tests/DigitalIdTestVectors.cs`).

## 7. Emergency / Rollback

- pub.dev: Once published, versions are immutable. You must publish a new higher version to "fix" issues.
- NuGet: Same rule — unlist if needed, but prefer a new patch version.
- Always test thoroughly with `--dry-run` and the cross-platform test harness before pushing.

## 8. One-Line Quick Reference

**Flutter side (in order):**
```bash
# bump versions in all 5 pubspec.yaml files + example
dart pub publish   # platform_interface → android → darwin → web → main package
```

**C# side:**
```bash
cd DigitalId.Net
dotnet test -c Release
dotnet pack -c Release -o ./artifacts
dotnet nuget push ./artifacts/DigitalId.Net.*.nupkg -k <key> -s https://api.nuget.org/v3/index.json
```

---

**This file is the single source of truth for releases.** Update it whenever the process changes (new platforms, new C# verification features, CI automation, etc.).

Last updated: 2026. Publish dry-runs (Flutter order + .NET pack) are exercised via CI and documented in the release process.