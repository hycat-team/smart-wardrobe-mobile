---

description: "Task list — Sửa lỗi theo phản hồi tester (đợt 1)"
---

# Tasks: Sửa lỗi theo phản hồi tester (đợt 1)

**Input**: Design documents from `/specs/016-tester-feedback-fixes/`

**Prerequisites**: plan.md, spec.md (7 user story), research.md (R1–R8), data-model.md, contracts/, quickstart.md

**Tests**: Có — spec/plan/quickstart yêu cầu test cho clamp canvas, phân loại "Áo khoác", xoá canvas, render Markdown; và cập nhật 2 test bị ảnh hưởng bởi việc gỡ UI (`community_search_filter_test.dart`, `wardrobe_status_widget_test.dart`).

**Organization**: Tasks grouped by user story để mỗi story có thể làm/kiểm thử độc lập.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Có thể chạy song song (khác file, không phụ thuộc task chưa xong)
- **[Story]**: US1..US7 tương ứng user story trong spec.md
- Đường dẫn file là repo-relative (mobile feature-first)

## Path Conventions

- `lib/features/<domain>/{layout,providers,presentation}/…`
- `test/…`
- `pubspec.yaml`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Chốt baseline trước khi sửa

- [ ] T001 Chạy `flutter analyze` và `flutter test` trên nhánh `016-tester-feedback-fixes`, ghi lại số issues + test fail hiện tại vào `docs/work-log-2026-10-13.md` (mốc so sánh pre-existing)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Điều kiện nền chặn mọi user story.

**Không có tác vụ nền chặn.** 7 nhóm việc độc lập về kỹ thuật; tiện ích dùng chung
(`normalizeRole`, `outfitRoleLabelVi`, `clearCanvas`, `layoutCanvasItems`) **đã tồn tại** và
được tái dùng (research.md §Phát hiện). Vào Phase 3 ngay.

**Checkpoint**: Nền sẵn sàng — bắt đầu user story.

---

## Phase 3: User Story 1 — Thêm món không tràn viền (Priority: P1) 🎯 MVP

**Goal**: Mọi món thêm thủ công (phụ kiện, giày, món "khác") nằm trọn trong biên canvas, theo kích thước canvas đo được.

**Independent Test**: `flutter test test/canvas_layout_test.dart test/studio_canvas_placement_test.dart` pass; kéo khay và thêm phụ kiện/giày/món "khác" trên canvas nhỏ → không tràn (quickstart WS-A).

### Tests for User Story 1 ⚠️ (viết trước, phải FAIL khi chưa sửa)

- [X] T002 [P] [US1] Thêm test cho `clampCanvasItem` (kẹp 1 món vượt biên; thu nhỏ khi món quá khổ) vào `test/canvas_layout_test.dart`
- [X] T003 [P] [US1] Tạo `test/studio_canvas_placement_test.dart`: `addItemToCanvas` cho accessory/footwear/other trên **3 kích thước canvas** (320×520, 390×700, 430×932) → mọi món nằm trong biên (INV-1..3; thoả SC-001)

### Implementation for User Story 1

- [X] T004 [US1] Thêm helper công khai `clampCanvasItem(CanvasItem, canvasWidth, canvasHeight)` trong `lib/features/outfit_studio/layout/canvas_layout.dart` (tổng quát hoá `_clamp`, margin 8px, thêm nhánh giảm `scale` nếu `itemW/H` lớn hơn vùng khả dụng)
- [X] T005 [US1] Cập nhật `addItemToCanvas` trong `lib/features/outfit_studio/providers/outfit_studio_provider.dart`: sau khi đặt theo `coordinateMap[role]`, gọi `clampCanvasItem` với `state.canvasWidth/Height` (fallback 360×520); **chỉ** kẹp món mới
- [X] T006 [US1] Chạy `flutter test test/canvas_layout_test.dart test/studio_canvas_placement_test.dart` → pass; xác nhận không đổi vị trí món đã có

**Checkpoint**: US1 hoàn chỉnh, kiểm thử độc lập được (MVP).

---

## Phase 4: User Story 2 — "Áo khoác" + khay mượt + đóng bằng icon (Priority: P1)

**Goal**: Có danh mục "Áo khoác"; kéo khay không giật; chạm icon mũi tên xuống để thu gọn.

**Independent Test**: `flutter test test/studio_drawer_category_test.dart` pass; kéo khay không giật và đóng bằng icon (quickstart WS-B).

### Tests for User Story 2 ⚠️

- [X] T007 [P] [US2] Tạo `test/studio_drawer_category_test.dart`: chip "Áo khoác" chỉ trả outerwear; chip "Áo" **loại trừ** outerwear

### Implementation for User Story 2

- [X] T008 [P] [US2] Cập nhật `OutfitStudioState.filteredWardrobeItems` trong `lib/features/outfit_studio/providers/outfit_studio_provider.dart`: thêm nhánh `Áo khoác` (dùng `normalizeRole(...) == CanvasRole.outerwear`) và sửa `Áo` để loại trừ outerwear; giữ nguyên các chip khác
- [X] T009 [US2] Thêm chip "Áo khoác" vào danh sách chip khay (`['All','Áo','Áo khoác','Quần','Váy','Giày','Phụ kiện']`, nhãn qua `outfitRoleLabelVi`) trong `lib/features/outfit_studio/presentation/outfit_studio_screen.dart`
- [X] T010 [US2] Bỏ `setState` theo ngưỡng trong `_onSheetScrolled`; theo dõi trạng thái mở/đóng bằng `ValueNotifier<bool>` cục bộ và bọc **chỉ** header khay + phép dịch nút "Lưu" trong `ValueListenableBuilder` (không rebuild cây canvas) trong `lib/features/outfit_studio/presentation/outfit_studio_screen.dart`
- [X] T011 [US2] Đổi icon mũi tên hạ xuống ở header khay mở thành `IconButton` (`onPressed: _toggleDrawer`, tooltip "Thu gọn", vùng chạm ≥44px) trong `lib/features/outfit_studio/presentation/outfit_studio_screen.dart`
- [X] T012 [US2] Chạy `flutter test test/studio_drawer_category_test.dart` → pass; QS kéo khay + đóng bằng icon trên máy (QS deferred — chờ developer kiểm trên thiết bị thật)

**Checkpoint**: US1 + US2 cùng hoạt động độc lập.

---

## Phase 5: User Story 3 — Nút "Xóa tất cả" (Priority: P2)

**Goal**: Nút "Xóa tất cả" trên thanh công cụ phải xoá sạch canvas (có xác nhận).

**Independent Test**: `flutter test test/studio_clear_all_test.dart` pass; thêm món → bấm "Xóa tất cả" + xác nhận → canvas trống (quickstart WS-C).

### Tests for User Story 3 ⚠️

- [X] T013 [P] [US3] Tạo `test/studio_clear_all_test.dart`: `clearCanvas()` xoá hết `canvasItems` và bỏ chọn

### Implementation for User Story 3

- [X] T014 [US3] Đổi điều kiện hiển thị thanh công cụ phải trong `_buildManualStudioTab` sang `state.canvasItems.isNotEmpty`; vô hiệu hoá (không `onPressed`) các nút thao tác món khi `selectedIndex == null` trong `lib/features/outfit_studio/presentation/outfit_studio_screen.dart`
- [X] T015 [US3] Thêm `IconButton` "Xóa tất cả" (`Icons.delete_sweep_rounded`, tooltip "Xóa tất cả") + dialog xác nhận Quiet Luxury gọi `ref.read(outfitStudioProvider.notifier).clearCanvas()` trong `lib/features/outfit_studio/presentation/outfit_studio_screen.dart`
- [X] T016 [US3] Chạy `flutter test test/studio_clear_all_test.dart` → pass; QS nút ẩn khi canvas trống

**Checkpoint**: US1–US3 hoàn tất.

---

## Phase 6: User Story 4 — Chat AI render Markdown (Priority: P2)

**Goal**: Tin nhắn Stylist hiển thị định dạng Markdown, không lộ ký tự thô.

**Independent Test**: `flutter test test/stylist_markdown_render_test.dart` pass; gửi câu hỏi có danh sách/đậm → hiển thị đúng (quickstart WS-D).

### Implementation for User Story 4

- [X] T017 [US4] Thêm `flutter_markdown_plus` vào `pubspec.yaml` (mục `dependencies`) và chạy `flutter pub get`
- [X] T018 [US4] Tạo `test/stylist_markdown_render_test.dart`: (a) nội dung có `**đậm**`/danh sách render thành widget Markdown, không còn ký tự thô; (b) văn bản thuần + cú pháp chưa đóng (fence/bold dở) render an toàn, không ném exception
- [X] T019 [US4] Thay `Text(msg.cleanContent …)` trong `_buildMessageBubble` bằng `MarkdownBody` (`flutter_markdown_plus`) với `MarkdownStyleSheet` Quiet Luxury (Be Vietnam Pro/Playfair, palette dự án) trong `lib/features/stylist/presentation/stylist_screen.dart`; giữ nhánh "Đang suy nghĩ..." khi rỗng + streaming
- [X] T020 [US4] Chạy `flutter test test/stylist_markdown_render_test.dart` → pass; QS stream không nhấp nháy lỗi (quickstart WS-D)

**Checkpoint**: US1–US4 hoàn tất.

---

## Phase 7: User Story 5 — Gỡ ô "Demo" màn Đăng ký (Priority: P3)

**Goal**: Màn tạo tài khoản không còn điều khiển điền mẫu tự động.

**Independent Test**: Mở màn Đăng ký → không còn chip "Điền mẫu tự động (Demo)"; form gửi OTP bình thường (quickstart WS-E).

### Implementation for User Story 5

- [X] T021 [US5] Gỡ `ActionChip` "Điền mẫu tự động (Demo)" và method `_fillSampleRegister` trong `lib/features/auth/presentation/register_screen.dart`
- [X] T022 [US5] QS màn Đăng ký: không còn ô Demo; validate + gửi OTP vẫn chạy

**Checkpoint**: US5 hoàn tất độc lập.

---

## Phase 8: User Story 6 — Gỡ nút "Phối đồ Studio" ở chi tiết món (Priority: P3)

**Goal**: Chi tiết món đồ không còn lối vào Studio.

**Independent Test**: `flutter test test/wardrobe_status_widget_test.dart` pass; mở chi tiết món → không có nút "Phối đồ Studio", "Chỉnh sửa" vẫn chạy (quickstart WS-F).

### Implementation for User Story 6

- [X] T023 [US6] Gỡ `ElevatedButton.icon` "Phối đồ Studio" (và `context.push('/studio')` tương ứng) trong `lib/features/wardrobe/presentation/item_detail_screen.dart`; cho `OutlinedButton` "Chỉnh sửa" giãn toàn bộ hàng; gỡ import thừa nếu không dùng
- [X] T024 [US6] Cập nhật `test/wardrobe_status_widget_test.dart`: gỡ 3 assert `find.widgetWithText(ElevatedButton, 'Phối đồ Studio')` (nút đã bỏ — thay đổi có chủ đích)
- [X] T025 [US6] Chạy `flutter test test/wardrobe_status_widget_test.dart` → pass

**Checkpoint**: US6 hoàn tất độc lập.

---

## Phase 9: User Story 7 — Đơn giản hoá tìm kiếm Community (Priority: P3)

**Goal**: Bỏ hàng lọc loại bài trong tìm kiếm; kết quả gồm mọi loại bài.

**Independent Test**: `flutter test test/community_search_filter_test.dart` pass; tìm kiếm ở tab "Bài viết" không còn chip loại bài (quickstart WS-G).

### Implementation for User Story 7

- [X] T026 [US7] Gỡ hàng 2 (chip "Tất cả bài/Bộ phối/Ảnh-Video") và `_buildPostTypeChip`; cố định `preferredSize` chỉ còn hàng segmented trong `lib/features/community/presentation/community_search_screen.dart`
- [X] T027 [US7] Ngừng dùng `postTypeFilter` trong luồng tìm kiếm (`lib/features/community/providers/community_search_provider.dart`): `executeSearch`/`loadMorePosts` luôn truyền `postType: null`; giữ field để tránh lan rộng model
- [X] T028 [US7] Cập nhật `test/community_search_filter_test.dart`: đổi assert hàng 2 sang `findsNothing` cho `Tất cả bài/Bộ phối/Ảnh-Video` (thay đổi có chủ đích)
- [X] T029 [US7] Chạy `flutter test test/community_search_filter_test.dart` → pass

**Checkpoint**: Tất cả 7 user story độc lập hoạt động.

---

## Phase 10: Polish & Cross-Cutting Concerns

**Purpose**: Cổng chất lượng bàn giao

- [ ] T030 [P] Chạy `flutter analyze` → 0 issues mới (so baseline T001)
- [ ] T031 [P] Chạy `flutter test` toàn bộ test liên quan → pass (không hồi quy ngoài 2 test sửa chủ đích)
- [ ] T032 QS máy thật theo `specs/016-tester-feedback-fixes/quickstart.md` §2 cho cả 7 nhóm (WS-A→G); cập nhật `docs/work-log-2026-10-13.md` (spec/task xong, file sửa, việc cần user)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Không phụ thuộc — chạy ngay.
- **Foundational (Phase 2)**: Không có tác vụ nền chặn.
- **User Stories (Phase 3–9)**: Độc lập, có thể làm song song theo nhân lực.
  - **Ràng buộc file**: US1, US2, US3 cùng sửa `outfit_studio_screen.dart`/provider → **tuần tự** (US1 → US2 → US3).
  - US4 (`stylist_screen.dart` + `pubspec.yaml`), US5 (`register_screen.dart`), US6 (`item_detail_screen.dart` + test), US7 (`community_search_screen.dart`/provider + test) — **file tách biệt**, chạy song song được.
- **Polish (Phase 10)**: Sau khi các story mong muốn xong.

### User Story Dependencies

- **US1 (P1)**: Không phụ thuộc story khác — MVP.
- **US2 (P1)**: Độc lập, nhưng cùng file với US1 nên làm sau US1 để tránh xung đột.
- **US3 (P2)**: Độc lập; cùng file với US1/US2 → làm sau US2.
- **US4 (P2)**: Độc lập (file khác, thêm dependency).
- **US5 (P3)**, **US6 (P3)**, **US7 (P3)**: Độc lập hoàn toàn.

### Trong mỗi story

Tests (nếu có) viết trước và phải FAIL → impl → verify pass.

### Parallel Opportunities

- T002 và T003 ([P], khác file).
- T008 và T009: T008 (provider) [P] với T009 (screen) — khác file; nhưng T009 cần T008 để chip có tác dụng.
- US5 / US6 / US7 có thể chạy song song với nhau và với US4 (khác file hoàn toàn).
- T030 và T031 ([P]).

---

## Parallel Example: nhóm US4/US5/US6/US7 (sau khi Setup xong)

```bash
# Cùng lúc, mỗi người một story khác file:
Task: "US4 — thêm flutter_markdown_plus + render MarkdownBody trong stylist_screen.dart"
Task: "US5 — gỡ chip Demo trong register_screen.dart"
Task: "US6 — gỡ nút Phối đồ Studio trong item_detail_screen.dart + sửa wardrobe_status_widget_test.dart"
Task: "US7 — gỡ hàng lọc loại bài trong community_search_screen.dart + sửa community_search_filter_test.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1)

1. Phase 1 Setup (T001)
2. Phase 2: không có nền chặn
3. Phase 3: US1 (T002–T006)
4. **DỪNG & KIỂM CHỨNG** US1 độc lập (quickstart WS-A)
5. Demo nếu sẵn sàng

### Incremental Delivery

1. US1 → kiểm chứng (lỗi chặn Studio, giá trị cao nhất)
2. US2 → kiểm chứng
3. US3 → kiểm chứng
4. US4 → kiểm chứng
5. US5, US6, US7 (P3, rủi ro thấp) → kiểm chứng
6. Polish (analyze/test/QS/work-log)

### Ghi chú

- **Sửa test có chủ đích** (không phải hồi quy): T024 (`wardrobe_status_widget_test.dart`), T028 (`community_search_filter_test.dart`).
- Không thêm route/deep-link; không sửa BE; không đụng `ENABLE_PAID_FEATURES`.
- Tuân thủ gotcha Windows §6: chỉ sửa file bằng tool `edit`/`write`, không `Get-Content | -replace | Set-Content`.
- Cập nhật `docs/work-log-2026-10-13.md` sau mỗi nhóm (T001 ghi baseline, T032 ghi kết thúc).
