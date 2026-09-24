# Data Model: Web Payment Redirect (Phase 1)

**Feature**: `009-web-payment-redirect` | **Date**: 2026-09-24

Không thay đổi schema backend hay model hiện có. Tất cả entities dưới đây là chế độ chỉ đọc phía mobile (ánh xạ từ `user_profile_models.dart` hiện tại) cộng một nội dung tĩnh mới. Không thêm bảng, không migration.

## 1. SubscriptionPlanDisplay (chỉ đọc)

- Nguồn: `SubscriptionPlanModel` (`id`, `name`, `slug`, `description`, `price`, `durationDays`, `maxWardrobeItems`, `maxOutfits`, `aiOutfitDailyQuota`, `aiChatDailyQuota`, `features`, `isActive`) qua `getSubscriptionPlans()`.
- Hiển thị: tên, `formattedPrice` VNĐ, thời hạn ngày, danh sách quyền lợi/so sánh.
- Validation: chỉ render gói `isActive`; khi danh sách rỗng/lỗi → thông báo tiếng Việt + nút thử lại, không hiện hướng dẫn thanh toán (FR-001, FR-010).
- Quan hệ: 1 plan ↔ N `UserSubscriptionStatus` theo thời gian (chỉ quan sát sau thanh toán web).

## 2. UserSubscriptionStatus (chỉ đọc, đồng bộ từ web)

- Nguồn: `UserSubscriptionModel` (`planId`, `planName`, `planSlug`, `expiresAt`, `status`, hạn mức) qua `getMySubscription()` + `DailyQuotaModel` qua `getDailyQuota()`.
- Chuyển trạng thái (chỉ quan sát, mobile không ghi):
  - `free/ACTIVE` → (thanh toán web thành công) → `<paid-plan>/ACTIVE` + hạn mức mới.
  - Giao dịch web chưa xong → giữ trạng thái cũ, gợi ý kiểm tra lại sau (không báo thành công giả).
- Validation: `isPremium = planSlug != 'free' && status == 'ACTIVE'` (giữ logic hiện có); hết hạn/quota do backend quyết định.

## 3. WalletReadOnly (chỉ đọc)

- Nguồn: `WalletModel` (`formattedBalance`) qua `getWallet()` + `List<WalletStatementModel>` (`typeLabel`, `description`, `createdAt`, `formattedAmount`, `isIncome`) qua `getWalletStatements(page, pageSize)`.
- Hiển thị: số dư khả dụng + lịch sử biến động; KHÔNG form nhập tiền, KHÔNG nút nạp/mua (FR-004, FR-008).
- Validation: lỗi tải → thông báo tiếng Việt + thử lại (dùng lại AppBar refresh + `RefreshIndicator` sẵn có ở `wallet_detail_screen`); số dư mới chỉ đến từ kết quả nạp web.

## 4. WebGuidanceContent (nội dung tĩnh mới, không phải entity lưu trữ)

- Trường: `websiteHostText` (văn bản địa chỉ website đầy đủ từ một hằng số cấu hình duy nhất), `steps` (3 bước cố định: 1. tự mở trình duyệt ngoài app → 2. đăng nhập cùng tài khoản mobile → 3. thanh toán gói / nạp ví trên web rồi quay lại app), `sameAccountNote` (nhấn mạnh cùng email/số điện thoại), `staleLinkNote` (link cũ hết hiệu lực).
- Validation: không chứa URL có tham số gói/số tiền/user; không gắn hành động mở link (FR-002, FR-005, FR-006).
- Quan hệ: hiển thị trong màn hình gói (khi chọn gói) và màn hình/ví (khi có nhu cầu nạp); dùng chung một nguồn câu chữ để tránh lệch.

## Luồng làm mới (không phải entity)

- Trigger: app resume từ nền + mở lại màn hình gói/ví → gọi lại `getMySubscription`/`getDailyQuota`/`getWallet`/`getWalletStatements` hiện có.
- Không polling liên tục, không SSE mới; đủ đáp ứng SC-003 trong 2 phút sau khi quay lại app.
