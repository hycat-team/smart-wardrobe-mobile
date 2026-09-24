# Implementation Plan: App Logo Update

**Branch**: `008-app-logo-update` | **Date**: 2026-09-24 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/008-app-logo-update/spec.md`

## Summary

Replace the default Flutter launcher icons (Android + iOS) and the login-screen placeholder branding with the new Closy logo set from `C:\FPT\Project\smart-wardrobe\logo`. Launcher icons use the icon-only mark (white tile, charcoal `#111111` adaptive background on Android); the login header renders the full `CLOSY` lockup directly with no frame. Measured artwork is 1254×1254 opaque-white, so no transparency handling is needed and the app (light-only UI, bg `#FAFAFA`) requires no dark-mode rework — see [research.md](research.md) for all measured decisions.

## Technical Context

**Language/Version**: Dart (SDK `>=3.0.0 <4.0.0`) / Flutter stable

**Primary Dependencies**: None new — `flutter_riverpod`, `go_router` untouched; icon replacement is manual (no `flutter_launcher_icons` dependency, per R-02)

**Storage**: N/A (static bundled assets only)

**Testing**: `flutter analyze` + `flutter_test` (existing suite) + physical-device verification per [quickstart.md](quickstart.md) + 5-person hallway check (SC-003)

**Target Platform**: Android (`minSdk = flutter.minSdkVersion`, legacy mipmaps + `anydpi-v26` adaptive icon) and iOS (`AppIcon.appiconset`, Xcode build)

**Project Type**: mobile-app (Flutter)

**Performance Goals**: Install-size delta ≤ +5MB (SC-004); ship resized copies only (expected total addition < 1MB)

**Constraints**: Artwork is opaque white — black mark must never sit directly on charcoal; iOS 1024 image must contain no alpha (source complies); originals in `C:\FPT\Project\smart-wardrobe\logo` stay read-only

**Scale/Scope**: 3 source files → 3 surfaces (`android-launcher`, `ios-app-icon`, `login-header`); 1 Dart file touched (`login_screen.dart`) + `pubspec.yaml`

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` is an unfilled template (no principles, constraints, or governance rules defined) — there are no gates to evaluate. Post-design re-check (2026-09-24): design adds no new dependencies, no data handling, no API changes; nothing to justify. **PASS** (vacuous).

## Project Structure

### Documentation (this feature)

```text
specs/008-app-logo-update/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
│   └── logo-assets.md   # Variant → surface contract + verification hooks
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
assets/
└── images/
    └── logo-full.png        # NEW resized copy (≤512px) for login header

lib/
└── features/auth/presentation/
    └── login_screen.dart    # EDIT: remove placeholder Container+Icon, add Image.asset

android/app/src/main/res/
├── mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher.png  # REPLACE (48/72/96/144/192)
├── mipmap-anydpi-v26/                                      # NEW adaptive icon XMLs
│   ├── ic_launcher.xml
│   └── ic_launcher_round.xml
└── values/colors.xml / ic_launcher_background  # NEW/EDIT: #111111 background

ios/Runner/Assets.xcassets/AppIcon.appiconset/
└── Icon-App-*.png (16 files)  # REPLACE 1:1 per Contents.json (unchanged)

pubspec.yaml  # EDIT: declare assets/images/
```

**Structure Decision**: Single Flutter project; changes are additive asset replacement plus one widget edit. No new packages, screens, or routes.

## Complexity Tracking

No constitution violations — table not applicable.
