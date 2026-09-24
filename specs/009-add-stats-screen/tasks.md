---
description: "Task list for Statistics Screen"
---

# Tasks: Statistics Screen

**Input**: Design documents from `/specs/009-add-stats-screen/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/stats-data.md, quickstart.md

**Tests**: Không có yêu cầu TDD trong spec. Dùng validation thủ công theo `quickstart.md` + `flutter analyze`/`flutter test` baseline.

**Organization**: Task nhóm theo user story để triển khai/kiểm thử độc lập.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: chạy song song (file khác nhau, không phụ thuộc)
- **[Story]**: US1 / US2 / US3
- Đường dẫn file chính xác trong mô tả

## Path Conventions

Single Flutter project: `lib/`, `specs/009-add-stats-screen/`.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Xác minh dữ liệu nền tảng trước khi code

- [X] T001 [P] Xác minh API dashboard (`/me/dashboard/wardrobe-statistics` hoặc mở rộng `/me/dashboard/wardrobe-insights`): ghi lại trường nào có trong `totalItems`, `totalWardrobeValueVnd`, `lastWornDaysAgo`, `categories`, `outfits`, `wearCount`, `wearHistory`; kết luận fallback nếu thiếu `wearCount`/`wearHistory`; ghi vào `specs/009-add-stats-screen/research.md` (FR-014, contract D1, QS-000)

**Checkpoint**: Biết chắc dữ liệu nào dùng được → quyết định hiển thị hay ẩn cost-per-wear/xu hướng

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Model và widget dùng chung cho mọi story

**⚠️ CRITICAL**: Hoàn tất trước khi bắt đầu user story

- [X] T002 Tạo `lib/features/wardrobe/models/wardrobe_stats_models.dart` gồm `StatsBundle`, `UtilizationMetric`, `ValueMetric`, `CategoryValue`, `CostPerWear`, `OutfitStat`, `TimeTrendPoint` đúng `data-model.md`; ràng buộc verbatim: `utilizationRate` trong 0.0–1.0 và bằng `(totalItems - unused30) / totalItems`, `totalItems == 0 → 0.0`; `costPerWear` là `null` khi `wearCount == 0`; `TimeTrendPoint.month` định dạng `YYYY-MM` (FR-002→007, data-model)
- [X] T003 [P] Tạo `lib/shared/widgets/stats_bar_chart.dart` — bar chart bằng `CustomPainter` (không thêm package), nhận danh sách điểm theo tháng, hỗ trợ rỗng/< 2 điểm (R4, contract D5)

**Checkpoint**: Model + widget sẵn sàng

---

## Phase 3: User Story 1 - Tổng quan & mức độ sử dụng (Priority: P1) 🎯 MVP

**Goal**: Màn Thống kê mới truy cập từ Hồ sơ, hiển thị tổng món, tỷ lệ sử dụng, món ít mặc 30/60/90, có empty/error/refresh.

**Independent Test**: Vào Hồ sơ → "Thống kê chi tiết"; đối chiếu tổng món và món ít mặc 30/60/90 với dữ liệu thực tế.

### Implementation for User Story 1

- [X] T004 [US1] Thêm `getWardrobeStatistics()` vào `lib/features/wardrobe/data/wardrobe_repository.dart` (additive, dùng `ApiClient`/`dio` sẵn có; xử lý lỗi tiếng Việt như `getWardrobeInsights`) (FR-001/002/003, R3)
- [X] T005 [US1] Tạo `lib/features/wardrobe/providers/wardrobe_stats_provider.dart` với `FutureProvider.autoDispose<StatsBundle>` (R5)
- [X] T006 [US1] Tạo `lib/features/wardrobe/presentation/wardrobe_statistics_screen.dart` khung màn: `AsyncValue.when` (data/loading/error), `RefreshIndicator`, trạng thái rỗng khi `totalItems == 0`, nút "Thử lại" (FR-008, contract D3)
- [X] T007 [US1] Thêm section tổng quan + mức độ sử dụng vào `wardrobe_statistics_screen.dart`: tổng món, `utilizationRate` (%), món ít mặc 30/60/90; dùng `AppColors`/`GoogleFonts`, đọc rõ sáng/tối (FR-002/003/011, R7/R9)
- [X] T008 [US1] Thêm GoRoute `/wardrobe/statistics` vào `lib/core/router/app_router.dart` (FR-001, R1)
- [X] T009 [US1] Thêm `_buildMenuTile` "Thống kê chi tiết" trong `lib/features/profile/presentation/profile_screen.dart`, giữ nguyên mục "Thống kê & Phân tích tủ đồ" cũ (FR-001, R1)
- [X] T010 [US1] Chạy QS-001 và QS-002 trong `specs/009-add-stats-screen/quickstart.md`; xác nhận tải < 3 giây và số liệu khớp (SC-001/SC-002)

**Checkpoint**: US1 hoàn chỉnh và kiểm thử độc lập (MVP)

---

## Phase 4: User Story 2 - Giá trị & cost-per-wear (Priority: P2)

**Goal**: Tổng giá trị, giá trị theo danh mục, cost-per-wear với xử lý món chưa mặc/thiếu giá.

**Independent Test**: Đối chiếu tổng giá trị với giá mua; tính thủ công `price / wearCount` cho vài món.

### Implementation for User Story 2

- [X] T011 [US2] Thêm section giá trị vào `wardrobe_statistics_screen.dart`: tổng giá trị, giá trị theo danh mục, chú thích `missingPriceCount` khi có món thiếu giá (FR-004, data-model ValueMetric)
- [X] T012 [US2] Thêm cost-per-wear vào `wardrobe_statistics_screen.dart`: `purchasePriceVnd / wearCount`; món `wearCount == 0` hiển thị "Chưa mặc" (không chia 0) (FR-005, contract D2, data-model CostPerWear)
- [X] T013 [US2] Xử lý fallback `wearDataAvailable == false`: ẩn cost-per-wear kèm ghi chú "Chưa có dữ liệu", không hiển thị số ước lượng (FR-014, contract D1/D3)
- [X] T014 [US2] Chạy QS-003 trong `quickstart.md`; xác nhận cost-per-wear đúng 100% trên mẫu kiểm thử (SC-004)

**Checkpoint**: US1 và US2 cùng hoạt động độc lập

---

## Phase 5: User Story 3 - Outfit & xu hướng (Priority: P3)

**Goal**: Thống kê outfit và biểu đồ xu hướng theo tháng 6 tháng gần nhất.

**Independent Test**: Đối chiếu số outfit với dữ liệu thực tế; đối chiếu biểu đồ với lịch sử mặc theo tháng.

### Implementation for User Story 3

- [X] T015 [US3] Thêm section outfit vào `wardrobe_statistics_screen.dart`: tổng outfit đã lưu (và đã dùng nếu API cung cấp), không tải toàn bộ list nếu có aggregate (FR-006, R8)
- [X] T016 [US3] Thêm section xu hướng vào `wardrobe_statistics_screen.dart` dùng `stats_bar_chart.dart`: tối đa 6 điểm tháng gần nhất; nếu < 2 điểm có dữ liệu hiển thị "chưa đủ dữ liệu" thay vì biểu đồ rỗng (FR-007, contract D2, data-model TimeTrendPoint)
- [X] T017 [US3] Chạy QS-004 trong `quickstart.md`; xác nhận outfit và biểu đồ khớp dữ liệu (SC-003)

**Checkpoint**: Cả 3 user story hoàn chỉnh

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Chất lượng, hồi quy, tài liệu

- [X] T018 Chạy `flutter analyze` (sạch) và `flutter test` (baseline) sau khi thêm màn (FR-008)
- [X] T019 Kiểm tra hiệu năng tài khoản nhiều món (tải < 3 giây) và khả năng đọc ở chế độ sáng/tối (SC-001/SC-006)
- [X] T020 Chạy QS-005 và ma trận SC-003 (5 tài khoản: rỗng, ít món, nhiều món, thiếu giá, nhiều outfit): trạng thái rỗng, mất mạng/thử lại, sáng/tối, và xác nhận `/wardrobe/insights` cũ không hồi quy (SC-003/SC-005)
- [X] T021 [P] Ghi chú kết quả xác minh API + quyết định fallback vào `specs/009-add-stats-screen/research.md` (FR-014)
- [X] T022 [P] Xác minh nhất quán số liệu (FR-009): tổng số món khớp Home quick stats, tổng giá trị khớp `/wardrobe/insights` trên cùng tài khoản/thời điểm
- [X] T023 [P] Xác minh quyền riêng tư (FR-012): màn chỉ gọi API có xác thực, không log/hiển thị dữ liệu người dùng khác

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: bắt đầu ngay
- **Foundational (Phase 2)**: T002 sau T001 (biết trường dữ liệu); T003 độc lập — CHẶN user story
- **User Stories (Phase 3+)**: đều sau Foundational
  - US1 → US2 → US3 theo ưu tiên
  - US2/US3 dùng chung screen/provider từ US1 (không tách file riêng) nên làm tuần tự sau US1
- **Polish (Phase 6)**: sau các story mong muốn

### User Story Dependencies

- **US1 (P1)**: sau Foundational — không phụ thuộc story khác (MVP)
- **US2 (P2)**: sau US1 (cùng file screen/provider) và sau T001/T013 fallback
- **US3 (P3)**: sau US1; dùng T003 chart widget; cần T001 cho dữ liệu xu hướng

### Parallel Opportunities

- T003 (chart) song song với T002 (models)
- T011 và T015 cùng sửa `wardrobe_statistics_screen.dart` nên KHÔNG song song; chạy tuần tự
- T021, T022, T023 song song trong Polish

---

## Parallel Example

```bash
# Foundational song song:
Task: "T002 Tạo model wardrobe_stats_models.dart"
Task: "T003 Tạo stats_bar_chart.dart CustomPainter"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Hoàn tất Phase 1 (T001 xác minh API)
2. Hoàn tất Phase 2 (T002, T003)
3. Hoàn tất Phase 3 US1 (T004–T010)
4. **DỪNG và VALIDATE**: QS-001/QS-002; đối chiếu số liệu thực tế

### Incremental Delivery

1. Setup + Foundational → nền tảng sẵn sàng
2. US1 → validate (MVP: tổng quan + mức độ sử dụng)
3. US2 → validate (giá trị + cost-per-wear)
4. US3 → validate (outfit + xu hướng)
5. Polish → analyze/test + hồi quy

---

## Notes

- Không thêm dependency runtime; biểu đồ dùng `CustomPainter` (T003)
- Không sửa hành vi `/wardrobe/insights` cũ (T020 kiểm tra)
- Fallback khi thiếu dữ liệu mặc: ẩn chỉ số + ghi chú, không bịa số (T013)
- Chi tiêu ví/gói ngoài phạm vi (spec FR-013)
