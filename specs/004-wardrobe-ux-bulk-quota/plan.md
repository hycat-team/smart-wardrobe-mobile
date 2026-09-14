# Implementation Plan: Wardrobe UX Bulk Quota Fixes

**Branch**: `004-wardrobe-ux-bulk-quota` | **Date**: 2026-09-14 | **Spec**: specs/004-wardrobe-ux-bulk-quota/spec.md

**Input**: Feature specification from `/specs/004-wardrobe-ux-bulk-quota/spec.md`

## Summary

Fix 4 manual-testing issues in one mobile-only iteration: (1) edge-swipe back from wardrobe item detail re-flashes the detail frame — fix via `transitionOnUserGestures: true` on both shared Heroes + pop rebuild guard; (2) bulk delete for wardrobe items (reuse existing `DELETE /wardrobe-items/bulk`) and outfits (sequential `DELETE /outfits/{id}` with partial-failure report); (3) new "system catalog" add-flow mirroring web FE `/wardrobe/explore` against EXISTING `GET /system-catalog/wardrobe-items` + `POST /wardrobe-items/catalog-init` (FE/BE-verified 2026-09-14, zero BE work); (4) AI quota display sync via one shared `AiQuotaDisplay` widget (`"x/y lượt"`) in Profile + Subscription screens. See `research.md` for decisions, `data-model.md` + `contracts/` for shapes, `quickstart.md` for validation.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x

**Primary Dependencies**: flutter_riverpod 2.5 (`StateNotifierProvider`), go_router 14.2, dio 5.4, google_fonts

**Storage**: N/A (server state via Dio; token in flutter_secure_storage — existing, untouched)

**Testing**: flutter_test (`test/` has unit + integration tests); primary gate is manual emulator/device checklist in `quickstart.md` + `flutter analyze` clean

**Target Platform**: Android (emulator first) + iOS (edge-swipe must be verified on real iOS device — emulator gesture differs)

**Project Type**: mobile-app (single Flutter project)

**Performance Goals**: swipe-back pop at 60fps with no re-flash over 20 consecutive pops; bulk delete of 8 items completes < 10s on stable network; catalog first paint < 2s with cached categories

**Constraints**: Dio MUST keep `Accept-Encoding: identity` header (BE gzip gotcha); NEVER call `GET /wardrobe-items/me` (use `/me/wardrobe-items`); BottomSheets wrap `Column` in `SingleChildScrollView`; `ListTile` in colored `Container` needs `Material` wrapper; Quiet Luxury tokens (bg `#FAFAFA`/`#F8F6F0`, text `#111111`, accent `#D9C5B2`, border `#E5E2DE`); touch targets ≥ 44px; quota format exactly `"x/y lượt"`

**Scale/Scope**: ~5 files touched + 3 new files (catalog screen/provider/repo, shared quota widget); lists ≤ 300 items / ≤ 100 outfits; 4 user stories, mobile-only, zero BE work (all endpoints exist and are FE-proven)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` is an unfilled placeholder (no ratified principles/gates) → no constitutional gates to violate. Project governance applied instead (per `closy-mobile-flutter` skill + `PROJECT_AGENT_GUIDE.md` gotchas):

- [x] No new dependencies — Riverpod + GoRouter + Dio + google_fonts only.
- [x] No auth/token/storage changes — existing interceptors/providers reused.
- [x] No upload/SSE flow changes — optimistic UI + SSE + safety polling untouched (bulk delete only invalidates the same stats providers delete-single already does).
- [x] New screens/widgets follow Quiet Luxury tokens + safe-area + existing bottom-nav (no nav restructuring; detail route stays top-level).
- [x] BE contract additions are additive + proposed (no breaking change to existing endpoints).

Post-design re-check: Phase 1 adds no new state-sharing between features (selection state is per-screen, quota stays single-provider) → still passes. No Complexity Tracking entries needed.

## Project Structure

### Documentation (this feature)

```text
specs/004-wardrobe-ux-bulk-quota/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
│   ├── bulk-delete.md
│   ├── system-catalog.md
│   └── quota-display.md
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
lib/
├── core/router/app_router.dart            # (touch only if fallback needed for US1)
├── shared/widgets/
│   └── ai_quota_display.dart              # NEW — shared "x/y lượt" widget (US4)
├── features/wardrobe/
│   ├── data/wardrobe_repository.dart      # + deleteWardrobeItems(ids), + SystemCatalogRepository (US2a, US3)
│   ├── providers/wardrobe_provider.dart   # + deleteItems, selection state (US2a)
│   ├── providers/system_catalog_provider.dart  # NEW (US3, pending-BE tolerant)
│   └── presentation/
│       ├── wardrobe_screen.dart           # selection mode + catalog entry (US2a, US3)
│       ├── item_detail_screen.dart        # transitionOnUserGestures + pop guard (US1)
│       └── system_catalog_screen.dart     # NEW (US3)
├── features/outfit_studio/
│   ├── data/outfit_repository.dart        # + deleteOutfits sequential (US2b)
│   ├── providers/outfits_list_provider.dart  # + deleteOutfits, selection state (US2b)
│   └── presentation/outfits_list_screen.dart # selection mode (US2b)
└── features/profile/presentation/
    ├── profile_screen.dart                # use AiQuotaDisplay (US4)
    └── subscription_detail_screen.dart    # use AiQuotaDisplay (US4)

test/
├── widget/ or *_test.dart                 # extend existing unit/widget tests for new notifier methods + widget
```

**Structure Decision**: Single-project Flutter layout — follow existing `lib/features/<feature>/{data,providers,presentation,models}` slices; shared UI goes to `lib/shared/widgets/`. No new top-level directories.

## Phases (for /speckit-tasks)

- **Phase A (P1)**: US1 swipe-back fix + US4 quota widget (both small, independent, shippable separately).
- **Phase B (P1)**: US2 bulk delete wardrobe + outfits (shared selection pattern, separate notifiers).
- **Phase C (P2)**: US3 system catalog screen + repo + provider against the verified contract (mirror FE `/wardrobe/explore`); integration covered by QS-004.
- **Phase D**: QS-006 regression (`flutter analyze` + upload/SSE + single-delete + Premium flow intact).

## Complexity Tracking

> No constitution violations — nothing to justify.
