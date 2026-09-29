# Research: Kỹ thuật Pop-up Toast đỉnh màn hình trong Flutter

## 1. Cơ chế hiển thị Overlay vs ScaffoldMessenger

### Vấn đề hiện tại:
1. Thông báo lỗi hết lượt AI phối đồ trong Outfit Studio đang được viết cứng dưới dạng một `Container` màu đỏ tĩnh bên dưới nút "Tạo Set Đồ Với AI Ngay". Khi có lỗi, khối đỏ này xuất hiện làm đẩy toàn bộ danh sách kết quả hoặc Bottom Sheet xuống, gây vỡ bố cục và xấu giao diện.
2. Các thông báo khác trong app dùng `ScaffoldMessenger.of(context).showSnackBar()`. SnackBar mặc định dính chặt đáy màn hình, bị thanh Bottom Navigation Bar 5 tabs che khuất, hoặc che mất đôi giày / phụ kiện ở canvas.

### Quyết định kỹ thuật:
- **Sử dụng `OverlayEntry` chuyên biệt:**
  - `Overlay` được lồng tự nhiên trong `Navigator` của Flutter.
  - Vị trí hiển thị: `Positioned(top: safeAreaTop + 10, left: 16, right: 16)`.
  - Không phụ thuộc vào sự tồn tại hay trạng thái của `Scaffold`.
  - Hiển thị nổi lên trên mọi Dialog, Modal Bottom Sheet hoặc Canvas.

## 2. Animation & Timing (2 Giây Auto-Dismiss)

### Cơ chế:
- **Thời lượng:** 2000ms (`Duration(seconds: 2)`).
- **Animation vào:** `SlideTransition` từ `Offset(0, -1.0)` xuống `Offset(0, 0)` kết hợp `FadeTransition` từ 0.0 lên 1.0 trong 250ms (curve: `Curves.easeOutCubic`).
- **Thời gian giữ:** 2000ms.
- **Animation ra:** Slide ngược từ `Offset(0, 0)` lên `Offset(0, -0.8)` kết hợp `FadeTransition` về 0.0 trong 200ms (curve: `Curves.easeInCubic`).
- **Tương tác sớm:**
  - `GestureDetector(onTap: dismiss, onVerticalDragUpdate: (details) { if (details.primaryDelta < -5) dismiss(); })`.
  - Người dùng có thể vuốt lên hoặc chạm để tắt ngay lập tức mà không cần đợi đủ 2 giây.

## 3. Singleton Queue & Chống đè Toast

- Duy trì một `static OverlayEntry? _currentEntry` và `static AnimationController? _currentController`.
- Khi có thông báo mới trong lúc thông báo cũ chưa biến mất:
  - Thông báo cũ lập tức được loại bỏ an toàn mà không làm rách widget tree.
  - Thông báo mới xuất hiện mượt mà ngay tại đỉnh màn hình.

## 4. Bảng màu Quiet Luxury cho Toast

| Loại | Background | Border | Icon | Text |
|---|---|---|---|---|
| **Error / Hết lượt** | `#FFF7F7` (Kem phớt hồng) | `#F0D5D3` (Đỏ ngọc mờ) | `Icons.error_outline_rounded` (`#B44439`) | `#6E2822` |
| **Warning** | `#FFFDF5` (Vani ấm) | `#EDE0C8` (Vàng champagne) | `Icons.warning_amber_rounded` (`#A67C33`) | `#594119` |
| **Success** | `#F6FAF7` (Xanh sage sương) | `#D6E8DB` (Xanh mờ nhạt) | `Icons.check_circle_outline_rounded` (`#2E6F40`) | `#1E482B` |
| **Info** | `#FAF8F5` (Trắng ngà ấm) | `#E8E3DC` (Gỗ sáng) | `Icons.info_outline_rounded` (`#6B665E`) | `#2C2A29` |
