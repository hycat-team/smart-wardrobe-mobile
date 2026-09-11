# Quickstart: Fix Wallet Top-Up Flow

**Feature**: `003-fix-wallet-topup` | **Date**: 2026-09-11

Hướng dẫn kiểm thử thủ công trên emulator sau khi implement (ánh xạ 1-1 với Success Criteria trong spec).

## Chuẩn bị

1. Backend Go chạy tại `http://10.0.2.2:8080` (emulator map `API_BASE_URL_ANDROID`).
2. Emulator Android đang chạy: `flutter devices` thấy `emulator-5554`.
3. Đăng nhập tài khoản test (1 tài khoản Free, 1 tài khoản đã Premium).
4. Ghi lại số dư ví trước mỗi lượt test.

## Kịch bản kiểm thử

### QS-1. Thấy mã QR đúng số tiền (SC-001)
1. Vào Hồ sơ → Ví → Nạp tiền, chọn preset 100.000 đ → nhấn "Tạo Mã VietQR Thanh Toán".
2. **Mong đợi**: sang màn hình mới hiển thị mã QR + "100.000 đ" + mã đơn hàng; không mở trình duyệt ngoài, không sang màn hình chờ Premium.
3. Lặp với số tiền tự nhập `50.000` và `500000` → QR hiện đúng số tiền tương ứng.

### QS-2. Không báo thành công giả (SC-002)
1. Tạo lệnh nạp 50.000 đ nhưng **không chuyển tiền**, chờ 1 phút.
2. **Mong đợi**: vẫn "Đang chờ", không có màn hình thành công.
3. Tắt mạng 30s rồi bật lại → **mong đợi**: báo lỗi mạng + nút thử lại, không báo thành công.

### QS-3. Nạp thật → về ví đúng số dư (SC-003, SC-004)
1. Quét QR bằng app ngân hàng (sandbox/test) và chuyển đúng số tiền.
2. **Mong đợi**: trong ~10s màn hình báo nạp thành công với đúng số tiền; nhấn tiếp tục → về màn hình Ví, số dư tăng đúng 50.000 đ.
3. Lặp với tài khoản đã Premium → **mong đợi**: chỉ báo nạp ví thành công, không hiện "Chúc mừng Premium".

### QS-4. Hồi quy mua Premium (SC-005)
1. Tài khoản Free → mua gói Premium qua PayOS → thanh toán xong.
2. **Mong đợi**: vẫn về trang Gói Hội Viên & Hạn Mức như cũ; số tiền hiển thị đúng giá gói (không còn cứng 249.000 đ nếu giá khác).

### QS-5. Edge cases
- Nhập `5.000` → bị từ chối (tối thiểu 10.000 đ). Nhập `100.000` → preset 100k sáng đúng.
- Nhấn nút nạp 2 lần liên tiếp → chỉ 1 lệnh được tạo (kiểm tra 1 mã đơn hàng).
- Hết 15 phút không trả → hiện hết hạn + nút tạo lệnh mới.

## Lệnh chạy

```powershell
flutter analyze
flutter run -d emulator-5554 --debug
flutter test test/features/profile/wallet_topup_test.dart  # sau khi có test
```
