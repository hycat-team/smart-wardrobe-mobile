# Tasks: Home Stats Infinite Scroll

**Input**: Design documents from `/specs/006-home-stats-infinite-scroll/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md
**Tests**: Not requested — validation is manual per `quickstart.md`.
**Organization**: Grouped by user story; each story independently implementable and testable.

## Format: `[ID] [P?] [Story] Description`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Baseline before changes

- [ ] T001 Verify baseline `flutter analyze` clean (repo root; config in `analysis_options.yaml`)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Stats source shared by US1 (Home counts depend on it)

**⚠️ CRITICAL**: Complete before US1.

- [ ] T002 Add `WardrobeStats{activeItemsCount, outfitsCount}` model in `lib/features/wardrobe/models/wardrobe_models.dart` parsing `GET /me/wardrobe-items/stats` envelope (contract: `specs/006-home-stats-infinite-scroll/contracts/pagination.md` §3)
- [ ] T003 Add `getWardrobeStats()` to `lib/features/wardrobe/data/wardrobe_repository.dart` + `wardrobeStatsProvider` (FutureProvider, same pattern as `wardrobeInsightsProvider`) in `lib/features/wardrobe/providers/wardrobe_provider.dart` (depends on T002)

**Checkpoint**: Foundation ready — US1/US2/US3 can proceed (US2/US3 touch different files from US1; same-file order inside each story).

---

## Phase 3: User Story 1 — Home trùng số Thống kê (Priority: P1) ✅ MVP

**Goal**: Home lấy tổng món/giá trị tủ/outfit từ nguồn stats, có loading/lỗi đúng phần.
**Independent Test**: QS-001 — so số Home vs Thống kê; offline hiện retry.

### Implementation for User Story 1

- [ ] T004 [US1] Rewire quick-stats in `lib/features/home/presentation/home_screen.dart` to `wardrobeInsightsProvider` (`totalItems`, `formattedTotalValue`) + `wardrobeStatsProvider` (`outfitsCount`), refresh invalidates insights + stats + distribution, per-section loading skeleton + error-retry instead of partial numbers (depends on T003; minimal edits — file is teammate's uncommitted work)
- [ ] T005 [US1] Verify QS-001 in `specs/006-home-stats-infinite-scroll/quickstart.md` (depends on T004)

**Checkpoint**: US1 fully functional and testable independently — ship as MVP if desired.

---

## Phase 4: User Story 2 — Wardrobe infinite scroll (Priority: P1)

**Goal**: Kéo gần cuối tự tải nối tiếp, dedupe, single-flight, reset khi filter/refresh.
**Independent Test**: QS-002 — 35 món tải đủ; đổi filter reset; lỗi giữ vị trí; 0 request trùng.

### Implementation for User Story 2

- [ ] T006 [US2] Add `isLoadingMore` + `hasMore` + `loadMore()` + stale-guard to `WardrobeNotifier` in `lib/features/wardrobe/providers/wardrobe_provider.dart` — append page+1 with id-dedupe (keep optimistic processing head), single-flight guard, refresh/selectCategory reset page 1 and drop stale responses
- [ ] T007 [US2] Add scroll-threshold trigger (`NotificationListener<ScrollNotification>`, ~400px) + footer sliver (spinner/error-retry) in `lib/features/wardrobe/presentation/wardrobe_screen.dart` (depends on T006; keep selection mode + upload banner intact)
- [ ] T008 [US2] Verify QS-002 in `specs/006-home-stats-infinite-scroll/quickstart.md` (depends on T007)

**Checkpoint**: US1 + US2 both work independently.

---

## Phase 5: User Story 3 — Outfit infinite scroll (Priority: P2)

**Goal**: Outfit tải nối tiếp trang 50, giữ tick chọn, hết thì dừng.
**Independent Test**: QS-003 — 60 outfit tải đủ; giữ selection khi append.

### Implementation for User Story 3

- [ ] T009 [US3] Add `OutfitPaginationResult` + `getMyOutfitsPaginated({page, limit})` in `lib/features/outfit_studio/data/outfit_repository.dart` parsing `page/total` (keep old `getMyOutfits` if other callers use it — check first)
- [ ] T010 [US3] Add `page/total/isLoadingMore/hasMore` + `loadMore()` to `OutfitsListNotifier` in `lib/features/outfit_studio/providers/outfits_list_provider.dart` — append + id-dedupe, single-flight guard, `selectedIds` preserved, delete adjusts total (depends on T009)
- [ ] T011 [US3] Add scroll-threshold trigger + trailing loader in `lib/features/outfit_studio/presentation/outfits_list_screen.dart` (depends on T010; keep selection UI + bottom bar intact)
- [ ] T012 [US3] Verify QS-003 in `specs/006-home-stats-infinite-scroll/quickstart.md` (depends on T011)

**Checkpoint**: All 3 stories independently functional.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Regression

- [ ] T013 Run `flutter analyze` clean (repo root), fix only new warnings
- [ ] T014 [P] Verify QS-004 regression in `specs/006-home-stats-infinite-scroll/quickstart.md` + existing `flutter test` suite at baseline (pre-existing integration load failures out of scope)

---

## Dependencies & Execution Order

- **Setup (T001)** → **Foundational (T002→T003)** BLOCKS US1
- **US1 (T004→T005)** — MVP; needs T003
- **US2 (T006→T007→T008)** — needs Setup only (disjoint files from US1) → parallelizable with US1
- **US3 (T009→T010→T011→T012)** — needs Setup only → parallelizable with US1/US2
- **Polish (T013→T014)** last

### Same-file caution

- `wardrobe_provider.dart`: T003 (provider wiring) → T006 (paging) sequentially
- `wardrobe_screen.dart`: T007 only; `outfits_list_screen.dart`: T011 only
- `home_screen.dart`: T004 only (coordinate with teammate — file uncommitted)

---

## Implementation Strategy

### MVP First (US1 only)

1. T001 → T002 → T003 → T004
2. **STOP and VALIDATE**: QS-001
3. Demo: Home numbers match Insights

### Incremental Delivery

1. + US1 → QS-001 → demo (MVP!)
2. + US2 → QS-002 → demo
3. + US3 → QS-003 → demo
4. + Polish → QS-004 → done
