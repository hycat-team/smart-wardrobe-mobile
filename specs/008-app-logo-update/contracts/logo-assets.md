# Asset Contract: Logo Variant → Surface

**Feature**: `specs/008-app-logo-update` | **Date**: 2026-09-24

This contract is the normative mapping any implementation and review must satisfy. Details and rationale live in [research.md](../research.md) and [data-model.md](../data-model.md).

## Contract

1. **Launcher icons (Android + iOS) MUST use the `only` variant** (`logo-only.png`). The full lockup MUST NOT appear on launcher icons (wordmark illegible at icon sizes).
2. **Login brand header MUST use the `full` variant** (`logo-full.png`), rendered directly with aspect-preserving fit and NO surrounding frame, container, or generic icon. The old 68×68 rounded `Container` + `checkroom` icon MUST be removed.
3. **Artwork background is opaque white** — implementations MUST NOT assume transparency. The black mark MUST never sit directly on the charcoal primary (`#111111`); launchers keep the white tile, optionally on the `#111111` adaptive-icon background.
4. **Android**: legacy `mipmap-*` PNGs (48/72/96/144/192) replaced + `mipmap-anydpi-v26` adaptive icon (`#111111` background) added. Manifest `android:icon` reference unchanged.
5. **iOS**: every image slot in `AppIcon.appiconset/Contents.json` replaced 1:1; no alpha in the 1024 image; `Contents.json` unchanged.
6. **In-app asset**: exactly one shipped copy, `assets/images/logo-full.png` (≤512px longest edge), declared in `pubspec.yaml` under `flutter.assets`. No network loading for brand art.
7. **Out of scope**: register, onboarding, splash, and all other screens keep current appearance.

## Verification hooks (for quickstart)

- `V1`: Package listing contains no `ic_launcher.png` identical to the old Flutter default (compare hashes before/after).
- `V2`: `flutter analyze` passes on touched Dart files; `pubspec.yaml` parses and includes the new asset path.
- `V3`: Installed APK/IPA size delta vs. baseline build ≤ +5MB.
