# UI Contract: Web Handoff (Phase 1)

**Feature**: `009-web-payment-redirect` | **Date**: 2026-09-24

Mobile không phơi API/service mới ra ngoài. Contract này là hợp đồng giao diện nội bộ mà mọi màn hình gói/ví phải tuân thủ sau đổi luồng. Kiểm chứng bằng `quickstart.md`.

## 1. Package display surface (màn hình gói / nâng cấp)

- PHẢI hiển thị: danh sách gói `isActive` với tên, giá VNĐ (`formattedPrice`), thời hạn ngày, quyền lợi/so sánh.
- PHẢI KHÔNG có: nút tạo thanh toán, nút mua bằng ví, nút mở QR/checkout, `launchUrl`, WebView, điều hướng tới `PaymentWaitingScreen` / `PaymentResultScreen`.
- Khi chọn gói trả phí → hiển thị `WebGuidanceCard` (xem mục 3), không gọi `createDirectPurchase`.

## 2. Wallet surface (thẻ ví + màn hình ví chi tiết)

- PHẢI hiển thị: số dư (`formattedBalance`), lịch sử (`typeLabel`, `description`, `createdAt`, `formattedAmount`), trạng thái loading/lỗi tiếng Việt + thử lại.
- PHẢI KHÔNG có: form nhập số tiền, `TopUpBottomSheet`, nút nạp/mua, gọi `createWalletTopUp` / `purchasePlanWithWallet`.
- Nhu cầu nạp → hiển thị `WebGuidanceCard` (mục 3).

## 3. WebGuidanceCard (nội dung bắt buộc, văn bản thuần túy)

- Tiêu đề: nêu tiếp tục thanh toán/nạp trên website.
- Thân card:
  1. `websiteHostText`: địa chỉ website đầy đủ ở dạng văn bản (KHÔNG phải nút/link, không tham số gói/tiền/user).
  2. Bước 1: tự mở trình duyệt ngoài app và nhập địa chỉ trên.
  3. Bước 2: đăng nhập website bằng CÙNG tài khoản mobile (cùng email/số điện thoại).
  4. Bước 3: hoàn tất mua gói / nạp ví trên web rồi quay lại app; trạng thái tự cập nhật.
- Cấm: mọi `onTap` mở URL, sao chép tự động, QR, deep-link có tham số.

## 4. Refresh contract (đồng bộ sau thanh toán web)

- Trigger bắt buộc: app resume từ nền và mở lại màn hình gói/ví → tải lại subscription (+quota) và wallet (+statements) qua các provider hiện có.
- Khi giao dịch web chưa xong: giữ trạng thái cũ + gợi ý kiểm tra lại sau; không hiển thị thành công giả.
- Link/màn hình chờ cũ (`PendingPayment`, waiting/result): không mở; hiển thị thông báo hết hiệu lực + `WebGuidanceCard`.

## 5. Backend usage (mobile ngừng gọi)

- Mobile NGƯNG gọi: `POST /subscriptions/me/purchase`, `POST /subscriptions/me/wallet/topup`, `POST /subscriptions/me/purchase-with-wallet` và mọi đường mở `paymentUrl` qua `payment_link_opener`.
- Mobile TIẾP TỤC gọi (chỉ đọc): `GET /subscriptions/plans`, `GET /subscriptions/me`, `GET /subscriptions/me/daily-quota`, `GET /subscriptions/me/wallet`, `GET /subscriptions/me/wallet/statements`.
- Backend/website không thay đổi trong phạm vi này.
