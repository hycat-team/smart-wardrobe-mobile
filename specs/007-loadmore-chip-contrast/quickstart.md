# Quickstart — Validate 007-loadmore-chip-contrast

**Prereqs**: app on emulator, backend running, tài khoản 35 món + 60 outfit. Mở log mạng (Dart DevTools Network hoặc BE access log) để đối chiếu số request.

## QS-001 — Wardrobe tải đủ 35 món (US1)

1. Kéo tới gần cuối → ✅ món mới nối tiếp, đếm tăng; lặp tới hết → dừng, không spinner.
2. ✅ Pass: đủ 35/35 trong 3 lượt tải (20+15, hoặc +1 probe rỗng nếu tổng là bội số); kéo nhanh 5 lần → 0 request trùng.
3. Nếu BE bỏ qua `page` (mọi trang trùng): ✅ dừng sau tối đa 2 probe, không spinner vô hạn, list giữ nguyên.

## QS-002 — Outfit tải đủ 60 bộ (US1)

1. Kéo cuối trang 1 → ✅ 10 bộ còn lại hiện ra; hết thì dừng.

## QS-003 — Chip trắng khi chọn (US2)

1. Nhấn từng chip (Tất cả/Áo/Quần/...) → ✅ chip chọn: nền đậm + chữ trắng + tick trắng; chip nghỉ: nền nhạt + chữ/icon màu chủ đạo; rõ ở cả sáng/tối.

## QS-004 — Hồi quy 006

- SC-002→SC-006 của 006 vẫn đạt; `flutter analyze` sạch; test suite như baseline.
