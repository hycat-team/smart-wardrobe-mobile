# Implementation Plan: Home Stats Infinite Scroll

**Branch**: `006-home-stats-infinite-scroll` | **Date**: 2026-09-14 | **Spec**: specs/006-home-stats-infinite-scroll/spec.md

**Input**: Feature specification from `/specs/006-home-stats-infinite-scroll/spec.md`

## Summary

Two UI/UX fixes, mobile-only: (1) Home reads overview numbers from the same stats sources as the Insights page (`wardrobeInsightsProvider` + new `wardrobeStatsProvider` on existing `GET /me/wardrobe-items/stats` + existing distribution provider) with per-section loading/error states; (2) infinite scroll on Wardrobe (extend notifier with real paging, repo already supports it) and Outfit list (repo parses pagination metadata + notifier paging), both with dedupe, single-flight guard, filter-reset and selection preservation. See `research.md`, `data-model.md`, `contracts/pagination.md`, `quickstart.md`.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x

**Primary Dependencies**: flutter_riverpod 2.5 (`StateNotifierProvider`, `FutureProvider`), go_router (untouched)

**Storage**: N/A (server paging; no cache layer added)

**Testing**: flutter_test (existing suite must stay at baseline) + manual QS-001→004; `flutter analyze` clean

**Target Platform**: Android emulator first + iOS device for scroll-physics regression

**Project Type**: mobile-app (single Flutter project)

**Performance Goals**: load-more append without list jump (keep scroll offset); no duplicate requests on fast flings; first page paint time unchanged

**Constraints**: Page sizes frozen (wardrobe 20, outfits 50); existing `WardrobePaginationResult` parsing untouched; Quiet Luxury tokens for new spinners/error rows; selection-mode (004) and catalog (004) flows untouched; one additive repo method only, no BE change

**Scale/Scope**: 5 files touched + 2 small additions (stats model+provider wiring, outfit pagination result); 3 user stories; mobile-only

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` is an unfilled placeholder → no enforceable gates. Project governance (closy skill + gotchas):

- [x] No new dependencies; single additive GET (existing Dio stack + `Accept-Encoding: identity` untouched).
- [x] No nav/route changes; no auth/storage changes.
- [x] No breaking change to existing provider APIs consumed by other screens (bulk-delete, catalog, detail all keep working: refresh semantics preserved).
- [x] Home is teammate's uncommitted file — attach stats with minimal edits, coordinate on merge.

Post-design re-check: Phase 1 adds state fields only (no shared-state merge, quota/selection flows intact) → passes. No Complexity Tracking needed.

## Project Structure

### Documentation (this feature)

```text
specs/006-home-stats-infinite-scroll/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
│   └── pagination.md
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
lib/
├── features/wardrobe/
│   ├── models/wardrobe_models.dart                  # + WardrobeStats model (parse stats endpoint)
│   ├── data/wardrobe_repository.dart                # + getWardrobeStats()
│   ├── providers/wardrobe_provider.dart             # + isLoadingMore/hasMore/loadMore(); refresh resets page; stale-guard
│   └── presentation/wardrobe_screen.dart            # + scroll threshold trigger + footer sliver (spinner/done)
├── features/outfit_studio/
│   ├── data/outfit_repository.dart                  # + getMyOutfitsPaginated() (keep old method if still used)
│   ├── providers/outfits_list_provider.dart         # + page/total/isLoadingMore/hasMore/loadMore()
│   └── presentation/outfits_list_screen.dart        # + scroll threshold + trailing loader
├── features/home/presentation/home_screen.dart      # + insights + stats providers in quick-stats (minimal edits)
└── (provider wiring for wardrobeStatsProvider lives with wardrobe providers)

test/
├── *_test.dart                                      # existing suite at baseline
```

**Structure Decision**: Follow existing feature slices; no new top-level dirs. Stats provider colocated with wardrobe providers (same file or adjacent, matching `wardrobeInsightsProvider` pattern).

## Phases (for /speckit-tasks)

- **Phase A (P1)**: US1 — stats model + repo + provider + Home wiring (QS-001).
- **Phase B (P1)**: US2 — Wardrobe notifier paging + screen trigger/footer (QS-002).
- **Phase C (P2)**: US3 — Outfit repo pagination + notifier + screen (QS-003).
- **Phase D**: QS-004 regression (analyze + tests + old flows).

## Complexity Tracking

> No constitution violations — nothing to justify.
