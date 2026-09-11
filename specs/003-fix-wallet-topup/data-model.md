# Data Model: Fix Wallet Top-Up Flow

**Feature**: `003-fix-wallet-topup` | **Date**: 2026-09-11

> Chỉ dùng các thực thể đã có trong `lib/features/profile/models/user_profile_models.dart`, cộng thêm trạng thái phía client. Không thay đổi schema backend.

## 1. PaymentLinkModel (đã có — dùng lại)

Lệnh thanh toán do backend tạo (`POST /subscriptions/me/wallet/topup`).

- `paymentUrl` (String): đường dẫn checkout — nguồn render mã QR trong app.
- `orderCode` (int): mã đơn hàng — hiển thị `#<orderCode>`, dùng đối chiếu statements.
- `paymentStatus` (int): giữ nguyên, không dùng để kết luận thành công phía client.
- `expiresAt` (String?): hiển thị đếm ngược hết hạn nếu có.
- `amount` (double?) + `formattedAmount`: **bắt buộc hiển thị đúng số tiền nạp** (thay cho chuỗi cứng '249.000 đ' hiện tại).

## 2. WalletModel (đã có — dùng lại)

- `balance` (double), `formattedBalance`, `currency` (VND), `updatedAt`.
- Vai trò mới: `balanceBefore` (chụp lúc tạo lệnh) vs `balanceNow` (mỗi vòng poll) → hiệu số xác nhận nạp thành công.

## 3. WalletStatementModel (đã có — dùng lại, đối chiếu chéo)

- `amount`, `transactionType` (nhận diện nạp tiền qua `isIncome` / `typeLabel`), `previousBalance`/`newBalance`, `createdAt`.
- Quy tắc khớp: entry có `createdAt` sau thời điểm tạo lệnh + `amount` khớp số tiền nạp (±epsilon) + kiểu nạp tiền → xác nhận độc lập với so sánh số dư.

## 4. PaymentPurpose (mới, enum phía client)

- `topup` — lệnh nạp ví → route `/profile/wallet/topup-qr`, chờ theo chênh lệch số dư, đích đến `/profile/wallet`.
- `subscription` — mua gói Premium → route `/profile/subscription/waiting` cũ, giữ logic `isPremium`, đích đến `/profile/subscription`.
- Mục đích: một `extra` duy nhất mang `{link, purpose}` để router và màn hình chờ không bao giờ lẫn luồng.

## 5. TopUpWatchState (mới, state client trong WalletNotifier)

- `balanceBefore` (double), `expectedAmount` (double), `orderCode` (int), `createdAt` (DateTime).
- `status`: `waiting` | `success` | `expired` | `error` (+ `errorMessage`).
- `secondsElapsed`: đếm thời gian chờ (timeout 900s).
- Chuyển trạng thái: `waiting` → `success` (số dư tăng đủ + statements khớp) | `expired` (hết 900s) | `error` (lỗi mạng kéo dài / tạo lệnh thất bại).

## Validation rules (từ spec)

- Số tiền nạp: số sau chuẩn hóa (bỏ `.` `,` khoảng trắng) phải `>= 10000`, từ chối 0/âm/trống kèm thông báo.
- Chuẩn hóa số tiền dùng **một hàm duy nhất** cho cả hiển thị preset và submit (fix bug parse lệch).
- Chống double-submit: nút nạp disable trong lúc `_isCreatingTopUp` + guard trong notifier.
