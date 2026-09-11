# Research: Premium Payment Mobile (Parity FE)

**Feature**: `001-premium-payment-mobile` | **Date**: 2026-09-11

## R-01: Deep link trả về từ PayOS trên Flutter

- **Decision**: Dùng package `app_links` + custom scheme `smartwardrobe://` đã có trong code (`smartwardrobe://subscription/success|cancel`, `smartwardrobe://wallet/topup/success|cancel`).
- **Rationale**:
  - Custom scheme không đòi sở hữu domain (https App Links cần `assetlinks.json` / AASA — dự án chưa có domain cho mobile).
  - PayOS chỉ lưu chuỗi `returnUrl`/`cancelUrl` BE gửi sang và redirect trình duyệt về đó; custom scheme mở được app từ trình duyệt ngoài trên cả Android và iOS.
  - `app_links` là package chuẩn hiện tại cho custom scheme + initial-link (cold start) + stream (warm start); web không cần setup thêm (chỉ initial link).
- **Alternatives considered**:
  - `uni_links` — đã ngừng bảo trì, loại.
  - https App Links/Universal Links — cần domain + file well-known, quá nặng cho đợt này, loại.
  - Chỉ polling màn hình chờ — user đã bác (chọn đón deep link), giữ polling làm dự phòng.
- **Native setup còn thiếu** (đã kiểm chứng trong repo):
  - `android/.../AndroidManifest.xml`: chưa có `intent-filter` scheme `smartwardrobe`; cần thêm + `flutter_deeplinking_enabled=false` để không xung đột với handler mặc định của Flutter.
  - `ios/Runner/Info.plist`: chưa có `CFBundleURLTypes`/`CFBundleURLSchemes`; cần thêm.
- **Test**: `adb shell am start -a android.intent.action.VIEW -d "smartwardrobe://subscription/success"` và `xcrun simctl openurl booted "smartwardrobe://subscription/success"`.

## R-02: Mở trang PayOS từ app

- **Decision**: Giữ `url_launcher` với `LaunchMode.externalApplication` (mobile) như code hiện tại.
- **Rationale**: PayOS checkout là trang web ngoài; mở trình duyệt ngoài tránh WebView bị chặn cookie/storage và khớp hành vi FE (`window.location.href`). Polling + deep link bù lại việc không biết khi nào user quay lại.
- **Alternatives considered**: WebView trong app (`webview_flutter`) — thêm dependency, rủi ro session/cookie, loại.

## R-03: Polling xác nhận thanh toán

- **Decision**: Giữ polling `GET /subscriptions/me` mỗi 3 giây, tối đa 15 phút, như `PaymentWaitingScreen` hiện tại; deep link chỉ để điều hướng nhanh, nguồn xác thực duy nhất vẫn là API subscription.
- **Rationale**: Webhook/PayOS server-callback do backend sở hữu; mobile không nhận callback trực tiếp. Không tin query param trên deep link (có thể giả mạo) — mọi nâng cấp UI phải qua `isPremium` từ API.
- **Alternatives considered**: SSE realtime cho payment — backend không có endpoint SSE cho payment, loại.

## R-04: Toggle tự động gia hạn

- **Decision**: `PUT /subscriptions/me/auto-renew {enabled}` (endpoint FE đang dùng trong `subscription.api.ts`), thêm `toggleAutoRenew` vào `ProfileRepository` + notifier + Switch trong `SubscriptionDetailScreen`.
- **Rationale**: Parity 1-1 với FE, model mobile đã parse `isAutoRenewEnabled` sẵn.
- **Alternatives considered**: Không có — endpoint đã tồn tại.

## R-05: Giá tiền ghi cứng ở màn hình chờ

- **Decision**: Truyền giá + tên gói + mã đơn theo `PaymentLinkModel`/plan vào `PaymentWaitingScreen` (qua `extra` hoặc provider `activePaymentLink`), xóa literal `249.000 đ` tại `payment_waiting_screen.dart:216`.
- **Rationale**: Bug đã xác minh bằng đọc code; SC-004 yêu cầu số tiền luôn khớp gói đã chọn.

## R-06: Quy ước text/codebase cần tuân thủ

- **Decision**: Mọi file tiếng Việt ghi bằng UTF-8 (dùng Node `fs.writeFileSync(..., 'utf8')`, không dùng redirect PowerShell) — Gotcha 5 trong `PROJECT_AGENT_GUIDE.md`; `ListTile` trong nền màu bọc `Material` (Gotcha 3); bottom sheet bọc `SingleChildScrollView` (Gotcha 4).
