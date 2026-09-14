# Tasks: Loadmore Chip Contrast

**Input**: Design documents from `/specs/007-loadmore-chip-contrast/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md
**Tests**: Not requested — validation is manual per `quickstart.md` (with network-log cross-check).
**Organization**: Grouped by user story.

## Format: `[ID] [P?] [Story] Description`

---

## Phase 1: Setup (Shared Infrastructure)

- [ ] T001 Verify baseline `flutter analyze` clean (repo root; config in `analysis_options.yaml`)

---

## Phase 2: Foundational

No shared prerequisite — state machine lives per-notifier (different limits). Proceed to stories. **Checkpoint**: none blocking.

---

## Phase 3: User Story 1 — Load-more tải thật (Priority: P1) ✅ MVP

**Goal**: `hasMore` v2 + axis filter trên cả 2 list; bao mọi case BE xấu, tối đa 2 probe thừa.
**Independent Test**: QS-001/QS-002 — 35 món + 60 outfit tải đủ; log mạng 0 trùng.

### Implementation for User Story 1

- [ ] T002 [US1] Add `lastPageWasFull/emptyStreak/loadMoreExhausted` + `hasMore` v2 to `WardrobeState` in `lib/features/wardrobe/providers/wardrobe_provider.dart` (defaults false/0/false; copyWith; page-size const 20), wire into `loadItems(refresh)` reset + `loadMore()` transitions per research R2
- [ ] T003 [US1] Add vertical-axis filter to the `NotificationListener` in `lib/features/wardrobe/presentation/wardrobe_screen.dart` (ignore `metrics.axis != Axis.vertical`) (depends on T002 for the flags it protects; different file → writable in parallel once formula agreed)
- [ ] T004 [US1] Mirror T002 in `OutfitsListNotifier` (`lib/features/outfit_studio/providers/outfits_list_provider.dart`, page-size const 50; `fetchOutfits` resets flags) [P] (different file, same pattern)
- [ ] T005 [US1] Add vertical-axis filter to the `NotificationListener` in `lib/features/outfit_studio/presentation/outfits_list_screen.dart` [P] (different file)
- [ ] T006 [US1] Verify QS-001 + QS-002 in `specs/007-loadmore-chip-contrast/quickstart.md` with network-log cross-check (depends on T002–T005)

**Checkpoint**: US1 fully functional and testable independently — ship as MVP if desired.

---

## Phase 4: User Story 2 — Chip trắng khi chọn (Priority: P2)

**Goal**: Checkmark trắng trên chip đang chọn, 3 điểm chip.
**Independent Test**: QS-003.

### Implementation for User Story 2

- [ ] T007 [P] [US2] Set `checkmarkColor: selected ? white : primary` on both `ChoiceChip`s in `lib/features/wardrobe/presentation/wardrobe_screen.dart`
- [ ] T008 [P] [US2] Set `checkmarkColor` same rule on `_CategoryChip` in `lib/features/wardrobe/presentation/system_catalog_screen.dart`
- [ ] T009 [US2] Verify QS-003 in `specs/007-loadmore-chip-contrast/quickstart.md` (depends on T007–T008)

**Checkpoint**: Both stories independently functional.

---

## Phase 5: Polish & Cross-Cutting Concerns

- [ ] T010 Run `flutter analyze` clean (repo root), fix only new warnings
- [ ] T011 [P] Verify QS-004 (006 SC-002→SC-006 still green) + `flutter test` suite at baseline

---

## Dependencies & Execution Order

- T001 → T002 → T003; T004 ∥ T002 (same pattern, different files); T005 ∥ T003
- T006 ← T002–T005; T007 ∥ T008 → T009; T010 → T011

### Same-file caution

- `wardrobe_provider.dart`: T002 only; `outfits_list_provider.dart`: T004 only
- `wardrobe_screen.dart`: T003 (listener) + T007 (chips) — different regions, sequence T003 then T007 to avoid edit conflicts

---

## Implementation Strategy

### MVP First (US1 only)

1. T001 → T002 (+T004 in parallel) → T003 (+T005) → T006
2. **STOP and VALIDATE**: QS-001/QS-002 + network log
3. Demo: 35/35 items, 60/60 outfits by scrolling
