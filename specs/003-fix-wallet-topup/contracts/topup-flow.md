# Contracts: Fix Wallet Top-Up Flow

**Feature**: `003-fix-wallet-topup` | **Date**: 2026-09-11

> Không thêm endpoint backend. Chỉ chốt hợp đồng route/state phía mobile và các API backend hiện có được sử dụng.

## 1. Route contract (GoRouter)

| Route | Extra | Màn hình | Dùng cho |
|-------|-------|----------|----------|
| `/profile/wallet/topup-qr` (mới) | `{ link: PaymentLinkModel, purpose: PaymentPurpose.topup }` | Màn hình QR nạp ví + chờ xác nhận | Luồng nạp ví |
| `/profile/subscription/waiting` (giữ nguyên) | `{ link: PaymentLinkModel, purpose: PaymentPurpose.subscription }` | `PaymentWaitingScreen` (sửa hiển thị số tiền động) | Luồng mua Premium |
| `/profile/wallet` (giữ nguyên) | — | `WalletDetailScreen` (reload số dư khi quay về) | Đích đến sau nạp thành công |
| `/profile/subscription` (giữ nguyên) | — | `SubscriptionDetailScreen` | Đích đến sau mua Premium (không đổi) |

Quy tắc: `extra` thiếu `purpose` → mặc định `subscription` (tương thích code gọi cũ, không crash).

## 2. Backend API contracts (đã tồn tại — dùng lại, không sửa)

| Method & Endpoint | Dùng để | Ghi chú |
|-------------------|---------|---------|
| `POST /subscriptions/me/wallet/topup` `{amount, returnUrl?, cancelUrl?}` | Tạo lệnh nạp → `PaymentLinkModel` | Đã có (`ProfileRepository.createWalletTopUp`) |
| `GET /subscriptions/me/wallet` | Chụp `balanceBefore` + poll `balanceNow` | Đã có (`getWallet`) |
| `GET /subscriptions/me/wallet/statements?page=1&pageSize=20` | Đối chiếu entry nạp tiền mới khớp amount + thời gian | Đã có (`getWalletStatements`) |
| `GET /subscriptions/me` + `GET /subscriptions/me/daily-quota` | Chỉ dùng cho luồng mua Premium | Không dùng cho luồng nạp ví nữa |

## 3. Provider contract (mở rộng, không phá API cũ)

- `WalletNotifier.topUp(amount, ...)` giữ nguyên chữ ký (trả `PaymentLinkModel?`).
- Thêm trên `WalletNotifier`: `startTopUpWatch(link, expectedAmount)` → khởi tạo `TopUpWatchState`; `checkTopUpOnce()` → một vòng kiểm tra (dùng cho nút bấm tay + resume); `cancelTopUpWatch()` → dọn timer.
- `SubscriptionOverviewNotifier.checkSubscriptionStatus()` giữ nguyên, chỉ còn phục vụ luồng Premium.

## 4. UI contract — màn hình QR nạp ví

Hiển thị: mã QR (từ `paymentUrl`), số tiền đúng (`formattedAmount`), mã đơn hàng, đếm ngược chờ/hết hạn, trạng thái (`Đang chờ` / `Thành công` / `Hết hạn` / `Lỗi mạng — thử lại`).
Hành động: "Mở trang thanh toán" (trình duyệt ngoài), "Sao chép liên kết", "Tôi đã chuyển tiền — Kiểm tra kết quả", back có dialog xác nhận rời đi.
Thành công: nút duy nhất về `/profile/wallet` kèm reload số dư — không nhắc Premium, không dẫn sang trang gói.
