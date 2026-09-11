# Quickstart: Kiểm chứng Premium Payment Mobile

## Điều kiện
- Backend chạy (`http://localhost:8080`), đã seed gói `free` + `premium-monthly`.
- App mobile đã đăng nhập tài khoản test Free.
- PayOS ở chế độ sandbox (không quét tiền thật).

## Kịch bản 1 — Mua VietQR/PayOS (P1)
1. `flutter run` (hoặc `flutter run -d chrome --web-port=8081` cho web).
2. Vào Hồ sơ → Gói hội viên → Nâng cấp → bấm **Quét VietQR Trực Tiếp (PayOS)**.
3. Kỳ vọng: trình duyệt ngoài mở trang PayOS; app chuyển màn chờ hiện đúng mã đơn + số tiền gói (không phải giá trị cố định).
4. Hoàn tất thanh toán sandbox → quay lại app (deep link hoặc mở tay).
5. Kỳ vọng: chậm nhất sau 1 chu kỳ polling hiện màn chúc mừng; `GET /subscriptions/me` là Premium; hạn mức AI mới.

## Kịch bản 2 — Mua bằng ví (P1)
1. Nạp ví test đủ số dư → màn nâng cấp hiện nút ví khả dụng + đúng số dư.
2. Xác nhận mua → kỳ vọng: dialog thành công, ví trừ đúng giá gói, gói lên Premium.
3. Với ví thiếu tiền → kỳ vọng: mở bottom sheet nạp thay vì mua.

## Kịch bản 3 — Nạp ví (P2)
1. Nhập số tiền → xác nhận → mở PayOS → thanh toán sandbox.
2. Kỳ vọng: số dư + lịch sử giao dịch có bản ghi nạp sau khi quay lại.

## Kịch bản 4 — Chi tiết gói + tự động gia hạn (P2)
1. Mở chi tiết gói → thấy tên gói, hạn dùng, hạn mức AI.
2. Bật/tắt tự động gia hạn → tải lại màn hình → trạng thái giữ nguyên.

## Kịch bản 5 — Deep link (FR-009)
1. Khi app đang chạy: `adb shell am start -a android.intent.action.VIEW -d "smartwardrobe://subscription/success"` → kỳ vọng mở đúng màn kết quả gói (không tự coi là đã thanh toán nếu API vẫn Free).
2. Lặp lại với `.../cancel` và 2 link ví. Trên iOS dùng `xcrun simctl openurl booted "<link>"`.

## Kiểm tra chất lượng
- `flutter analyze` sạch lỗi mới.
- Mất mạng giữa polling: màn chờ không crash, thử lại chu kỳ sau.
- Nút back ở màn chờ: hiện dialog xác nhận rời đi.
