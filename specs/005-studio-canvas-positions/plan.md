# Implementation Plan: Studio Canvas Positions

**Branch**: `005-studio-canvas-positions` | **Date**: 2026-09-14 | **Spec**: specs/005-studio-canvas-positions/spec.md

**Input**: Feature specification from `/specs/005-studio-canvas-positions/spec.md`

## Summary

Fix scattered/overlapping/off-canvas items when loading AI suggestions or saved outfits onto the manual Studio canvas. Pure client-side layout fix: (1) canonical role normalization covering all 7 BE roles + raw VI slugs; (2) shared slot table extending the 5 known-good positions with outerwear/headwear/unknown slots + duplicate-role cascade; (3) pure `layoutCanvasItems` post-pass (clamp into canvas, all-(0,0) legacy detection, 80px de-overlap, single-item centering); (4) honor stored coordinates on saved-outfit open; (5) overwrite-confirm dialog when canvas is busy. No BE change — see `research.md`, `data-model.md`, `contracts/canvas-positions.md`, `quickstart.md`.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x

**Primary Dependencies**: flutter_riverpod 2.5 (`StateNotifierProvider`), google_fonts (existing)

**Storage**: N/A (positions already persisted via existing save/outfit endpoints)

**Testing**: flutter_test (existing suite) + pure-function unit checks for the layout helper + manual QS-001→006 in `quickstart.md`; `flutter analyze` clean

**Target Platform**: Android emulator first + iOS real device for gesture/drag regression

**Project Type**: mobile-app (single Flutter project)

**Performance Goals**: layout post-pass < 16ms for ≤ 10 items (pure math, no I/O); canvas first paint after load unchanged

**Constraints**: Existing 5 role slots (top/bottom/fullbody/footwear/accessory offsets) MUST NOT change values (users recognize them); base item size 200px and `center + offset` render math untouched; manual drag/scale/layer/save flows untouched; Quiet Luxury tokens for any new dialog; `Accept-Encoding: identity` Dio rule unaffected (no network change)

**Scale/Scope**: 3 files touched (`outfit_models.dart` or new layout helper, `outfit_studio_provider.dart`, `outfits_list_provider.dart` + `outfit_studio_screen.dart` dialog) + 1 new pure helper file; 2 user stories, mobile-only, zero BE work

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` is an unfilled placeholder → no enforceable gates. Project governance (closy skill + PROJECT_AGENT_GUIDE gotchas):

- [x] No new dependencies; no auth/token/storage/network changes.
- [x] No route/nav changes; one dialog added following existing confirm patterns.
- [x] Existing role offsets frozen; render math untouched.
- [x] Layout helper is pure (no context, no I/O) → trivially testable.

Post-design re-check: Phase 1 keeps provider responsibilities (providers call helper; screen owns dialog) → passes. No Complexity Tracking needed.

## Project Structure

### Documentation (this feature)

```text
specs/005-studio-canvas-positions/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
│   └── canvas-positions.md
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
lib/
├── features/outfit_studio/
│   ├── models/outfit_models.dart                 # + normalizeRole() (+ optional position fields on RecommendedItemRes for forward-compat, ignored if absent)
│   ├── layout/canvas_layout.dart                 # NEW — pure: slot table + layoutCanvasItems(items, w, h)
│   ├── providers/outfit_studio_provider.dart     # loadFromAIRecommendation uses normalizeRole + slots + layout pass
│   ├── providers/outfits_list_provider.dart      # loadIntoStudio honors stored pos + layout pass (clamp/de-overlap/legacy)
│   └── presentation/outfit_studio_screen.dart    # overwrite-confirm dialog when canvas non-empty
test/
├── *_test.dart                                   # existing suite must stay green
```

**Structure Decision**: Single-project Flutter slices; new pure helper under `lib/features/outfit_studio/layout/` (no new top-level dirs). No test-file mandate (spec didn't request TDD), but helper's purity allows quick asserts during implementation.

## Phases (for /speckit-tasks)

- **Phase A (P1)**: US1 — normalizeRole + slot table + AI load path + de-overlap (QS-001/002).
- **Phase B (P1)**: US2 — saved-outfit load path (honor stored + clamp + legacy + single-center) + overwrite dialog (QS-003/004/005).
- **Phase C**: QS-006 cross-size + full analyze/test regression.

## Complexity Tracking

> No constitution violations — nothing to justify.
