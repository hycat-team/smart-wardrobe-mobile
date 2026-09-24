# Quickstart: Verify App Logo Update

**Feature**: `specs/008-app-logo-update` | **Date**: 2026-09-24

Validation guide proving the feature works end-to-end. Normative mapping: [contracts/logo-assets.md](contracts/logo-assets.md).

## Prerequisites

- Source art: `C:\FPT\Project\smart-wardrobe\logo\` (`logo-full.png`, `logo-only.png` present and readable).
- Flutter SDK (per `pubspec.yaml`: Dart `>=3.0.0 <4.0.0`), one physical Android device + one physical iOS device (per clarify Q5), Xcode with the project's signing profile.
- Baseline: install size of the pre-change release build (for the ≤ +5MB check).

## Steps

1. **Assets present**
   - `flutter pub get`
   - Confirm `assets/images/logo-full.png` exists and `pubspec.yaml` declares `assets/images/`.
   - Expected: no "Unable to load asset" errors.
2. **Static checks**
   - `flutter analyze` — Expected: no new issues in touched files.
   - Confirm old placeholder (`checkroom_rounded` header block) is gone from `login_screen.dart`.
3. **Android run** — `flutter run` / install release APK on the Android device.
   - Expected: home-screen + app-info icon shows the Closy mark on charcoal; no Flutter default icon anywhere.
4. **iOS run** — `flutter run` / install release IPA on the iOS device.
   - Expected: home-screen + settings icon shows the Closy mark; artwork crisp at full size and in Spotlight/settings small sizes.
5. **Login header** — open the app logged-out → login screen (repeat on smallest and largest supported screen sizes).
   - Expected: full `CLOSY` lockup centered, correct aspect ratio, no frame, no clipping, blends into the `#FAFAFA` background.
6. **Size + hallway check**
   - Compare install size vs. baseline — Expected: delta ≤ +5MB.
   - Show the home-screen icon to 5 people — Expected: 5/5 identify the app on first glance (SC-003).

## Fail signals (stop and fix)

- White box / invisible mark on any surface → background-variant mismatch (see contract rule 3).
- Blurry icon at any density → padding/resize error; regenerate that bucket from the 1254px source.
- Missing-asset red screen on login → `pubspec.yaml` declaration or path mismatch.
