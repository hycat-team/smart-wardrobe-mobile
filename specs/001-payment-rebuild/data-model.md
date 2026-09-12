# Data Model: Payment Rebuild

**Feature**: `001-payment-rebuild` | **Date**: 2026-09-12

Nguồn hiện tại: `lib/features/profile/models/user_profile_models.dart` (giữ nguyên field, chỉ thêm wrapper điều hướng).

## 1. PendingPayment (mới, client-only)

Wrapper khắc phục hardcode ở waiting screen. Mọi luồng tạo link PHẢI dựng object này.

- `orderCode: int` — mã đơn duy nhất từ backend, dùng để hiển thị + tra cứu.
- `paymentUrl: String` — checkout URL PayOS, bắt buộc non-empty mới cho mở browser.
- `amount: double` — số tiền đúng của giao dịch (>= 10.000). Waiting screen hiển thị từ đây, không hardcode.
- `kind: PaymentKind` — `walletTopUp | directPurchase`. Quyết định poll ví hay poll subscription.
- `label: String` — nhãn hiển thị, ví dụ `Nạp ví Closy Pay` / `Premium (30 ngày)`.
- `createdAt: DateTime` — để tính thời gian đã chờ + hết hạn 15 phút.
- Quy tắc: `kind == walletTopUp` thì success = `wallet.balance` tăng >= amount so với snapshot trước khi tạo; `kind == directPurchase` thì success = `subscription.isPremium == true`.

## 2. PaymentLink (đã có: PaymentLinkModel)

- `paymentUrl, orderCode, paymentStatus (0 = chờ), expiresAt?, amount?`
- Vấn đề hiện tại: `formattedAmount` fallback `249.000 đ` khi `amount == null` — sau rebuild caller phải truyền amount thật, fallback chỉ còn cho dữ liệu cũ.
- Không đổi JSON parse để tránh vỡ tương thích backend.

## 3. Wallet (đã có: WalletModel)

- `userId, balance (VND, double), currency = VND, updatedAt?`
- Validation: `balance >= 0`; mua bằng ví chỉ cho khi `balance >= plan.price`; sau mua thành công `loadWallet()` + invalidate statements.

## 4. WalletStatement (đã có: WalletStatementModel)

- `id, amount, transactionType, previousBalance, newBalance, description, createdAt?`
- `isIncome = amount > 0 || type chứa topup/credit/deposit`; `typeLabel`: topup/deposit → `Nạp tiền vào ví`, purchase → `Mua gói hội viên`, refund/credit → `Hoàn tiền vào ví`.
- Quan hệ: mỗi statement thành công phải thỏa `newBalance - previousBalance ≈ ±amount` (dung sai làm tròn VNĐ).

## 5. SubscriptionPlan / UserSubscription (đã có, dùng lại)

- `SubscriptionPlanModel`: `id, name, slug, price, durationDays = 30, maxWardrobeItems, maxOutfits, aiOutfitDailyQuota, aiChatDailyQuota, features[], isActive`. Không hardcode giá ở UI logic; giá lấy từ `plans` API, fallback `premium-monthly` chỉ khi API lỗi.
- `UserSubscriptionModel.isPremium = slug != free && status == ACTIVE`. Waiting mua trực tiếp poll field này.

## 6. Trạng thái giao dịch (suy ra, không có model riêng ở backend hiện tại)

- `pending → success | cancelled | expired`. Client suy ra: success qua ví/subscription như mục 1; cancelled khi user quay lại từ `cancelUrl` mà poll không thấy tiền; expired khi `now - createdAt > 15 phút`.
- Đề xuất backend tương lai: `GET /payments/{orderCode}` trả trạng thái chuẩn — mobile đã thiết kế `PaymentRepository.getOrderStatus()` chờ sẵn, hiện mock bằng poll ví/subscription.
