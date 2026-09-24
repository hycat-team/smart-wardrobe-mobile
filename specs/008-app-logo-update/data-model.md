# Data Model: App Logo Update

**Feature**: `specs/008-app-logo-update` | **Date**: 2026-09-24

No user data or persistence is involved. The "data" in this feature is the static asset set and its mapping to brand surfaces.

## Entities

### LogoAsset

A source image from `C:\FPT\Project\smart-wardrobe\logo` (originals stay outside the repo; resized copies are generated at implementation time).

| Field | Value / Rule |
|-------|--------------|
| `variant` | One of `full` (mark + CLOSY wordmark), `only` (mark alone), `text` (wordmark alone) |
| `sourcePath` | Absolute path of the original PNG (read-only input) |
| `dimensions` | 1254×1254px (measured) |
| `background` | Opaque white (measured A=255); never treat as transparent |
| `shippedCopy` | Resized output committed to the repo (path + max dimension per surface, see mapping) |

**Validation rules**:
- Shipped copies MUST preserve aspect ratio (no stretch/crop of the mark).
- iOS 1024 copy MUST contain no alpha channel (source already complies).
- Total added bytes across all shipped copies MUST keep the SC-004 budget (≤ +5MB install size).

### BrandSurface

A place where the logo appears.

| Field | Value / Rule |
|-------|--------------|
| `id` | `android-launcher`, `ios-app-icon`, `login-header` (closed set for this feature) |
| `shape` | Launcher: maskable square (circle/squircle applied by OS); login header: free rectangle |
| `requiredVariant` | Launchers → `only`; login header → `full` |
| `background` | Launchers → brand primary `#111111` behind the white tile; login header → app bg `#FAFAFA` (artwork white blends in) |

## Variant → Surface mapping (normative)

| Surface | Source variant | Output | Background |
|---------|---------------|--------|------------|
| Android legacy `mipmap-*/ic_launcher.png` (48/72/96/144/192) | `logo-only.png` | Downscaled white tile with safe-zone padding | White tile itself |
| Android adaptive icon (`mipmap-anydpi-v26`) | `logo-only.png` (foreground) | Foreground tile + `#111111` background color | `#111111` (`AppColors.primary`) |
| iOS `AppIcon.appiconset` (16 slots incl. 1024) | `logo-only.png` | Downscaled opaque copies with padding | White tile itself |
| Login header (`login_screen.dart`) | `logo-full.png` | Resized copy ≤512px, `assets/images/logo-full.png` | `#FAFAFA` (blends) |

## State transitions

None — assets are static. The only lifecycle is build-time: source → resized copies → bundled outputs. If a source file is missing/unreadable, generation MUST fail with the missing filename (spec Edge Cases) rather than silently keeping old art.
