---
description: "Task list — Wardrobe Landing, Studio Canvas & AI Status Handling (013)"
---

# Tasks: Wardrobe Default Landing, Studio Canvas Presentation & AI Analysis Status Handling

**Input**: Design documents from `specs/013-wardrobe-studio-status-handling/`

**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/retry-analysis.contract.md`, `contracts/canvas-layout.contract.md`, `contracts/status-ui-matrix.contract.md`, `quickstart.md`, `.specify/memory/constitution.md`

**Tests**: Có — theo DoD dự án (`flutter analyze` 0 issues + `flutter test` liên quan + QS máy thật).

**Organization**: Task nhóm theo user story. US1/US2/US3 (P1) → US4 (P2). Mỗi story độc lập, test được riêng.

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: chạy song song được (khác file, không phụ thuộc task chưa xong)
- **[Story]**: US1/US2/US3/US4 — bắt buộc ở phase user story
- Mọi task có đường dẫn file cụ thể

## Path Conventions

Flutter: `lib/core/**`, `lib/features/**`, `test/**`.

---

## Phase 1: Setup

**Purpose**: Xác minh nguồn sự thật trước khi sửa (hiến pháp II: không bịa endpoint).

- [x] T001 Xác minh API thật của BE 023 trên BE repo: `POST /api/v1/wardrobe-items/{id}/retry-analysis` nhận body `{ categoryId }`, trả `data.status=3` + `taskId`; SSE `/wardrobe-items/tasks/{taskId}/sse` trả `status: processing|completed|failed|needs_review` và `error` là mã lý do — ghi kết quả vào `specs/013-wardrobe-studio-status-handling/research.md`
- [x] T002 [P] Ghi nhận bảng số canvas từ FE (`D:\_HYCAT\smart-wardrobe-fe\src\features\ai-stylist\utils\outfit-canvas-layout.ts`) vào `contracts/canvas-layout.contract.md`; KHÔNG sửa repo FE

**Checkpoint**: nguồn sự thật đã xác nhận.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Model + helper dùng chung cho US2 và US3.

- [x] T003 Mở rộng `lib/features/wardrobe/models/wardrobe_models.dart`: `FashionItemModel` thêm `reviewReason` + `processingErrorReason` (đọc camelCase trước, snake_case dự phòng) trong `fromJson`/`copyWith`; giữ `WardrobeItem.status` số nguyên nguyên vẹn
- [x] T004 Mở rộng `lib/features/outfit_studio/models/outfit_models.dart`: `CanvasItem` thêm `baseScale` (placement.scale FE), `boxRatioW`, `boxRatioH` (tỉ lệ FE) + `copyWith`, giá trị mặc định null-safe
- [x] T005 Tạo `lib/features/wardrobe/utils/analysis_status.dart`: enum/map reason code (`uncertain_category`, `multiple_items_detected`, `full_body_outfit_detected`, `analysis_temporary_error`, `auto_retry_exceeded`) + getter `canRetry`, `requiresCategory`, `messageVi` (mã lạ → message mặc định) — theo `contracts/status-ui-matrix.contract.md`
- [x] T006 Mở rộng `lib/features/outfit_studio/layout/canvas_layout.dart`: `layoutCanvasItems` thêm bước **vừa-khung** sau clamp/de-overlap — tính bbox toàn set, `fitK = min(w/bboxW, h/bboxH, 1)`, tịnh tiến về tâm; giữ nguyên hành vi 1 món ra giữa và clamp lề 8px

**Checkpoint**: model + helper sẵn sàng cho mọi story.

---

## Phase 3: User Story 1 - Tủ đồ là điểm đến mặc định (Priority: P1) 🎯 MVP

**Goal**: Sau đăng nhập/khôi phục phiên → `/wardrobe` trên Web + Android; pending redirect vẫn ưu tiên.

**Independent Test**: Đăng xuất → đăng nhập → vào thẳng tab Tủ đồ; deep-link chờ vẫn ưu tiên.

- [x] T007 [US1] Sửa `lib/core/router/app_router.dart`: `kPostLoginRoute = '/wardrobe'` và nhánh redirect sau-auth trả `'/wardrobe'`; giữ nguyên `pendingRedirect`, guard `isPublicCommunityPage`, redirect `/home → /community` (FR-001, FR-002)
- [x] T008 [P] [US1] Cập nhật test router: mặc định sau login là `/wardrobe`, `/` và `/home` không hồi quy về `/community`, deep-link chờ vẫn ưu tiên — `test/scaffold_with_nav_bar_test.dart` hoặc file test router hiện có

**Checkpoint**: US1 xong (MVP).

---

## Phase 4: User Story 2 - Trạng thái phân tích AI & khắc phục lỗi ảnh (Priority: P1)

**Goal**: 4 trạng thái, mã lý do, retry đúng rule, khóa double-tap, đồng bộ lại khi SSE đứt.

**Independent Test**: Nạp ảnh nhiều món → không có nút Thử lại; nạp ảnh rõ 1 món → chọn danh mục + gửi lại → hoàn tất.

- [x] T009 [US2] Thêm `retryAnalysis({required String id, String? categoryId})` vào `lib/features/wardrobe/data/wardrobe_repository.dart`: POST `/wardrobe-items/{id}/retry-analysis`, parse `data.taskId` (fallback `data.id`), trả lỗi BE nguyên văn; KHÔNG gọi `confirm-review` (FR-014)
- [x] T010 [US2] `lib/features/wardrobe/providers/wardrobe_provider.dart`: thêm `submitNeedsReview({id, categoryId})` + `retryFailedAnalysis({id})`; khoá bấm lặp theo từng item (`_retryingIds`); sau khi có `taskId` thì subscribe SSE lại; cập nhật thông báo theo mã lý do (FR-013, FR-015, FR-016)
- [x] T011 [US2] `lib/features/wardrobe/presentation/wardrobe_screen.dart`: badge trạng thái theo mã lý do (`Đang phân tích` / `Cần chọn danh mục` / `Ảnh có nhiều món` / `Ảnh toàn thân` / `Lỗi tạm thời`), ẩn nút Thử lại với ảnh không hợp lệ, khoá thao tác phối đồ khi processing (FR-012, FR-015)
- [x] T012 [US2] `lib/features/wardrobe/presentation/item_detail_screen.dart`: khối theo mã lý do — chọn danh mục + "Gửi phân tích lại" (bắt buộc chọn, `needsReview`), hoặc ẩn retry + gợi ý "chụp cận cảnh một món duy nhất", hoặc nút "Thử lại" (cooldown/khoá khi đang gửi) (FR-013, FR-015)
- [x] T013 [US2] `lib/features/outfit_studio/presentation/outfit_studio_screen.dart`: trong ngăn kéo chọn đồ, món `processing` hiển thị mờ + huy hiệu "Đang phân tích" và không thể chọn lên canvas (US2/AC6)
- [x] T014 [P] [US2] Tạo `test/wardrobe_retry_test.dart`: repository fake — retry thành công trả `taskId`; thiếu `categoryId` bị 400 và hiện message; gate `canRetry` đúng cho từng mã; khoá double-tap chỉ gửi 1 request
- [x] T028 [US2] `lib/features/wardrobe/providers/wardrobe_provider.dart` (dòng ~405-414): khi SSE đã trả `data` đầy đủ (`completed`/`needs_review`) thì **chỉ patch item trong state, KHÔNG gọi `loadItems(refresh: true)`**; chỉ refetch toàn trang khi payload thiếu `data` hoặc `failed` không kèm `fashionItem` (FR-016)
- [x] T029 [US2] `lib/features/wardrobe/providers/wardrobe_provider.dart` + `lib/features/wardrobe/presentation/wardrobe_screen.dart`: hợp đồng đồng bộ lại khi SSE gián đoạn — mở lại màn tủ đồ / pull-to-refresh phải refetch `GET /me/wardrobe-items` và giải phóng mọi món kẹt `processing` quá ngưỡng thời gian (FR-017, US2-AC5)
- [x] T030 [P] [US2] Tạo `test/wardrobe_status_widget_test.dart`: badge theo từng mã lý do; `needsReview` hiện bộ chọn danh mục + nút gửi lại (disabled khi chưa chọn); ảnh không hợp lệ **không** có nút "Thử lại"; ngăn kéo Studio hiện món `processing` mờ và không chọn được (US2/AC6)

**Checkpoint**: US1 + US2 độc lập.

---

## Phase 5: User Story 3 - Studio Canvas chuẩn giải phẫu (Priority: P1)

**Goal**: Món theo cấu trúc cơ thể, đúng tỉ lệ, đúng lớp, không chồng, vừa khung — như Web FE.

**Independent Test**: Mở set 5 món trên canvas → vị trí/tỉ lệ/lớp đúng, nằm giữa màn hình, không cần kéo tay.

- [x] T015 [US3] `lib/features/outfit_studio/layout/canvas_layout.dart`: port bảng `ROLE_COORDINATES_SEPARATE` / `ROLE_COORDINATES_FULLBODY`, `SECONDARY_ACCESSORY_COORDINATES`, `ROLE_BOUNDING_BOX_RATIOS` (giá trị nguyên văn theo `contracts/canvas-layout.contract.md`) (FR-005..FR-009)
- [x] T016 [US3] `lib/features/outfit_studio/layout/canvas_layout.dart`: bổ sung từ khóa/slug còn thiếu cho `normalizeRole` — khớp cả chuỗi **có dấu** (`"mũ"`, `"nón"`) như FE, thêm fragment `beanie/bucket/sandal/boot/dep/lien/hoodie/len/phukien/that-lung/khan/trang-suc`, slug `chan-vay`/`vay-lien`/`giay-*`/`phu-kien-*`/`ao-*`; thêm `detectCompositionType` (fullbody → FULLBODY; có top/bottom → SEPARATE_PIECES; còn lại → INCOMPLETE) (FR-005, FR-006)
- [x] T017 [US3] `lib/features/outfit_studio/layout/canvas_layout.dart`: thêm `restoreCanvasPlacement()` — vai trò thân trên mà `y > 0` đảo dấu; `x == ±1` (default 0) ⇒ 0; outerwear `x == 25` ⇒ −25; footwear `y == 305` ⇒ 295; gần gốc ⇒ dùng tọa độ chuẩn; `positionX/positionY` null hoặc không phải số ⇒ dùng tọa độ chuẩn theo vai trò (edge case dữ liệu legacy)
- [x] T018 [US3] `lib/features/outfit_studio/providers/outfit_studio_provider.dart`: `loadFromAIRecommendation` dùng layout mới — loại trừ top/bottom khi có fullbody, dedupe vai trò chính, phụ kiện so le cánh đối diện, gán `baseScale`/`boxRatio*`, `layerOrder` theo z-index (FR-008..FR-011)
- [x] T019 [US3] `lib/features/outfit_studio/providers/outfits_list_provider.dart`: `loadIntoStudio` dùng `restoreCanvasPlacement()` cho outfit đã lưu và áp layout mới (kể cả nhánh legacy toạ độ 0) (FR-005, FR-011)
- [x] T020 [US3] `lib/features/outfit_studio/presentation/outfit_studio_screen.dart`: thay khung vuông `200 × scale` (dòng ~1051-1072) bằng khung chữ nhật theo vai trò `w = baseScale×boxRatioW×scale×fitK`, `h = baseScale×boxRatioH×scale×fitK`; giữ zoom/kéo/thả và lưu toạ độ mới (FR-007, FR-011, US3/AC6)
- [x] T021 [P] [US3] Tạo `test/canvas_layout_test.dart`: tọa độ từng role đúng bảng; bbox ratio đúng; fullbody loại top/bottom; phụ kiện 2+ so le; dedupe vai trò chính; INCOMPLETE dựng như SEPARATE; restore legacy đảo dấu; vừa-khung không tràn vùng vẽ

**Checkpoint**: US1 + US2 + US3 (P1) xong.

---

## Phase 6: User Story 4 - Gỡ thông báo đáy màn hình khi lưu outfit (Priority: P2)

**Goal**: Lưu thành công → chuyển thẳng `/outfits`, không SnackBar; lỗi vẫn báo rõ.

**Independent Test**: Lưu outfit thành công → thấy danh sách bộ đồ ngay, không có thanh SnackBar nào.

- [x] T022 [US4] `lib/features/outfit_studio/presentation/outfit_studio_screen.dart` (~dòng 176-182): gỡ SnackBar thành công trong dialog "Lưu Trang Phục", giữ `context.push('/outfits')` ngay sau lưu và giữ SnackBar lỗi (FR-003, FR-004)
- [x] T023 [US4] `lib/features/outfit_studio/presentation/outfit_studio_screen.dart` (~dòng 955-965) + `lib/features/stylist/presentation/stylist_screen.dart`: gỡ mọi SnackBar **thành công khi lưu outfit** từ gợi ý AI. **Phạm vi:** chỉ nhánh lưu outfit; KHÔNG đụng SnackBar nạp/xoá/thông báo khác (VD `outfits_list_screen.dart:330/337/396` là nạp-xoá, giữ nguyên) (FR-003)
- [x] T024 [P] [US4] Cập nhật test widget save-outfit: không có `SnackBar` khi thành công, vẫn có khi lỗi — `test/outfit_integration_test.dart` hoặc test studio hiện có

**Checkpoint**: Toàn bộ user story xong.

---

## Phase 7: Polish & Cross-Cutting Concerns

- [x] T025 Chạy `flutter analyze` (0 issues) + `flutter test` liên quan (`test/canvas_layout_test.dart`, `test/wardrobe_retry_test.dart`, `test/scaffold_with_nav_bar_test.dart`); nếu integration fail phải chứng minh pre-existing bằng `git stash` (mẫu spec 009/012)
- [ ] T026 Chạy `quickstart.md` QS-001..QS-004 trên Chrome (`--web-port=8081`) + Android; ghi kết quả thực tế vào work-log
- [x] T027 [P] Cập nhật `docs/work-log-2026-09-28.md`: task nào xong/còn, file mới/sửa, việc cần người dùng (ví dụ: retry ảnh invalid bị BE 400 là kỳ vọng đúng — không phải bug app)

**Checkpoint**: sẵn sàng bàn giao.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: trước mọi thứ (xác minh nguồn thật).
- **Foundational (Phase 2)**: chặn US2 (T003, T005) và US3 (T004, T006) — phải xong trước khi code UI của 2 story này.
- **User Stories**: US1 → US2 → US3 → US4 theo ưu tiên P1 → P2; US1 độc lập hoàn toàn, có thể làm trước.
- **Polish (Phase 7)**: sau khi story mong muốn xong.

### User Story Dependencies

- **US1**: độc lập (chỉ router).
- **US2**: cần T003 + T005; không phụ thuộc US1/US3.
- **US3**: cần T004 + T006; không phụ thuộc US1/US2.
- **US4**: độc lập (cùng file `outfit_studio_screen.dart` với US3 ⇒ chạy **sau US3** để tránh conflict).

### Within Each User Story

- Model/helper → provider → repository → UI → test; UI trước khi chốt.

### Parallel Opportunities

- T002 (Setup) song song T001.
- T008 (US1 test) song song T007.
- T014 (US2 test) song song T009–T013; **T028–T030 là task bổ sung từ `/speckit.analyze`, chạy ngay sau T014**.
- T021 (US3 test) song song T015–T020.
- T024 (US4 test) song song T022–T023.
- T027 (Polish) song song T025–T026.

## Parallel Example: User Story 2

```bash
Task: "T010 [US2] wardrobe_provider.dart — submitNeedsReview/retry + khoá + SSE"
Task: "T011 [US2] wardrobe_screen.dart — badge theo mã lý do"
Task: "T012 [US2] item_detail_screen.dart — chọn danh mục / ẩn retry / Thử lại"
Task: "T013 [US2] outfit_studio_screen.dart — ngăn kéo: processing không chọn được"
```

## Implementation Strategy

### MVP First (US1)

1. Phase 1 Setup → Phase 2 Foundational
2. Phase 3 US1 → **DỪNG & KIỂM CHỨNG** (QS-001) → demo
3. Rồi tới US2 (QS-002), US3 (QS-003), US4 (QS-004)

### Incremental Delivery

1. US1 → demo (landing tủ đồ)
2. US2 → demo (xử lý lỗi ảnh)
3. US3 → demo (canvas chuẩn giải phẫu)
4. US4 → demo (gỡ snackbar)
5. Polish: analyze/test + QS đầy đủ + work-log

---

## Notes

- [P] = khác file, không phụ thuộc
- T028–T030 là task bổ sung từ `/speckit.analyze` (vá I1/U1/U2); chạy trong Phase 4 ngay sau T014
- US4 sửa cùng file với US3 ⇒ chạy sau US3
- BE 023 đã triển khai: mobile chỉ tuân thủ hợp đồng, không sửa BE
- FE chỉ đọc tham khảo bảng số; không sửa repo FE
- Tuân thủ constitution: no-mock, Quiet Luxury, ảnh qua `ClosyNetworkImage`, UTF-8, không thêm dependency
