# Tasks: Wardrobe UX Bulk Quota Fixes

**Input**: Design documents from `/specs/004-wardrobe-ux-bulk-quota/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md
**Tests**: Not requested in spec — validation is manual per `quickstart.md` (each story phase ends with a QS verify task).
**Organization**: Grouped by user story; each story independently implementable and testable.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: US1/US2/US3/US4 maps to spec.md user stories
- Exact file paths in every code task

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Baseline readiness before any code changes

- [ ] T001 Verify Flutter toolchain and record baseline `flutter analyze` output (repo root; config in `analysis_options.yaml`)
- [ ] T002 [P] Verify backend reachability for `GET /system-catalog/wardrobe-items` and `DELETE /wardrobe-items/bulk` using base URL in `lib/core/constants/app_constants.dart` (read-only check, no code change)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared model used by both bulk-delete tracks (US2a wardrobe + US2b outfits)

**⚠️ CRITICAL**: Complete before any user-story work.

- [ ] T003 Create shared `BulkDeletionResult` value class in `lib/shared/models/bulk_deletion_result.dart` with `deletedIds: List<String>`, `failedIds: List<String>` and invariant `deletedIds + failedIds == requestedIds`

**Checkpoint**: Foundation ready — US1, US2, US3, US4 can now proceed (sequentially by priority, or in parallel if staffed; US1+US4 touch disjoint files from US2/US3).

---

## Phase 3: User Story 1 — Swipe-back không giật (Priority: P1) ✅ MVP

**Goal**: Edge-swipe từ item detail về Wardrobe list mượt trong 1 chuyển động, không nháy lại khung detail; nút mũi tên giữ nguyên.
**Independent Test**: QS-001 — mở detail 1 món → vuốt cạnh trái → về list mượt, giữ scroll + thumbnail (20 lần + zoom + double-back).

### Implementation for User Story 1

- [ ] T004 [P] [US1] Set `transitionOnUserGestures: true` on the list-side Hero (`tag: 'item_${id}'`) in `lib/features/wardrobe/presentation/wardrobe_screen.dart`
- [ ] T005 [P] [US1] Set `transitionOnUserGestures: true` on the detail-side Hero plus guard `wardrobeItemDetailProvider` rebuild during pop in `lib/features/wardrobe/presentation/item_detail_screen.dart` (fallback inside same task: suppress Hero flight on pop only via HeroMode if verification still flickers, enter animation preserved)
- [ ] T006 [US1] Verify QS-001 scenarios in `specs/004-wardrobe-ux-bulk-quota/quickstart.md` on emulator, plus 1 real iOS and 1 real Android device (depends on T004, T005)

**Checkpoint**: US1 fully functional and testable independently — ship as MVP if desired.

---

## Phase 4: User Story 2 — Xóa hàng loạt items + outfits (Priority: P1)

**Goal**: Chế độ chọn nhiều + xác nhận + xóa 1 lần cho cả Wardrobe grid và Outfit grid, báo rõ thành công/thất bại từng phần.
**Independent Test**: QS-002/QS-003 — chọn 3 món → xóa → snackbar số lượng; chọn 2 outfit → xóa; hủy không mất gì; lỗi 1 phần có retry.

### Implementation — Track A: Wardrobe bulk (existing `DELETE /wardrobe-items/bulk`)

- [ ] T007 [P] [US2] Add `deleteWardrobeItems(List<String> ids)` to `lib/features/wardrobe/data/wardrobe_repository.dart` — single `DELETE /wardrobe-items/bulk` with `{ids}`, non-empty guard (contract: `specs/004-wardrobe-ux-bulk-quota/contracts/bulk-delete.md`)
- [ ] T008 [US2] Add `deleteItems(ids)` + `SelectionState{isSelecting, selectedIds:Set<String>}` to `lib/features/wardrobe/providers/wardrobe_provider.dart` — optimistic removal + total decrement, rollback on failure, invalidate `wardrobeInsightsProvider` + `categoryDistributionProvider`, return `BulkDeletionResult` (depends on T003, T007)
- [ ] T009 [US2] Add selection mode UI to `lib/features/wardrobe/presentation/wardrobe_screen.dart` — AppBar morphs to `N đã chọn` + select-all + close, card tap toggles (long-press enters), bottom bar `Xóa (n)` → confirm dialog with count + extra warning line for `status == 3` processing items, success snackbar / failure dialog (depends on T008)

### Implementation — Track B: Outfit bulk (sequential `DELETE /outfits/{id}`)

- [ ] T010 [P] [US2] Add `deleteOutfits(List<String> ids)` to `lib/features/outfit_studio/data/outfit_repository.dart` — sequential `DELETE /outfits/{id}` loop collecting per-item success/failure into `BulkDeletionResult`, never aborts early (contract: `specs/004-wardrobe-ux-bulk-quota/contracts/bulk-delete.md`)
- [ ] T011 [US2] Add `deleteOutfits(ids)` + `SelectionState` to `lib/features/outfit_studio/providers/outfits_list_provider.dart` — progressive removal of successes, keep failures with messages (depends on T003, T010)
- [ ] T012 [US2] Add selection mode UI to `lib/features/outfit_studio/presentation/outfits_list_screen.dart` — same pattern as T009, partial-failure dialog lists failed names + `Thử lại (k)` retrying only `failedIds` (depends on T011)

### Verify

- [ ] T013 [US2] Verify QS-002 + QS-003 scenarios in `specs/004-wardrobe-ux-bulk-quota/quickstart.md`, including airplane-mode failure and empty-filter-list behavior (depends on T009, T012)

**Checkpoint**: US1 + US2 both work independently; single-delete paths unchanged.

---

## Phase 5: User Story 3 — Thêm đồ từ tủ hệ thống (Priority: P2)

**Goal**: Màn hình catalog hệ thống (mirror FE `/wardrobe/explore`): duyệt + lọc + tìm kiếm + tick chọn nhiều + thêm vào tủ qua endpoint thật.
**Independent Test**: QS-004 — mở catalog từ Wardrobe → lọc/tìm → chọn 2 mẫu → `POST /wardrobe-items/catalog-init {catalogItemIds}` → 2 món mới trong grid + snackbar; mẫu đã có hiện `Đã có trong tủ`.
**Contract**: `specs/004-wardrobe-ux-bulk-quota/contracts/system-catalog.md` (endpoints exist, FE/BE-verified — zero BE work).

### Implementation for User Story 3

- [ ] T014 [US3] Add `getSystemCatalogItems({page, limit, categorySlug, q})` + `initClosetFromCatalog({catalogItemIds})` to `lib/features/wardrobe/data/wardrobe_repository.dart` — `GET /system-catalog/wardrobe-items` parsed with existing `WardrobeItemModel.fromJson` into `WardrobePaginationResult`, `POST /wardrobe-items/catalog-init` returning created items
- [ ] T015 [US3] Create `lib/features/wardrobe/providers/system_catalog_provider.dart` — paging (limit 20 like FE), `categorySlug` + debounced `q` filters from existing `categoriesProvider`, `selectedIds:Set<String>`, `inMyWardrobe` dedupe against `wardrobeProvider` items, `initSelected()` posts ids then calls `wardrobeProvider.loadItems(refresh: true)` and clears selection (depends on T014)
- [ ] T016 [US3] Create `lib/features/wardrobe/presentation/system_catalog_screen.dart` — 2-col grid reusing card style from `wardrobe_screen.dart`, category chips, search field (500ms debounce like FE), tap-to-toggle select with check overlay, `Đã có trong tủ` badge for dupes, bottom action bar `Đã chọn N` + `Thêm vào tủ đồ` (disabled at 0 selection and while adding), skeleton loading + error-retry + empty states, Quiet Luxury tokens, touch targets ≥ 44px (depends on T015)
- [ ] T017 [US3] Register top-level `GoRoute('/wardrobe/catalog')` in `lib/core/router/app_router.dart` serving the new screen, and add `Từ tủ đồ hệ thống` option to the upload picker in `lib/features/wardrobe/presentation/wardrobe_screen.dart` navigating to it (depends on T016)
- [ ] T018 [US3] Verify QS-004 scenarios in `specs/004-wardrobe-ux-bulk-quota/quickstart.md`, including offline retry without duplicates and full-wardrobe BE error guidance (depends on T017)

**Checkpoint**: US1 + US2 + US3 all independently functional.

---

## Phase 6: User Story 4 — Đồng bộ hạn mức AI (Priority: P2)

**Goal**: Hồ sơ cá nhân + Gói Hội Viên & Hạn Mức hiển thị cùng số, cùng định dạng `x/y lượt`, từ cùng provider.
**Independent Test**: QS-005 — ghi 2 số ở Hồ sơ → mở trang Gói → trùng số + format + dòng reset 00:00; dùng 1 lượt → cả hai cùng đổi; offline → cả hai hiện tải lại (không số giả).
**Contract**: `specs/004-wardrobe-ux-bulk-quota/contracts/quota-display.md` (no API change; props: `used`, `limit` from same `dailyQuota` object).

### Implementation for User Story 4

- [ ] T019 [P] [US4] Create shared `AiQuotaDisplay` widget in `lib/shared/widgets/ai_quota_display.dart` with props `used:int (required)`, `limit:int (required)` rendering `"$used/$limit lượt"` + `Còn n lượt` + progress bar (orange ≥ 90%) + `Tự động reset 00:00`, states: `loading` (skeleton, never fake `"0/5"`), `error` (retry), `exhausted` (`remaining == 0` red + upgrade hint) — props contract in `specs/004-wardrobe-ux-bulk-quota/data-model.md`
- [ ] T020 [P] [US4] Use `AiQuotaDisplay` for both quota rows in `lib/features/profile/presentation/profile_screen.dart`, values from the existing `subscriptionOverviewProvider.dailyQuota` object (no new fetch)
- [ ] T021 [P] [US4] Use `AiQuotaDisplay` for both quota bars in `lib/features/profile/presentation/subscription_detail_screen.dart`, replacing the `Còn lại: $remaining / $limit` line and keeping existing card layout (T019 props contract shared with T020)
- [ ] T022 [US4] Verify QS-005 scenarios in `specs/004-wardrobe-ux-bulk-quota/quickstart.md` (depends on T019, T020, T021)

**Checkpoint**: All 4 user stories independently functional.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Regression + hygiene across all stories

- [ ] T023 Run `flutter analyze` clean (repo root) and fix only warnings introduced by T004–T022 (no unrelated refactors)
- [ ] T024 [P] Run full QS-006 regression in `specs/004-wardrobe-ux-bulk-quota/quickstart.md` — camera/gallery upload + SSE optimistic flow, single item/outfit delete, Premium purchase flow unchanged
- [ ] T025 [P] UX copy/polish pass on touched screens (`wardrobe_screen.dart`, `outfits_list_screen.dart`, `system_catalog_screen.dart`, `subscription_detail_screen.dart`) — Vietnamese strings, ≥ 44px targets, safe-area + bottom-nav intact, no Gotcha 3/4 violations

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2, T003)**: Depends on Setup — BLOCKS US2 tracks (T008, T011 consume `BulkDeletionResult`)
- **US1 (Phase 3)**: Depends on Setup only — no Foundational dependency, can start immediately (MVP)
- **US2 (Phase 4)**: Depends on Foundational (T003); Tracks A/B parallel after that
- **US3 (Phase 5)**: Depends on Setup only (reuses existing models/providers) — parallelizable with US2
- **US4 (Phase 6)**: Depends on Setup only — parallelizable with everything
- **Polish (Phase 7)**: Depends on all shipped stories

### Within-story ordering

- T008 ← T007 (provider needs repo method); T009 ← T008; T011 ← T010; T012 ← T011; T013 ← T009 + T012
- T015 ← T014; T016 ← T015; T017 ← T016; T018 ← T017
- T022 ← T019 + T020 + T021 (T019/T020/T021 share the data-model props contract, writable in parallel)
- T004 ∥ T005 (different files); T006 ← both

### Parallel Opportunities

- T002 ∥ T001; T004 ∥ T005; Track A (T007→T009) ∥ Track B (T010→T012) after T003
- US3 chain ∥ US2 chains ∥ US4 tasks (disjoint files except `wardrobe_screen.dart` shared by T009-entry? No — T017 edits the upload picker in `wardrobe_screen.dart` while T009 edits its grid/AppBar: same file, so US2-T009 and US3-T017 MUST NOT run in parallel — sequence T009 before T017 or merge carefully)
- T019 ∥ T020 ∥ T021 (props contract fixed); T024 ∥ T025

### Same-file caution

- `lib/features/wardrobe/presentation/wardrobe_screen.dart`: touched by T004 (Hero flag), T009 (selection mode), T017 (catalog entry) — implement sequentially in that order
- `lib/features/wardrobe/data/wardrobe_repository.dart`: touched by T007 (bulk delete) then T014 (catalog) — sequentially in that order

---

## Implementation Strategy

### MVP First (US1 only)

1. Phase 1 (T001–T002) → Phase 3 (T004–T006)
2. **STOP and VALIDATE**: QS-001 on emulator + real devices
3. Demo: swipe-back smooth, arrow-back unchanged

### Incremental Delivery

1. Setup + T003 → foundation ready
2. + US1 (T004–T006) → test QS-001 → MVP demo
3. + US2 (T007–T013) → test QS-002/QS-003 → bulk-delete demo
4. + US3 (T014–T018) → test QS-004 → catalog demo (no BE needed)
5. + US4 (T019–T022) → test QS-005 → quota-sync demo
6. + Polish (T023–T025) → QS-006 regression → done

### Parallel Team Strategy

- Dev A: US1 → US4 (small UI tasks, disjoint files)
- Dev B: US2 Track A + Track B
- Dev C: US3 chain (after agreeing `wardrobe_screen.dart` edit order with Dev B)
- Sync point: T003 (`BulkDeletionResult` API) before US2; `wardrobe_screen.dart` merge order T004 → T009 → T017

---

## Notes

- Catalog endpoints are REAL (`contracts/system-catalog.md`): `GET /system-catalog/wardrobe-items`, `POST /wardrobe-items/catalog-init {catalogItemIds}` — no backend tasks in this plan
- Wardrobe bulk shape verified on BE (`BulkDeleteItemsReq{ids, min=1}`); outfits have no bulk route → sequential singles with `BulkDeletionResult`
- Quota fix is presentation-only; both screens keep reading `subscriptionOverviewProvider.dailyQuota`
