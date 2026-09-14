# Implementation Plan: Loadmore Chip Contrast

**Branch**: `007-loadmore-chip-contrast` | **Date**: 2026-09-14 | **Spec**: specs/007-loadmore-chip-contrast/spec.md

**Input**: Feature specification from `/specs/007-loadmore-chip-contrast/spec.md`

## Summary

Re-fix of 006 load-more (structure verified correct; failure is runtime/data-side): harden `hasMore` into a 3-flag state machine (`lastPageWasFull`/`emptyStreak`/`loadMoreExhausted`) covering BE-ignores-page, short-total and duplicate-page cases with at most 2 wasted probes and no infinite spinner; ignore horizontal scroll notifications; white checkmark on selected filter chips (Wardrobe + catalog). No API change. See `research.md`, `data-model.md`, `contracts/loadmore-hardening.md`, `quickstart.md`.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x

**Primary Dependencies**: flutter_riverpod 2.5 (StateNotifier), material ChoiceChip

**Storage**: N/A

**Testing**: flutter_test (baseline) + manual QS-001→004 with network-log cross-check; `flutter analyze` clean

**Target Platform**: Android emulator first

**Project Type**: mobile-app (single Flutter project)

**Performance Goals**: ≤ 2 wasted probe requests in degenerate BE cases; zero duplicate in-flight loadMores; first-page paint unchanged

**Constraints**: Page sizes frozen (20/50); 006 guards (single-flight, dedupe, reset, selection) preserved; Quiet Luxury chip look preserved except checkmark color; no BE change

**Scale/Scope**: 5 files touched, 0 new files; 2 stories; mobile-only

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Placeholder constitution → no gates. Gotcha compliance: no new deps, no nav/auth/storage/network changes, provider API extensions are additive (existing callers: bulk-delete, catalog, detail, home all refresh from page 1 — semantics preserved).

Post-design re-check: state additions only → passes. No Complexity Tracking needed.

## Project Structure

### Documentation (this feature)

```text
specs/007-loadmore-chip-contrast/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── loadmore-hardening.md
└── tasks.md             # Phase 2 output (NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
lib/
├── features/wardrobe/
│   ├── providers/wardrobe_provider.dart      # hasMore v2 + flags + loadMore/loadItems updates
│   └── presentation/wardrobe_screen.dart     # vertical-axis filter + checkmarkColor ×2 chips
├── features/outfit_studio/
│   ├── providers/outfits_list_provider.dart  # same state machine (limit 50)
│   └── presentation/outfits_list_screen.dart # vertical-axis filter
└── features/wardrobe/presentation/system_catalog_screen.dart  # checkmarkColor (consistency)
```

**Structure Decision**: Existing slices only; no new files.

## Phases (for /speckit-tasks)

- **Phase A (P1)**: US1 — notifier state machines + axis filters (QS-001/002).
- **Phase B (P2)**: US2 — chip checkmark colors (QS-003).
- **Phase C**: QS-004 regression.

## Complexity Tracking

> No constitution violations — nothing to justify.
