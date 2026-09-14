# Quickstart — Validate 006-home-stats-infinite-scroll

**Prereqs**: app on emulator, backend running, tài khoản A có 35 món + 60 outfit.

## QS-001 — Home trùng số Thống kê (US1)

1. Mở Home ghi số (tổng món, outfit, giá trị tủ) → mở Thống kê tủ đồ → so sánh.
2. ✅ Pass: trùng 100% sau refresh; thêm 1 món → refresh cả hai → cùng tăng.
3. Bật máy bay → mở Home → ✅ phần số liệu hiện lỗi + Thử lại (không hiện số thiếu); banner/lời chào vẫn hiện.

## QS-002 — Wardrobe infinite scroll (US2)

1. Tài khoản 35 món → kéo tới gần cuối → ✅ 15 món nối tiếp + spinner; hết thì dừng.
2. Đổi category → ✅ về trang đầu, không lẫn món cũ. Kéo refresh → ✅ reset.
3. Mất mạng giữa load-more → ✅ giữ list + vị trí cuộn, báo nhẹ, kéo tiếp thử lại được.
4. Kéo nhanh 5 lần tới cuối → ✅ 1 request (xem log mạng), 0 trùng id.

## QS-003 — Outfit infinite scroll (US3)

1. 60 outfit → kéo cuối trang 1 → ✅ 10 outfit còn lại hiện ra; hết thì dừng.
2. Tick chọn 2 outfit → kéo tải thêm → ✅ giữ tick, món mới không tự tick.

## QS-004 — Hồi quy

- `flutter analyze` sạch; test suite như baseline; lọc/pull-refresh/xóa đơn/bulk/mở detail đúng như cũ.
