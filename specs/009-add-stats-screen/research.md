# Research: Statistics Screen

**Feature**: specs/009-add-stats-screen
**Date**: 2026-09-19
**Scope**: mobile-only; backend phối hợp nếu thiếu dữ liệu (FR-014).

## R1 — Route & điểm vào

**Decision**: Màn mới tại route `/wardrobe/statistics` (sibling của `/wardrobe/insights`), entry từ trang Hồ sơ bằng `_buildMenuTile` mới ("Thống kê chi tiết"), giữ nguyên mục "Thống kê & Phân tích tủ đồ" hiện có.
**Rationale**: Cùng domain tủ đồ; tách biệt khỏi insights cũ (không thay thế); tái dùng pattern menu sẵn có (`profile_screen.dart`).
**Alternatives**: Đặt `/profile/statistics` — bị loại vì nội dung thuộc wardrobe; thêm tab bottom nav — bị loại vì thay đổi điều hướng lớn.

## R2 — Nguồn dữ liệu (FR-014, bước bắt buộc đầu tiên)

**Verified trong code hiện tại**:
- `wardrobe_models.dart` chỉ có `lastWornDaysAgo` cho món ít mặc; KHÔNG có số lần mặc / lịch sử mặc.
- Endpoints dashboard hiện có: `/me/dashboard/wardrobe-insights`, `/me/dashboard/wardrobe-stats`, `/me/dashboard/wardrobe/category-distribution`; outfits qua `/me/outfits`.
- `WardrobeInsightsModel` có: `totalItems`, `totalWardrobeValueVnd`, `underutilizedItemsCount`, `underutilizedItems[]`, `expiringVouchersCount`.
- `WardrobeStats` (getWardrobeStats) cung cấp tổng món/outfit cho Home.

**Decision**: Trước khi code cost-per-wear/xu hướng, xác minh API (A0). Kỳ vọng hợp đồng dữ liệu (xem `contracts/stats-data.md`):
- Có sẵn chắc chắn: `totalItems`, `totalWardrobeValueVnd`, `underutilizedItems[]` (có `lastWornDaysAgo`), category distribution, outfit count.
- CẦN xác minh/bổ sung: `wearCount` (số lần mặc) và `wearHistory` (theo thời gian) để tính cost-per-wear và xu hướng.
**Fallback (nếu API thiếu)**: ẩn cost-per-wear và biểu đồ xu hướng kèm thông báo rõ ràng; chỉ hiển thị nhóm (a)+(b phần giá trị)+(c). Không hiển thị số bịa.
**Alternatives**: Mobile tự suy diễn wear count từ `lastWornDaysAgo` — bị loại vì sai bản chất, dễ gây hiểu nhầm.

## R3 — Tính chỉ số: server hay client

**Decision**: Ưu tiên server cung cấp aggregate (theo pattern insights hiện có). Mobile chỉ tính cost-per-wear nếu API trả đủ `purchasePrice` + `wearCount`; công thức `price / wearCount`, món `wearCount == 0` → nhãn "Chưa mặc" (không chia 0).
**Rationale**: Nhất quán với kiến trúc hiện tại (số liệu lấy từ dashboard API), tránh tải toàn bộ list để tính.
**Alternatives**: Tính toàn bộ client từ list phân trang — bị loại (N+1, sai khi dữ liệu lớn).

## R4 — Biểu đồ xu hướng

**Decision**: Dùng `CustomPainter` tự viết (`shared/widgets/stats_bar_chart.dart`) cho bar chart theo tháng; không thêm package.
**Rationale**: Repo không có chart lib; tránh thêm dependency runtime (rủi ro build/Play, giữ gotcha "no new deps").
**Alternatives**: `fl_chart` — bị loại vì thêm dep; `LinearProgressIndicator` — không đủ trực quan cho xu hướng.

## R5 — State management

**Decision**: `FutureProvider.autoDispose` mới (`wardrobeStatsProvider`) + method repository additive; giữ pattern `wardrobeInsightsProvider`. Làm mới bằng `ref.invalidate`.
**Rationale**: Khớp pattern hiện có; autoDispose tránh giữ dữ liệu khi rời màn.
**Alternatives**: StateNotifier — thừa vì chỉ đọc dữ liệu một chiều.

## R6 — Trạng thái rỗng/lỗi/loading

**Decision**: Bắt chước `WardrobeInsightsScreen`: `AsyncValue.when` (data/loading/error) + `RefreshIndicator` + nút "Thử lại"; thêm trạng thái rỗng riêng cho từng section.
**Rationale**: Nhất quán UX; đáp ứng FR-008/SC-003/SC-005.

## R7 — Theme & khả năng đọc

**Decision**: Dùng `AppColors`, `GoogleFonts.playfairDisplay`/`beVietnamPro`; kiểm tra tương phản ở `values-night` (sáng/tối). Nội dung tiếng Việt.
**Rationale**: FR-011/SC-006; giữ Quiet Luxury.

## R8 — Thống kê outfit

**Decision**: Tái dùng dữ liệu outfit sẵn có (`/me/outfits` hoặc trường trong dashboard nếu có); chỉ hiển thị số lượng/phân bố cơ bản, không tải toàn bộ nếu API có aggregate.
**Rationale**: Tránh gọi list lớn; đáp ứng FR-006.

## R9 — Định nghĩa chỉ số (chuẩn hoá)

**Decision**:
- "Món ít mặc": `lastWornDaysAgo >= 30/60/90` theo mốc.
- "Tỷ lệ sử dụng": `(totalItems - underutilizedItemsCount) / totalItems` (mốc 30 ngày), hiển thị %.
- "Cost-per-wear": `purchasePriceVnd / wearCount`, món chưa mặc → "Chưa mặc".
- "Xu hướng": số lần mặc (hoặc số món được mặc) gom theo tháng, 6 tháng gần nhất.
**Rationale**: Thống nhất công thức để testable (SC-002/SC-004); tránh mơ hồ.

## R10 — Phạm vi loại trừ

**Decision**: Không hiển thị chi tiêu ví/gói hội viên (spec 008 đang ẩn luồng trả phí). Ngoài phạm vi v1.
**Rationale**: FR-013; tránh phụ thuộc tính năng đang ẩn.

## T001 — Kết quả xác minh API (thực hiện khi implement, ngày 2026-09-19)

**Xác minh trên repo backend** (`smart-wardrobe-be`, không cần server chạy):

- `GET /me/dashboard/wardrobe-insights` trả `UserWardrobeInsightsRes` (`user_dashboard_dto.go`): `totalItems`, `totalWardrobeValueVnd`, `underutilizedItemsCount`, `underutilizedItems[]` (`itemId`, `name`, `categoryName`, `purchasePriceVnd`, `lastWornDaysAgo`, `imageUrl`), `expiringVouchersCount`. **Không có** `wearCount`/`costPerWearVnd` ở DTO user-facing.
- `GET /me/dashboard/wardrobe/category-distribution` trả `totalItems` + `categories[]` (`categoryId`, `categoryName`, `itemCount`, `percentage`).
- **Không có** endpoint lịch sử mặc theo thời gian cho user; không có `/me/dashboard/wardrobe-statistics`.
- Quan trọng: `UnderutilizedItemInfoDTO` nội bộ (`wardrobe/.../dashboard_dto.go`) có `WearCount`/`CostPerWearVND`, nhưng ở `item_uc_read.go:432-433` backend đang **hardcode `wearCount := 0`** (dùng `item.LastUsedAt` chỉ để tính `lastWornDaysAgo`). Không có tracking số lần mặc thật.
- Outfit: danh sách qua `/me/outfits` (đếm được từ list/pagination); không có aggregate "đã dùng".

**Kết luận fallback (theo FR-014, đã được duyệt)**:
- Hiển thị: tổng món, tỷ lệ sử dụng, món ít mặc 30/60/90, tổng giá trị, giá trị theo danh mục, thống kê outfit đã lưu.
- Ẩn kèm ghi chú rõ ràng: cost-per-wear (không có `wearCount` thật) và biểu đồ xu hướng theo tháng (không có endpoint lịch sử). Không hiển thị số ước lượng.
- Ghi chú cho backend (ngoài phạm vi mobile v1): muốn bật 2 chỉ số trên cần tracking số lần mặc + endpoint lịch sử.
