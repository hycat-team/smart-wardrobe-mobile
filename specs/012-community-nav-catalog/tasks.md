---
description: "Task list — Community Home, Bulk Add & System Catalog Admin (012)"
---

# Tasks: Community Home, Bulk Add & System Catalog Admin

**Input**: Design documents from `specs/012-community-nav-catalog/`

**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/ui-behavior-contracts.md`, `quickstart.md`, `.specify/memory/constitution.md`

**Tests**: Có — theo DoD dự án (`flutter analyze` 0 issues + `flutter test` liên quan).

**Organization**: Task nhóm theo user story. Thứ tự phase ưu tiên P1 → P2. **US4 (admin) ngoài phạm vi v1 → không có task.**

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Chạy song song được (khác file, không phụ thuộc task chưa xong)
- **[Story]**: US1/US2/US3/US5/US6
- Mọi task có đường dẫn file cụ thể

## Path Conventions

Flutter: `lib/shared/**`, `lib/core/**`, `lib/features/**`, `test/**`.

---

## Phase 1: Setup

**Purpose**: Chuẩn bị/kiểm kê trước khi sửa.

- [X] T001 Kiểm kê các tab & route hiện tại (`lib/shared/widgets/scaffold_with_nav_bar.dart`, `lib/core/router/app_router.dart`) và liệt kê chuỗi tiếng Anh cần Việt hoá ra `specs/012-community-nav-catalog/research.md` (mục "Inventory")
- [X] T002 [P] Xác nhận `image_picker` có `pickMultiImage` và `google_sign_in` có `GoogleSignIn.instance.signOut()`/`disconnect()` (không cần thêm dependency) — ghi chú vào `plan.md`/`research.md`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Xác nhận cơ chế dùng chung trước khi sửa từng story.

- [X] T003 Xác nhận cơ chế phiên: `lib/core/session/session_provider.dart`, `lib/features/auth/providers/auth_provider.dart` (logout bump session, clear token) để tái dùng cho US5
- [X] T004 [P] Xác nhận `isPublicCommunityPage`/guard trong `lib/core/router/app_router.dart` không chặn `/community` và sẽ xử lý `/home` redirect an toàn (US1)

**Checkpoint**: Nền tảng rõ — bắt đầu user story.

---

## Phase 3: User Story 1 - Community thành tab chính, ẩn Home (Priority: P1) 🎯 MVP

**Goal**: Thanh nav 5 tab [Tủ đồ, Cộng đồng, Phối đồ AI, Stylist AI, Hồ sơ]; ẩn Home; `/home` → `/community`.

**Independent Test**: Mở app → 5 tab đúng thứ tự, không có Home; bấm Cộng đồng mở Community; nhập `/home` → về Community.

- [X] T005 [US1] Sửa `lib/shared/widgets/scaffold_with_nav_bar.dart`: 5 tab theo thứ tự **[Tủ đồ, Cộng đồng, Phối đồ AI, Stylist AI, Hồ sơ]** (bỏ Home); tab Community dùng `Icons.public`/`Icons.public_outlined`, nhãn "Cộng đồng" (FR-001, FR-002, FR-015, FR-016)
- [X] T006 [US1] Sửa `lib/core/router/app_router.dart`: bỏ branch Home khỏi `StatefulShellRoute`; đổi tab mặc định về `/community`; thêm `GoRoute('/home', redirect: (_, __) => '/community')`; giữ `/community` + `/users/:username` + guard (FR-003, FR-004, FR-014)
- [X] T007 [US1] Loại tham chiếu `HomeScreen` khỏi nav/router (`lib/features/home/**`): giữ file nếu còn dùng nội bộ, ngược lại xoá; đảm bảo không còn import thừa (FR-001)
- [X] T008 [P] [US1] Test `test/nav_test.dart`: 5 tab đúng thứ tự, không có Home, tap Community mở feed, `/home` → `/community`

**Checkpoint**: US1 hoàn chỉnh (MVP).

---

## Phase 4: User Story 2 - Nạp nhiều món đồ cùng lúc (Priority: P1)

**Goal**: Chọn nhiều ảnh một lần → thêm nhiều món; tiến trình; lỗi từng ảnh độc lập.

**Independent Test**: Chọn 4 ảnh → 4 món vào tủ; 1 ảnh lỗi không chặn ảnh khác; có thử lại.

- [X] T009 [US2] Mở rộng `lib/features/wardrobe/providers/upload_wardrobe_provider.dart`: `pickAndUploadMultiple` dùng `ImagePicker.pickMultiImage`; state batch (`batchTotal/batchCompleted/failedFiles/progress`); mỗi ảnh signature→Cloudinary→batch-upload độc lập; giữ `pickAndUpload` (1 ảnh) (FR-005, FR-006, FR-007)
- [X] T010 [US2] Cập nhật `lib/features/wardrobe/presentation/wardrobe_screen.dart`: thêm option "Chọn nhiều ảnh"; hiển thị tiến trình `x/N`; nút "Thử lại" cho `failedFiles`; tôn trọng hạn mức gói (FR-007, FR-008)
- [X] T011 [P] [US2] Test `test/upload_bulk_test.dart`: state batch, ảnh lỗi không chặn ảnh khác, giới hạn hạn mức

**Checkpoint**: US1 + US2 độc lập.

---

## Phase 5: User Story 5 - Google login đúng tài khoản (Priority: P1)

**Goal**: Mỗi tài khoản Google vào đúng tài khoản Closy; không tái dùng phiên/tài khoản cũ.

**Independent Test**: Login Google A → logout → login Google B → hồ sơ/tủ đồ là B.

- [X] T012 [US5] Sửa `lib/features/auth/presentation/widgets/google_sign_in_button.dart`: gọi `GoogleSignIn.instance.signOut()` **trước** `authenticate()`/luồng GIS để mở lại account chooser; nếu GIS vẫn tự chọn tài khoản cũ, bổ sung bước buộc hiển thị chọn tài khoản (FR-013)
- [X] T013 [US5] Sửa `lib/features/auth/providers/auth_provider.dart`: **clear phiên/state cũ** (token + `AuthState`) trước khi bắt đầu `loginWithGoogle`; đảm bảo lưu token mới ghi đè và `sessionProvider` reset đúng (FR-012, FR-013)
- [X] T014 [P] [US5] Test `test/auth_google_test.dart` (mở rộng): đổi tài khoản → user mới; phiên cũ bị clear; không lẫn dữ liệu

**Checkpoint**: US1–US5 (P1) xong.

---

## Phase 6: User Story 3 - Tủ đồ hệ thống ẩn món thiếu ảnh (Priority: P2)

**Goal**: Món hệ thống thiếu ảnh không hiển thị/không chọn; empty state VI; ghi chú BE bổ sung ảnh.

**Independent Test**: Mở tủ hệ thống → món thiếu ảnh không xuất hiện; rỗng → empty state VI.

- [X] T015 [US3] Sửa `lib/features/wardrobe/providers/system_catalog_provider.dart`: lọc bỏ món có ảnh rỗng khỏi danh sách; `toggleSelect` chặn món không hợp lệ (`isSelectable`) (FR-009, FR-010)
- [X] T016 [US3] Sửa `lib/features/wardrobe/presentation/system_catalog_screen.dart`: ẩn món thiếu ảnh; empty state tiếng Việt khi danh sách rỗng (FR-009, FR-010)
- [X] T017 [P] [US3] Test (thêm vào `test/upload_bulk_test.dart` hoặc `test/system_catalog_test.dart`): món thiếu ảnh bị ẩn/không chọn

**Checkpoint**: US3 độc lập.

---

## Phase 7: User Story 6 - Việt hoá toàn bộ giao diện (Priority: P2)

**Goal**: Thay chuỗi tiếng Anh hiển thị sang tiếng Việt trên các màn chính.

**Independent Test**: Duyệt các màn chính → không còn chuỗi tiếng Anh.

- [X] T018 [US6] Việt hoá `lib/features/wardrobe/presentation/wardrobe_screen.dart` (`Digital Closet` → "Tủ đồ số") và các chuỗi EN khác trong file (FR-017)
- [X] T019 [P] [US6] Việt hoá `lib/features/marketplace/presentation/marketplace_screen.dart` (search hint, `Retry` → "Thử lại", …) (FR-017)
- [X] T020 [P] [US6] Rà & Việt hoá các màn còn lại: `lib/features/auth/**`, `lib/features/outfit_studio/**`, `lib/features/stylist/**`, `lib/features/profile/**`, `lib/features/wardrobe/item_*` (FR-017)
- [X] T021 [P] [US6] Kiểm tra không còn chuỗi EN trong **các màn người dùng thấy** (grep `Text('...')`/hint) và ghi kết quả; giữ nguyên tên thương hiệu/model (FR-017, FR-018, SC-006)

**Checkpoint**: Toàn bộ user story xong.

---

## Phase 8: Polish & Cross-Cutting Concerns

- [X] T022 [P] Ghi chú yêu cầu **BE bổ sung ảnh** cho món hệ thống (`ao/quan/giay`) + cập nhật `docs/work-log-<yyyy-mm-dd>.md`
- [X] T023 Chạy `flutter analyze` (0 issues) + `flutter test` liên quan; sửa mọi vấn đề
- [X] T024 [P] Chạy `quickstart.md` QS-001..QS-005 trên Chrome + Android; ghi kết quả

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: bắt đầu ngay
- **Foundational (Phase 2)**: xác nhận cơ chế; không chặn cứng nhưng nên xong trước US5
- **User Stories**: US1/US2/US5 (P1) → US3/US6 (P2). Các story độc lập, có thể song song nếu đủ người.
- **Polish (Phase 8)**: sau khi các story mong muốn xong.

### User Story Dependencies

- **US1 (P1)**: độc lập.
- **US2 (P1)**: độc lập (chỉ wardrobe).
- **US5 (P1)**: độc lập (auth), dùng cơ chế T003.
- **US3 (P2)**: độc lập (wardrobe catalog).
- **US6 (P2)**: độc lập (chuỗi UI), **có thể trùng file với US1/US3** → chạy sau US1/US3 để tránh conflict.

### Within Each User Story

- Sửa file trước, test sau; UI trước khi chốt.

### Parallel Opportunities

- T002 (Setup) song song T001
- T004 (Foundational) song song
- T008 (US1 test) song song sau T005–T007
- T011 (US2 test), T014 (US5 test), T017 (US3 test), T019/T020/T021 (US6) song song theo phase
- T022, T024 (Polish) song song

## Parallel Example: User Story 6

```bash
Task: "T019 [US6] Việt hoá marketplace_screen.dart"
Task: "T020 [US6] Rà & Việt hoá auth/studio/stylist/profile/wardrobe item_*"
```

---

## Implementation Strategy

### MVP First (US1)

1. Phase 1 Setup → Phase 2 Foundational
2. Phase 3 US1 → **DỪNG & KIỂM CHỨNG** (QS-001) → demo
3. Rồi tới US2, US5 (P1), US3, US6 (P2)

### Incremental Delivery

1. US1 → demo (nav Community)
2. US2 → demo (nạp nhiều ảnh)
3. US5 → demo (google login đúng tài khoản)
4. US3 → demo (catalog sạch)
5. US6 → demo (tiếng Việt)
6. Polish: analyze/test + QS đầy đủ + work-log

---

## Notes

- [P] = khác file, không phụ thuộc
- **US4 (admin) không có task** — ngoài phạm vi v1 (Q2=C)
- US6 có thể trùng file US1/US3 → chạy sau để tránh xung đột
- Google web cần Authorized JS origin (ngoài code); ảnh món hệ thống cần BE bổ sung
- Tuân thủ constitution: no-mock, Quiet Luxury, ảnh qua `ClosyNetworkImage`, UTF-8

---

## Phase 9: Convergence

- [X] T025 [US2] Thêm khoá thao tác trùng khi đang tải: `pickAndUpload`/`pickAndUploadMultiple` MUST bỏ qua nếu `uploadWardrobeProvider.state.isUploading`; disable nút "Thêm đồ" (app bar) và các option trong `_showUploadPicker` khi `uploadState.isUploading` — `lib/features/wardrobe/providers/upload_wardrobe_provider.dart`, `lib/features/wardrobe/presentation/wardrobe_screen.dart` per FR-007 (partial)
- [X] T026 [US2] Xử lý hạn mức gói khi nạp nhiều ảnh: nhận diện lỗi hạn mức từ BE (batch-upload) và hiển thị thông báo tiếng Việt rõ "đã vượt hạn mức gói" thay cho message chung, giữ nguyên các món hợp lệ đã nạp — `lib/features/wardrobe/providers/upload_wardrobe_provider.dart`, `lib/features/wardrobe/data/wardrobe_repository.dart` per FR-008 (partial)
- [X] T027 [US6] Hoàn tất Việt hoá chuỗi hiển thị còn tiếng Anh trên màn người dùng thấy: nhãn filter marketplace (`All/Outerwear/Knitwear/Tailoring/Footwear` — giữ value EN gửi BE, chỉ đổi nhãn hiển thị), chip gợi ý search community (`Minimalism/Smart Casual/Workwear/Monochrome/Weekend Vibe`), palette/style preferences (`Neutral/Earth/Monochrome/Vibrant/Minimalist/Casual`), drawer `All` + tên mặc định `Outfit …` (outfit studio), `Regular Fit` (item detail), `ACTIVE` (subscription), `Like New` (product model) — giữ tên thương hiệu/model — per FR-017 (partial)
---

## Phase 10: Convergence

- [X] T028 [US6] Việt hoá nhãn màn **thanh toán/hồ sơ**: `'VietQR / Banking'` → `'VietQR / Chuyển khoản'` (`lib/features/profile/presentation/payment_waiting_screen.dart`) và đơn vị `'set'` → `'bộ'` (`lib/features/profile/presentation/subscription_detail_screen.dart`, `lib/features/profile/presentation/subscription_upgrade_screen.dart`) — giữ tên riêng `VietQR`, `CLOSY VIP` — per FR-017 (partial)
- [X] T029 [US6] Việt hoá tiêu đề/placeholder fallback khi thiếu dữ liệu: `'AI Stylist'` → `'Stylist AI'` (`lib/features/stylist/presentation/stylist_screen.dart`), tên mặc định `'Outfit …'`/`'Outfit'` → `'Bộ phối …'` (`lib/features/outfit_studio/providers/outfit_studio_provider.dart`, `lib/features/outfit_studio/models/outfit_models.dart`), brand placeholder `'DESIGNER'` → `'Thương hiệu'` (`lib/features/marketplace/models/product_model.dart`) — per FR-017 (partial)

---

## Phase 11: Convergence

- [X] T030 [US6] Việt hoá tên sản phẩm fallback của marketplace (hiển thị khi BE `/market/products` lỗi): dịch `name` các mock trong `MarketplaceRepository.getProducts` sang tiếng Việt (giữ nguyên `brand` và `category` value tiếng Anh để lọc đúng) — `lib/features/marketplace/data/marketplace_repository.dart` per FR-017 (partial)



