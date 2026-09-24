# Implementation Plan: Statistics Screen

**Branch**: `009-add-stats-screen` | **Date**: 2026-09-19 | **Spec**: specs/009-add-stats-screen/spec.md

**Input**: Feature specification from `/specs/009-add-stats-screen/spec.md`

## Summary

Thêm một màn Thống kê MỚI (route riêng, bổ sung cho `/wardrobe/insights` hiện có) truy cập từ trang Hồ sơ, gồm 4 nhóm chỉ số: (a) mức độ sử dụng 30/60/90 ngày, (b) giá trị & cost-per-wear, (c) outfit, (d) xu hướng theo tháng 6 tháng gần nhất. Dùng Riverpod `FutureProvider.autoDispose` + repository hiện có (mở rộng `/me/dashboard/...`). Vẽ biểu đồ bằng widget tự viết (CustomPainter) để không thêm dependency runtime. Vì máy chủ hiện chỉ trả `lastWornDaysAgo` (không có số lần mặc/lịch sử), FR-014 bắt buộc có bước xác minh API trước khi code cost-per-wear/xu hướng. Xem `research.md`, `data-model.md`, `contracts/stats-data.md`, `quickstart.md`.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x

**Primary Dependencies**: flutter_riverpod 2.5 (FutureProvider), go_router 14, dio 5, google_fonts, shared `ClosyNetworkImage`; biểu đồ dùng `CustomPainter` (không thêm package)

**Storage**: N/A (dữ liệu từ backend; không lưu cục bộ ngoài cache phiên)

**Testing**: `flutter analyze` sạch + `flutter test` baseline; manual QS-001→005 với tài khoản test; đối chiếu số liệu thủ công

**Target Platform**: Android (và các nền tảng Flutter hiện có); màn mới là widget Flutter thuần

**Project Type**: mobile-app (single Flutter project)

**Performance Goals**: tải số liệu và hiển thị dưới 3 giây với tài khoản hàng trăm món (mạng ổn định); cuộn mượt, không giật

**Constraints**: Không đổi màn `/wardrobe/insights` hiện có; không thêm dependency runtime; không phá luồng điều hướng hiện tại; chỉ hiển thị dữ liệu của chính người dùng; chi tiêu ví/gói ngoài phạm vi

**Scale/Scope**: 1 màn mới + 1 nhóm model/provider/repository method + route + 1 entry menu; 3 story; mobile-only

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` vẫn là template placeholder → không có gate chính thức.

Gotcha/compliance tự áp:
- Không thêm dependency runtime (biểu đồ tự vẽ) → tránh rủi ro build/Play.
- Mở rộng repository/provider theo kiểu additive; không đổi chữ ký provider cũ.
- Không đụng auth/network core; dùng `ApiClient`/`dio` sẵn có.
- Tôn trọng design tokens Quiet Luxury (`AppColors`, `GoogleFonts`), hỗ trợ sáng/tối.
- FR-014: xác minh API trước khi hứa cost-per-wear/xu hướng; nếu thiếu thì ẩn chỉ số kèm thông báo, không bịa số.

Post-design re-check: thiết kế chỉ thêm file mới + sửa additive (router, profile menu, repository) → passes. Không cần Complexity Tracking.

## Project Structure

### Documentation (this feature)

```text
specs/009-add-stats-screen/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── stats-data.md
└── tasks.md             # Phase 2 output (NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
lib/
├── core/router/app_router.dart                         # thêm GoRoute /wardrobe/statistics
├── features/profile/presentation/profile_screen.dart   # thêm _buildMenuTile "Thống kê chi tiết"
├── features/wardrobe/
│   ├── data/wardrobe_repository.dart                   # thêm getWardrobeStatistics() (additive)
│   ├── models/wardrobe_stats_models.dart               # (mới) model 4 nhóm chỉ số
│   ├── providers/wardrobe_stats_provider.dart          # (mới) FutureProvider.autoDispose
│   └── presentation/wardrobe_statistics_screen.dart    # (mới) màn Thống kê
└── shared/widgets/
    └── stats_bar_chart.dart                            # (mới) bar chart CustomPainter tái sử dụng
```

**Structure Decision**: Giữ trong feature `wardrobe` (cùng domain tủ đồ) và tái sử dụng hạ tầng sẵn có; biểu đồ đặt ở `shared/widgets` để tái dùng. Không tạo module mới.

## Phases (for /speckit-tasks)

- **Phase A (P1 — US1)**: Nền tảng & nhóm mức độ sử dụng.
  - A0 (FR-014): Xác minh API `/me/dashboard/...` — trường nào có sẵn (tổng món, `lastWornDaysAgo`, số lần mặc, lịch sử); ghi kết quả vào `research.md`/contract; quyết định ẩn hay bổ sung backend.
  - A1: Model `wardrobe_stats_models.dart` + method `getWardrobeStatistics()` + provider.
  - A2: Màn `wardrobe_statistics_screen.dart` với tổng món, tỷ lệ sử dụng, món ít mặc 30/60/90 ngày; empty/error/refresh.
  - A3: Route `/wardrobe/statistics` + entry ở Hồ sơ.
- **Phase B (P2 — US2)**: Giá trị & cost-per-wear (phụ thuộc A0).
  - B1: Tổng giá trị, giá trị theo danh mục (tái dùng dữ liệu phân bổ sẵn có).
  - B2: Cost-per-wear với xử lý món chưa mặc/thiếu giá; nếu API thiếu dữ liệu → ẩn + thông báo.
- **Phase C (P3 — US3)**: Outfit & xu hướng.
  - C1: Thống kê outfit (tái dùng `/me/outfits` hoặc dashboard).
  - C2: Biểu đồ xu hướng theo tháng 6 tháng (`stats_bar_chart.dart`); trạng thái "chưa đủ dữ liệu".
- **Phase D**: Polish & hồi quy.
  - D1: `flutter analyze`/`flutter test`; kiểm tra sáng/tối; hiệu năng tài khoản nhiều món.
  - D2: Xác nhận màn insights cũ không hồi quy; chạy quickstart.

## Complexity Tracking

> Không có vi phạm constitution — không cần justify.
