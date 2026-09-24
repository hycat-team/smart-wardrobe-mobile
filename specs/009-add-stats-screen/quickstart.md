# Quickstart — Validate 009-add-stats-screen

**Prereqs**: app chạy trên emulator/máy thật, backend đang chạy, tài khoản test có dữ liệu (món + giá mua + lịch sử mặc nếu có). Đối chiếu `contracts/stats-data.md` và `data-model.md`.

## QS-000 — Xác minh API (FR-014, làm trước khi code)

1. Gọi thử endpoint dashboard (`/me/dashboard/wardrobe-statistics` hoặc mở rộng insights).
2. ✅ Ghi lại trường nào có: `totalItems`, `totalWardrobeValueVnd`, `lastWornDaysAgo`, `categories`, `outfits`, `wearCount`, `wearHistory`.
3. ✅ Nếu thiếu `wearCount`/`wearHistory`: xác nhận kế hoạch fallback (ẩn chỉ số) hoặc thống nhất bổ sung backend.

## QS-001 — Truy cập & tổng quan (US1, SC-001)

1. Vào Hồ sơ → mục "Thống kê chi tiết" → mở màn mới.
2. ✅ Màn mở, hiển thị tổng món + tỷ lệ sử dụng trong dưới 3 giây.

## QS-002 — Mức độ sử dụng 30/60/90 (US1, SC-002)

1. Đối chiếu số món ít mặc 30/60/90 với danh sách thực tế.
2. ✅ Số liệu khớp 100%; món ít mặc xem chi tiết được.

## QS-003 — Giá trị & cost-per-wear (US2, SC-004)

1. Đối chiếu tổng giá trị với tổng giá mua đã nhập.
2. Chọn vài món có giá + số lần mặc → tính thủ công `price / wearCount`.
3. ✅ Cost-per-wear khớp; món `wearCount == 0` hiển thị "Chưa mặc", không chia 0.

## QS-004 — Outfit & xu hướng (US3)

1. Xem phần outfit → đối chiếu số lượng với dữ liệu thực tế.
2. Xem biểu đồ xu hướng 6 tháng → đối chiếu dữ liệu mặc theo tháng.
3. ✅ Nếu chưa đủ dữ liệu: hiển thị "chưa đủ dữ liệu", không vẽ biểu đồ rỗng gây hiểu nhầm.

## QS-005 — Trạng thái & hồi quy (SC-003/005/006)

1. Tài khoản rỗng → ✅ trạng thái rỗng thân thiện.
2. Tắt mạng rồi mở/kéo làm mới → ✅ thông báo lỗi + nút "Thử lại", không màn trắng.
3. Đổi chế độ sáng/tối → ✅ đọc rõ.
4. Mở lại `/wardrobe/insights` cũ → ✅ vẫn hoạt động như trước.
5. `flutter analyze` sạch; `flutter test` như baseline.

## QS-006 — Ma trận tài khoản (SC-003)

Chạy màn Thống kê trên 5 loại tài khoản, mỗi loại mở + kéo làm mới 2 lần:
1. Rỗng (0 món) → ✅ trạng thái rỗng thân thiện.
2. Ít món (< 5) → ✅ số liệu hiển thị đúng, không lỗi.
3. Nhiều món (hàng trăm) → ✅ tải < 3 giây, cuộn mượt.
4. Thiếu giá mua → ✅ chú thích `missingPriceCount`, cost-per-wear không tính món thiếu giá.
5. Nhiều outfit → ✅ phần outfit hiển thị đúng, không lỗi.
- ✅ 5/5 tài khoản không crash, trạng thái phù hợp.

## QS-007 — Nhất quán & quyền riêng tư (FR-009/FR-012)

1. Đối chiếu tổng số món với Home quick stats và tổng giá trị với `/wardrobe/insights` trên cùng tài khoản/thời điểm.
2. ✅ Số liệu khớp (không mâu thuẫn).
3. ✅ Màn chỉ gọi API có xác thực; không hiển thị/log dữ liệu của người dùng khác.
