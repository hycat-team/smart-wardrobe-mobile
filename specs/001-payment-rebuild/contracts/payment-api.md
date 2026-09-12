# Contracts: Payment Rebuild

**Feature**: `001-payment-rebuild` | **Date**: 2026-09-12

Mobile không phát hành API mới; đây là hợp đồng mobile ↔ backend hiện có mà rebuild phải tuân thủ. Base URL theo `AppConstants.baseUrl` (`http://localhost:8080/api/v1`, Android emulator `http://10.0.2.2:8080/api/v1`), auth Bearer, header `Accept-Encoding: identity` (non-web).

## 1. POST /subscriptions/me/wallet/topup — tạo mã nạp ví

- Request: `{ "amount": 100000, "returnUrl": "smartwardrobe://wallet/topup/success", "cancelUrl": "smartwardrobe://wallet/topup/cancel" }` (web dùng `${origin}/profile...`). `amount >= 10000`.
- Response `data`: `{ "paymentUrl": "<checkout>", "orderCode": 123456, "paymentStatus": 0, "expiresAt": "<iso>?", "amount": 100000 }`.
- Lỗi: `400` số tiền không hợp lệ → hiện message backend, không điều hướng waiting.

## 2. POST /subscriptions/me/purchase — mua gói trực tiếp

- Request: `{ "planSlug": "premium-monthly", "returnUrl": "smartwardrobe://subscription/success", "cancelUrl": "smartwardrobe://subscription/cancel" }`.
- Response `data`: `PaymentLink` như trên (amount = giá gói).
- Caller phải dựng `PendingPayment(kind: directPurchase, label: "<plan.name> (<duration> ngày)")`.

## 3. POST /subscriptions/me/purchase-with-wallet — mua bằng ví (sync)

- Request: `{ "planSlug": "premium-monthly" }`. Không tạo link, không qua PayOS.
- Thành công: refresh `GET /subscriptions/me` + `GET /subscriptions/me/wallet` + invalidate statements; hiện dialog thành công.
- Lỗi `400` số dư không đủ → mở `TopUpBottomSheet`, không trừ tiền.

## 4. GET /subscriptions/me/wallet + /wallet/statements + /subscriptions/me + /subscriptions/plans (poll & hiển thị)

- `GET /subscriptions/me/wallet` → `{ "userId, balance, currency, updatedAt" }`. Dùng snapshot trước/sau để xác nhận nạp ví.
- `GET /subscriptions/me/wallet/statements?page=1&pageSize=20` → `{ items: [...] }` (fallback `data: []` khi backend trả list trần). Dùng cho lịch sử + đối soát.
- `GET /subscriptions/me` → subscription (`isPremium` khi mua trực tiếp xong). `GET /subscriptions/plans` → danh mục gói (không hardcode giá).

## 5. Điều hướng (GoRouter, giữ route, đổi extra)

- Giữ: `/profile/wallet`, `/profile/subscription`, `/profile/subscription/upgrade`, `/profile/subscription/waiting`.
- Đổi: `/profile/subscription/waiting` nhận `extra: PendingPayment` (thay vì `PaymentLinkModel` trần); `extra == null` → fallback về upgrade. Hiển thị waiting từ `PendingPayment.amount/label/orderCode`, không dùng fallback `249.000đ`.
- Return deep-link: `smartwardrobe://wallet/topup/*`, `smartwardrobe://subscription/*` → về màn hình tương ứng và trigger refresh (cần `app_links` + config native).
