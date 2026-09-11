# Quickstart: Kiểm chứng User Outfits Tab

## Điều kiện
- Backend chạy, tài khoản test A có sẵn ≥ 2 outfits, tài khoản B mới (trống).

## Kịch bản 1 — Tab và thứ tự (P1)
1. Đăng nhập A → nhìn thanh dưới.
2. Kỳ vọng: 5 icon đúng thứ tự Home, Wardrobe, Stylist, Outfits, Profile.
3. Bấm Outfits → kỳ vọng: thấy lưới outfits của A + dòng tổng số; không có nút back trên AppBar.

## Kịch bản 2 — Chi tiết và hành động (P2)
1. Bấm 1 outfit → kỳ vọng: bottom sheet chi tiết đủ món trong set.
2. Mở trên Studio → kỳ vọng: set nạp lên canvas (chuyển sang tab Studio).
3. Xóa 1 outfit (xác nhận) → kỳ vọng: biến khỏi lưới + SnackBar thành công.

## Kịch bản 3 — Trống và lỗi
1. Đăng nhập B (trống) → tab Outfits → kỳ vọng: empty state + nút Tạo Outfit Ngay sang Studio.
2. Tắt mạng → mở tab → kỳ vọng: lỗi thân thiện + nút Thử lại.

## Kịch bản 4 — Không rò rỉ liên tài khoản
1. Đăng nhập A → mở tab Outfits (thấy đồ A) → đăng xuất → đăng nhập B.
2. Kỳ vọng: tab Outfits của B trống, không hiện đồ A.

## Kiểm tra chất lượng
- `flutter analyze` sạch lỗi mới.
- Bấm lại tab đang chọn → về đầu trang tab đó (hành vi `initialLocation` giữ nguyên).
- Route `/outfits` cũ từ Studio vẫn mở được như trước.
