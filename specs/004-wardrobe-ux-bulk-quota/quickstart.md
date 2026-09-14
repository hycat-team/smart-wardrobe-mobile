# Quickstart — Validate 004-wardrobe-ux-bulk-quota

**Prereqs**: app runs on emulator (`flutter run`), test account with ≥ 6 wardrobe items + ≥ 3 outfits, backend running (system catalog endpoints exist and are FE-proven).

## QS-001 — Swipe-back không giật (US1)

1. Mở Wardrobe → tap 1 món → chờ detail load xong.
2. Vuốt từ cạnh trái sang phải (edge-swipe) để quay lại.
3. ✅ Pass khi: về list trong 1 chuyển động mượt, KHÔNG thấy khung detail nháy lại; vị trí cuộn giữ nguyên; thumbnail không đen.
4. Lặp lại 20 lần + thử khi ảnh đang zoom + double back (vuốt + nút mũi tên cùng lúc → chỉ pop 1 lần).
5. Nút mũi tên vẫn về list đúng như cũ.

## QS-002 — Xóa hàng loạt wardrobe items (US2a)

1. Wardrobe → vào chế độ chọn (icon chọn / long-press card) → tick 3 món → `Xóa (3)` → dialog hiện đúng số lượng → xác nhận.
2. ✅ Pass: 3 món biến mất, snackbar `Đã xóa 3 món`, total/insights cập nhật.
3. Hủy ở dialog → không món nào bị xóa.
4. Chọn món đang `AI xử lý` → dialog có dòng cảnh báo.
5. Bật chế độ máy bay → xóa → báo lỗi rõ, list không đổi, thử lại sau khi có mạng không bị trùng.

## QS-003 — Xóa hàng loạt outfits (US2b)

1. `Tủ Outfit Của Tôi` → chế độ chọn → tick 2 outfit → xác nhận xóa.
2. ✅ Pass: 2 outfit biến mất + snackbar; hủy thì không mất gì.
3. Giả lập 1 id xóa lỗi (mất mạng giữa chừng) → dialog liệt kê món thất bại + nút `Thử lại` chỉ retry món lỗi.

## QS-004 — Thêm đồ từ tủ hệ thống (US3)

1. Wardrobe → `Thêm` → `Từ tủ đồ hệ thống` → duyệt list mẫu (`GET /system-catalog/wardrobe-items`) + lọc theo danh mục + tìm kiếm → tap mẫu tick chọn 2 mẫu → `Thêm vào tủ đồ (2)` → xác nhận.
2. ✅ Pass: request `POST /wardrobe-items/catalog-init {catalogItemIds: [...]}` → 2 món mới hiện trong grid Wardrobe sau refresh + snackbar `Đã thêm 2 món`; mẫu đã có hiện `Đã có trong tủ`, không tick được.
3. Mất mạng giữa chừng → giữ selection, báo lỗi + thử lại, không trùng sau retry.
4. Tủ đầy (đạt max gói) → BE báo lỗi → app hiển thị hướng dẫn nâng cấp/xóa bớt.

## QS-005 — Đồng bộ hạn mức AI (US4)

1. Ghi lại 2 con số ở Hồ sơ cá nhân (vd `0/5 lượt` phối đồ, `0/3 lượt` stylist) → mở Gói Hội Viên & Hạn Mức → so sánh.
2. ✅ Pass: trùng số + trùng định dạng `x/y lượt` + cùng dòng reset 00:00 ở cả hai trang.
3. Dùng 1 lượt AI → làm mới cả hai trang → cùng lên `1/5 lượt`.
4. Bật máy bay + mở cả hai trang → cả hai hiện trạng thái tải lại (KHÔNG hiện `0/5` giả).

## QS-006 — Hồi quy (không vỡ cái cũ)

- `flutter analyze` sạch lỗi mới; upload camera/gallery + SSE optimistic flow còn đúng; xóa đơn từng món/outfit còn đúng; mua Premium flow không đổi.
