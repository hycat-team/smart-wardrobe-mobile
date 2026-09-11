# Contracts: Backend API cho Premium Payment Mobile

Base: `http://localhost:8080/api/v1` — Auth: `Authorization: Bearer <JWT>` (SSE/d IP redirect dùng `?token=`).

## 1. Danh sách gói — `GET /subscriptions/plans`

- Response `data[]`: `slug | planSlug`, `name`, `price`, `durationDays`, `maxWardrobeItems`, `maxOutfits`, `aiOutfitDailyQuota`, `aiChatDailyQuota`, `features[]`.
- Lưu ý: backend trả key hoa/thường lẫn lộn (`planSlug`/`PlanSlug`) — client parse chịu lỗi cả hai dạng (đã có trong model).

## 2. Gói của tôi — `GET /subscriptions/me`

- Response `data`: `planSlug`, `planName`, `status`, `expiresAt`, `isAutoRenewEnabled` (+ biến thể hoa).
- Dùng cho: màn chi tiết gói, polling màn chờ (chu kỳ 3s), xác nhận thanh toán (`isPremium`).

## 3. Hạn mức ngày — `GET /subscriptions/me/daily-quota`

- Response `data`: `aiUsageCount`/`outfitRecommendCount` (đã dùng), `aiChatDailyQuota`/`aiOutfitDailyQuota` (giới hạn), `lastResetDate`.
- Làm mới cùng `GET /subscriptions/me` sau mỗi thanh toán.

## 4. Mua trực tiếp (VietQR/PayOS) — `POST /subscriptions/me/purchase`

- Request: `{ "planSlug": "premium-monthly", "returnUrl": "smartwardrobe://subscription/success", "cancelUrl": "smartwardrobe://subscription/cancel" }`
  (web: `returnUrl`/`cancelUrl` = origin; vắng mặt thì backend dùng config mặc định).
- Response `data`: `{ "paymentUrl" | "checkoutUrl", "paymentLinkId?", "orderCode?", "paymentStatus?" }`.
- Client mở `paymentUrl` bằng trình duyệt ngoài rồi vào màn chờ.

## 5. Mua bằng ví — `POST /subscriptions/me/purchase-with-wallet`

- Request: `{ "planSlug": "premium-monthly" }`.
- Response: boolean + message. Sau thành công: gọi lại contract 2 + 3 + ví.

## 6. Nạp ví — `POST /subscriptions/me/wallet/topup`

- Request: `{ "amount": 50000, "returnUrl": "smartwardrobe://wallet/topup/success", "cancelUrl": "smartwardrobe://wallet/topup/cancel" }`.
- Response `data`: như contract 4. Mở PayOS ngoài app; quay lại thì gọi lại ví + lịch sử.

## 7. Ví + lịch sử — `GET /subscriptions/me/wallet`, `GET /subscriptions/me/wallet/statements?page=&pageSize=`

## 8. Tự động gia hạn — `PUT /subscriptions/me/auto-renew`

- Request: `{ "enabled": true | false }`. Response boolean. Toggle trong chi tiết gói, tải lại giữ trạng thái.

## 9. Deep link (client-side, không phải API)

- `smartwardrobe://subscription/success` | `.../cancel` → màn chờ/kết quả gói.
- `smartwardrobe://wallet/topup/success` | `.../cancel` → màn ví/lịch sử.
- Query param từ PayOS chỉ dùng để điều hướng; mọi công nhận thành công qua contract 2.
