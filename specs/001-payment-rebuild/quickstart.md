# Quickstart: Payment Rebuild

**Feature**: `001-payment-rebuild` | **Date**: 2026-09-12

## Prerequisites

- Backend local chạy ở `http://localhost:8080/api/v1`, PayOS sandbox cấu hình webhook xong.
- App chạy `flutter run -d chrome --web-port=8081` (CORS đã allow) hoặc emulator Android (base URL `10.0.2.2`).
- Tài khoản test có ví 0đ và 1 tài khoản ví > giá gói Premium.

## Validate P1a — Nạp ví (FR-001→006, FR-009→010)

1. Vào `/profile/wallet` → bấm Nạp → chọn 100.000đ → Tạo mã VietQR.
2. Kỳ vọng: mở trang PayOS ngoài; sang `/profile/subscription/waiting` thấy đúng `#orderCode`, `100.000 đ`, nhãn Nạp ví.
3. Thanh toán sandbox xong → trong 2 phút số dư tăng 100.000đ, lịch sử có 1 dòng `+100.000 đ / Nạp tiền vào ví`.
4. Nhập 5.000đ → bị chặn với thông báo tối thiểu 10.000đ, không sang waiting.

## Validate P1b — Mua bằng ví (FR-007→008, FR-013)

1. Ví 100.000đ → `/profile/subscription/upgrade` → Mua bằng ví gói 59.000đ → xác nhận.
2. Kỳ vọng: dialog thành công, ví còn ~41.000đ, trạng thái Premium, lịch sử có dòng mua gói.
3. Ví 10.000đ → bấm mua bằng ví → không trừ tiền, được gợi ý nạp thêm + mở sẵn bottom sheet nạp.

## Validate P2 — Mua trực tiếp +waiting (FR-003→006, FR-011→012, FR-014)

1. Ví 0đ → chọn Quét VietQR trực tiếp → thanh toán sandbox.
2. Kỳ vọng: waiting hiện đúng giá gói + tên gói, tự nhảy success khi `isPremium == true`; nút mở lại PayOS hoạt động.
3. Bấm tạo link 2 lần liên tiếp → chỉ 1 lần mở browser (nút bị disable lúc tạo).
4. Hủy trên PayOS → waiting hiện đã hủy, số dư/gói không đổi. Rời waiting giữa chừng → có cảnh báo, quay lại vẫn tra được trạng thái.

## Regression

- `flutter analyze` sạch lỗi mới; lịch sử trống hiện empty-state; kéo làm mới ví cập nhật số dư + statements; hết hạn 15 phút hiện hết hạn + cho tạo mã mới.
