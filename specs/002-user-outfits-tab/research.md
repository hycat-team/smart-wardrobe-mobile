# Research: User Outfits Tab

**Feature**: `002-user-outfits-tab` | **Date**: 2026-09-11

## R-01: Tái dùng màn hình hay viết mới

- **Decision**: Tái dùng nguyên `OutfitsListScreen` + `outfitsListProvider` + `OutfitRepository` hiện có; chỉ thêm nhánh shell + tab.
- **Rationale**: Màn hiện tại đã đủ mọi hành vi spec yêu cầu (lưới 2 cột, tổng số, chi tiết bottom sheet, mở Studio, xóa xác nhận, pull-to-refresh, empty state). Viết mới là trùng lặp và gây lệch hành vi.
- **Alternatives considered**: Viết trang mới gọn nhẹ — loại vì mất tính năng chi tiết/xóa đã kiểm chứng.

## R-02: Đường route cho tab

- **Decision**: Nhánh shell mới path `/my-outfits` render `OutfitsListScreen`; giữ nguyên route顶层 `/outfits` cho các luồng push từ Studio/Stylist.
- **Rationale**: Hai path khác nhau nên GoRouter không xung đột; các `context.push('/outfits')` trong Studio/Stylist giữ nguyên không phải sửa.
- **Alternatives considered**: Chuyển `/outfits` vào shell và redirect — phải sửa 4 điểm push (`outfit_studio_screen.dart` x3, `stylist_screen.dart` x1), rủi ro cao hơn, loại.

## R-03: Nút back trong ngữ cảnh tab

- **Decision**: Thêm cờ `showBackButton` (mặc định `true`) cho `OutfitsListScreen`; nhánh shell truyền `false` để ẩn nút back (tab không có khái niệm back).
- **Rationale**: Trong shell, `Navigator.canPop()` luôn false nên nút back hiện tại sẽ nhảy sang `/studio` — gây nhầm lẫn khi đang ở tab Outfits.
- **Alternatives considered**: Giữ nguyên nút back — loại vì UX sai (tab bar đã là điều hướng chính).

## R-04: Thứ tự tab và index

- **Decision**: Thêm item giữa Stylist và Profile: Home(0), Wardrobe(1), Stylist(2), Outfits(3), Profile(4); thêm `StatefulShellBranch(/my-outfits)` giữa nhánh stylist và profile trong `app_router.dart`.
- **Rationale**: Khớp yêu cầu "icon ở giữa stylist và profile"; index trong `ScaffoldWithNavBar` và thứ tự branches phải đồng bộ tuyệt đối (đi theo index).
- **Alternatives considered**: Không có.

## R-05: Icon và nhãn tab

- **Decision**: Icon `Icons.style_outlined` / `Icons.style_rounded`, nhãn `Outfits`.
- **Rationale**: Đồng bộ kiểu outline→rounded với 4 tab hiện tại; `checkroom` đã dùng cho Wardrobe nên chọn `style` để phân biệt.
- **Alternatives considered**: `checkroom` — trùng Wardrobe, loại.

## R-06: Rò rỉ liên tài khoản

- **Decision**: Không cần xử lý riêng — cơ chế reset `ProviderScope` theo session (đã triển khai) bao phủ `outfitsListProvider`; tab mới nằm trong scope bị dispose khi đổi tài khoản.
- **Rationale**: Đã kiểm chứng ở feature session-reset; provider outfits là StateNotifierProvider không autoDispose nên được reset cùng scope.
