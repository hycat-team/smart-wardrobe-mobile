---

description: "Task list — Canvas một món mỗi loại + sửa áo khoác đè lớp nền"
---

# Tasks: Canvas một món mỗi loại + sửa áo khoác đè lớp nền

**Input**: Design documents from `/specs/017-canvas-single-item/`

**Prerequisites**: plan.md, spec.md (US1/US2/US3), research.md (R1–R5), data-model.md (INV-1..6), contracts/canvas-rules.md, quickstart.md

**Tests**: Có — plan.md (Test Impact) và quickstart yêu cầu test cho thay thế theo vai trò và bố cục outerwear.

**Organization**: Tasks theo user story để mỗi story làm/kiểm thử độc lập.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: chạy song song được (khác file, không phụ thuộc task chưa xong)
- **[Story]**: US1/US2/US3
- Đường dẫn file repo-relative

## Path Conventions

- `lib/features/outfit_studio/{layout,providers}/…`
- `test/…`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Chốt baseline trước khi sửa

- [X] T001 Chạy `flutter analyze` + `flutter test` trên nhánh `017-canvas-single-item`, ghi baseline vào `docs/work-log-2026-10-13.md` — analyze 0, test 257/2 (pre-existing BE)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Không có tác vụ nền chặn.** Cả 3 user story dùng chung enum `CanvasRole`/`normalizeRole` và
`clampCanvasItem` **đã tồn tại** (research §Phát hiện). Vào Phase 3 ngay.

---

## Phase 3: User Story 1 — Mỗi loại một món, thêm trùng tự thay (Priority: P1) 🎯 MVP

**Goal**: Canvas giữ tối đa một món cho mỗi loại cơ bản; thêm món trùng loại → thay thế; đầm↔áo loại trừ (giữ quần); mũ/phụ kiện nhiều món.

**Independent Test**: `flutter test test/studio_single_item_per_role_test.dart` pass (quickstart WS US1/US1b).

### Tests for User Story 1 ⚠️ (viết trước, phải FAIL)

- [X] T002 [P] [US1] Tạo `test/studio_single_item_per_role_test.dart` (pure unit, `ProviderContainer` + `addItemToCanvas`): (a) thêm 2 áo → chỉ còn 1 (đúng món mới) và **id món cũ không còn** trong `canvasItems`; (b) thêm 2 quần → thay quần; (c) thêm đầm khi có áo+quần → gỡ áo, **giữ quần**; (d) thêm áo khi có đầm → gỡ đầm; (e) thêm 2 phụ kiện → **cả hai** còn; (f) thêm món khác loại (giày) → không gỡ áo; (g) thêm vào canvas **trống** → không gỡ nhầm (SC-004); (h) sau thay thế, món mới nằm trong khung và `selectedIndex` trỏ món mới (SC-003/FR-003)

### Implementation for User Story 1

- [X] T003 [US1] Trong `lib/features/outfit_studio/layout/canvas_layout.dart` thêm hằng tập vai trò độc quyền (vd `exclusiveRoles = {top,bottom,fullbody,outerwear,footwear}`) + helper `isExclusiveRole(CanvasRole)`
- [X] T004 [US1] Cập nhật `addItemToCanvas` trong `lib/features/outfit_studio/providers/outfit_studio_provider.dart`: tính gỡ món xung đột **trước** khi chọn `coordinateMap` — cùng vai trò nếu độc quyền; `fullbody`→gỡ `top`; `top`→gỡ `fullbody`; giữ `bottom`; không gỡ `headwear/accessory/other/unknown`. Sau gỡ mới tính `hasFullbody` và đặt món mới theo toạ độ chuẩn + `clampCanvasItem`
- [X] T005 [US1] Chạy `flutter test test/studio_single_item_per_role_test.dart` → pass

**Checkpoint**: US1 hoàn chỉnh (MVP) — canvas không còn 2 món cùng loại.

---

## Phase 4: User Story 2 — Áo khoác không đè lớp nền (Priority: P1)

**Goal**: Outerwear + lớp nền (áo trên hoặc đầm) cùng canvas → xếp hai cột, không chồng ngang.

**Independent Test**: `flutter test test/canvas_outerwear_layout_test.dart` pass (quickstart WS US2).

### Tests for User Story 2 ⚠️

- [X] T006 [P] [US2] Tạo `test/canvas_outerwear_layout_test.dart`: helper `layoutOuterwearBesideBase` — với (áo+áo khoác) và (đầm+áo khoác): `outerwearLeftEdge ≥ baseRightEdge` (không chồng ngang), cả hai trong khung trên ≥2 kích thước canvas; và bất biến: chỉ outerwear (không lớp nền) → không dịch

### Implementation for User Story 2

- [X] T007 [US2] Trong `lib/features/outfit_studio/layout/canvas_layout.dart` thêm helper thuần `List<CanvasItem> layoutOuterwearBesideBase(List<CanvasItem> items, {required double canvasWidth, required double canvasHeight})`: nếu có `outerwear` + lớp nền (`top`/`fullbody`) → chia đôi bề ngang khả dụng (nền trái, outerwear phải), thu `scale` mỗi món để vừa nửa khung (sàn 0.15), rồi `clampCanvasItem`; giữ outerwear `layerOrder` trên
- [X] T008 [US2] Trong `addItemToCanvas` (`outfit_studio_provider.dart`): gọi `layoutOuterwearBesideBase` sau khi thêm, **chỉ khi** món vừa thêm là `outerwear` hoặc lớp nền (`top`/`fullbody`)
- [X] T009 [US2] Chạy `flutter test test/canvas_outerwear_layout_test.dart` → pass

**Checkpoint**: US1 + US2 hoạt động độc lập.

---

## Phase 5: User Story 3 — Trải nghiệm thay thế rõ ràng (Priority: P2)

**Goal**: Khi thay thế, món mới được chọn sẵn và có phản hồi rõ ràng.

**Independent Test**: `flutter test test/studio_single_item_per_role_test.dart` (bổ sung assert) — sau thay thế `selectedIndex` trỏ món mới, món mới nằm trong khung, và `addItemToCanvas` trả `true`.

### Implementation for User Story 3

- [X] T010 [US3] Cho `addItemToCanvas` (`outfit_studio_provider.dart`) **trả về `bool replaced`** (true nếu có ≥1 món bị gỡ do thay thế); trong `lib/features/outfit_studio/presentation/outfit_studio_screen.dart` nhánh drawer `onTap` gọi `addItemToCanvas` → nếu `replaced` thì `ClosyToast.success(context, 'Đã thay thế món cùng loại trên canvas.')` (screen hiện KHÔNG hiển thị `successMessage` của `outfitStudioProvider` — vì vậy dùng giá trị trả về, không thêm listener toàn cục)
- [X] T011 [US3] Bổ sung assertion vào `test/studio_single_item_per_role_test.dart`: `addItemToCanvas` trả `true` khi có thay thế và `false` khi thêm vào canvas trống/khác loại; chạy test → pass

**Checkpoint**: Cả 3 story độc lập hoạt động.

---

## Phase 6: Polish & Cross-Cutting Concerns

- [X] T012 [P] Chạy `flutter analyze` → 0 issues mới (so T001)
- [X] T013 [P] Chạy `flutter test` toàn bộ → không hồi quy (ngoài 2 integration cần BE pre-existing)
- [X] T014 QS máy thật theo `specs/017-canvas-single-item/quickstart.md` §2 (US1/US1b/US2/US3); cập nhật `docs/work-log-2026-10-13.md` (work-log ✅; **QS máy thật: chuyển cho developer**)

---

## Dependencies & Execution Order

- **Setup (T001)**: chạy ngay.
- **Foundational**: không có.
- **US1 (T002–T005)**: độc lập.
- **US2 (T006–T009)**: độc lập về acceptance, nhưng cùng file với US1 (`canvas_layout.dart`, provider) → làm **sau** US1 để tránh xung đột.
- **US3 (T010–T011)**: cùng file provider + test US1 → làm sau US2.
- **Polish (T012–T014)**: sau các story.

### Parallel Opportunities

- T002 và T006 ([P], khác file) — có thể viết song song.
- US1/US2/US3 dùng chung 2 file lõi nên triển khai tuần tự, nhưng acceptance test độc lập.

---

## Implementation Strategy

### MVP First

1. T001 Setup → US1 (T002–T005) → kiểm chứng (canvas hết trùng loại) → demo.

### Incremental

US1 (thay thế) → US2 (outerwear không đè) → US3 (toast/chọn) → Polish.

### Ghi chú

- Tuân thủ gotcha Windows: chỉ sửa file bằng `edit`/`write`.
- Không thêm dependency/route; không sửa BE.
- 3 integration test fail là pre-existing (cần BE), không tính hồi quy.
