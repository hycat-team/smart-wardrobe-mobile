# Tasks: Studio Canvas Positions

**Input**: Design documents from `/specs/005-studio-canvas-positions/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md
**Tests**: Not requested in spec — validation is manual per `quickstart.md`.
**Organization**: Grouped by user story; each story independently implementable and testable.

## Format: `[ID] [P?] [Story] Description`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Baseline before changes

- [ ] T001 Verify baseline `flutter analyze` clean (repo root; config in `analysis_options.yaml`)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Pure layout helper + role normalization used by both stories

**⚠️ CRITICAL**: Complete before any user-story work.

- [ ] T002 Create pure helper in `lib/features/outfit_studio/layout/canvas_layout.dart` — `normalizeRole(rawRole, categorySlug)` per research R2 (7 canonical roles + VI slug fragments + `unknown`), `roleSlot(role, occurrenceIndex)` per research R3 table (existing 5 offsets frozen; outerwear/headwear/unknown/duplicate cascade), `layoutCanvasItems(items, canvasW, canvasH)` per research R4 (scale-aware clamp with 8px margin, all-(0,0) legacy detection, 80px pairwise de-overlap max 5 tries, single-item centering). Pure Dart, no Flutter imports, operates on `CanvasItem` values.

**Checkpoint**: Foundation ready — US1 and US2 can proceed (sequentially; both touch `outfit_studio_provider.dart`/`outfits_list_screen.dart` regions — do not parallelize same-file edits).

---

## Phase 3: User Story 1 — Set AI đúng vị trí (Priority: P1) ✅ MVP

**Goal**: Nạp set AI lên canvas: mỗi vai trò đúng vùng riêng, không chồng, không ngoài khung.
**Independent Test**: QS-001/QS-002 — set 3 món cơ bản + set có áo khoác/mũ/phụ kiện.

### Implementation for User Story 1

- [ ] T003 [US1] Rewrite `loadFromAIRecommendation` in `lib/features/outfit_studio/providers/outfit_studio_provider.dart` to use `normalizeRole(group.role, fashionItem.category.slug)` + `roleSlot(role, occurrencePerRole)` instead of the hardcoded 5-role if-chain (role/scale/layerOrder preserved, `clearSelection: true` + success message kept)
- [ ] T004 [US1] Apply `layoutCanvasItems` post-pass in `lib/features/outfit_studio/providers/outfit_studio_provider.dart` after building AI canvas items, using last-known canvas size (fallback 360x520 when unknown — canvas size plumbed from `outfit_studio_screen.dart` LayoutBuilder via a `setCanvasSize(w, h)` notifier method in the same file)
- [ ] T005 [US1] Verify QS-001 + QS-002 in `specs/005-studio-canvas-positions/quickstart.md` (depends on T003, T004)

**Checkpoint**: US1 fully functional and testable independently — ship as MVP if desired.

---

## Phase 4: User Story 2 — Mở outfit đã lưu giữ bố cục (Priority: P1)

**Goal**: Mở outfit đã lưu đúng vị trí/tỉ lệ/lớp đã lưu, kẹp trong khung, legacy tự dàn, 1 món ra giữa, hỏi trước khi ghi đè đồ dở.
**Independent Test**: QS-003/QS-004/QS-005 — lưu→mở trùng khớp; outfit 1 món; ghi đè có hỏi.

### Implementation for User Story 2

- [ ] T006 [US2] Update `loadIntoStudio` in `lib/features/outfit_studio/providers/outfits_list_provider.dart` to keep stored `positionX/positionY/scale/layerOrder` then run `layoutCanvasItems` post-pass (clamp + de-overlap + all-(0,0) legacy → role auto-layout via fashionItem category slug + single-item centering), using last-known canvas size shared from `outfit_studio_provider.dart`
- [ ] T007 [US2] Add overwrite-confirm dialog in `lib/features/outfit_studio/presentation/outfit_studio_screen.dart` at both `loadFromAIRecommendation` call sites (lines ~874, ~898) and the `loadIntoStudio` entry path — when `canvasItems.isNotEmpty`, ask Ghi đè/Giữ lại before replacing (depends on T003–T006 for the load functions' final behavior)
- [ ] T008 [US2] Verify QS-003 + QS-004 + QS-005 in `specs/005-studio-canvas-positions/quickstart.md` (depends on T006, T007)

**Checkpoint**: US1 + US2 both work independently; manual drag/scale/layer/save unchanged.

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Cross-size + regression

- [ ] T009 Verify QS-006 (different screen sizes) in `specs/005-studio-canvas-positions/quickstart.md`
- [ ] T010 Run `flutter analyze` clean (repo root) and existing `flutter test` suite green (same pass/fail as baseline: pre-existing `auth/outfit_integration` load failures due to `[IP_ADDRESS]` placeholder are out of scope)

---

## Dependencies & Execution Order

- **Setup (T001)** → **Foundational (T002)** BLOCKS US1/US2
- **US1 (T003→T004→T005)** — MVP; no dependency on US2
- **US2 (T006→T007→T008)** — needs T002; T007 needs final load behavior (T003–T006)
- **Polish (T009–T010)** last

### Same-file caution

- `lib/features/outfit_studio/providers/outfit_studio_provider.dart`: T003 → T004 sequentially
- `lib/features/outfit_studio/presentation/outfit_studio_screen.dart`: T004 (canvas size plumbing) → T007 (dialog) sequentially

---

## Implementation Strategy

### MVP First (US1 only)

1. T001 → T002 → T003 → T004
2. **STOP and VALIDATE**: QS-001/QS-002
3. Demo: AI set lands arranged, no center-stack

### Incremental Delivery

1. + US1 → test → demo (MVP!)
2. + US2 → test QS-003/004/005 → demo
3. + Polish → QS-006 + analyze/test → done
