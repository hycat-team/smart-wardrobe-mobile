# Data Model: Premium Payment Mobile

**Feature**: `001-premium-payment-mobile` | **Source**: spec Key Entities + model Dart hiện có (`lib/features/profile/models/user_profile_models.dart`)

## Entities (dùng lại model hiện có, không tạo bảng mới)

### SubscriptionPlan
Gói hội viên bán trên màn hình nâng cấp.
- Khóa: `slug` (`free`, `premium-monthly`, ...).
- Thuộc tính: `name`, `price` (VNĐ, số), `durationDays`, `maxWardrobeItems`, `maxOutfits`, `aiOutfitDailyQuota`, `aiChatDailyQuota`, `features[]`, `isActive`.
- Nguồn: `GET /subscriptions/plans`. Giá trị ghi cứng trong app chỉ là dự phòng khi API lỗi.
- Quy tắc: `price == 0` là gói Free (ẩn nút mua); gói đang dùng (trùng slug) ẩn nút mua, hiện trạng thái Premium.

### UserSubscription
Gói đang dùng của user.
- Thuộc tính: `planSlug`, `planName`, `status` (`ACTIVE`), `expiresAt`, `isAutoRenewEnabled`, hạn mức đi kèm gói.
- Dẫn xuất: `isPremium = planSlug != 'free' && status == 'ACTIVE'` — là điều kiện duy nhất để mở khóa UI Premium và công nhận thanh toán thành công.
- Nguồn: `GET /subscriptions/me`.

### DailyQuota
Hạn mức AI còn lại trong ngày.
- Thuộc tính: lượt chat đã dùng/giới hạn, lượt phối đồ đã dùng/giới hạn, ngày reset.
- Nguồn: `GET /subscriptions/me/daily-quota`. Làm mới cùng lúc với subscription sau mỗi lần thanh toán.

### PaymentLink
Link thanh toán PayOS cho một đơn.
- Thuộc tính: `paymentUrl` (mở trình duyệt ngoài), `orderCode` (hiển thị + đối soát), `paymentStatus`.
- Vòng đời: tạo qua purchase/topup → `activePaymentLink` trong provider → xóa sau khi thành công/hủy/rời màn hình.
- Không tin trạng thái từ deep link; chỉ dùng deep link để điều hướng, xác thực qua `UserSubscription.isPremium`.

### Wallet
Ví nội bộ Closy.
- Thuộc tính: `balance`, lịch sử `TOPUP`/`PAYMENT`/`REFUND` (mô tả, số dư trước/sau, thời gian).
- Quy tắc: mua bằng ví chỉ thực hiện khi `balance >= price`; sau mua thành công nạp lại ví + subscription.

## State transitions

- `Free/ACTIVE` --(VietQR thành công)--> `Premium/ACTIVE` (+ `expiresAt` mới).
- `Free/ACTIVE` --(mua bằng ví thành công)--> `Premium/ACTIVE` (+ ví trừ đúng `price`).
- `Premium/ACTIVE` --(hết hạn, theo backend)--> `Free/ACTIVE`.
- `isAutoRenewEnabled`: `false` <-> `true` qua toggle, persisted server-side.
