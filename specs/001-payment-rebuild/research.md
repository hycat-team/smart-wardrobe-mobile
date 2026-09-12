# Research: Payment Rebuild

**Feature**: `001-payment-rebuild` | **Date**: 2026-09-12

## Decision 1: Mở trang PayOS bằng external browser, không nhúng WebView

- **Decision**: Giữ `url_launcher` với `LaunchMode.externalApplication` cho cả nạp ví và mua gói trực tiếp.
- **Rationale**: VietQR / banking app cần app-switch về app ngân hàng; WebView trong app bị chặn redirect, cookie, và deep-link return. Code hiện tại (`topup_bottom_sheet.dart`, `subscription_upgrade_screen.dart`) đã đúng hướng này.
- **Alternatives considered**: `flutter_inappwebview` / `webview_flutter` — loại vì tăng rủi ro chặn thanh toán ngân hàng và phải tự xử lý SSL/navigation delegate; chỉ phù hợp khi cần giữ user trong app, không phù hợp PayOS + VietQR.

## Decision 2: Polling backend làm nguồn xác nhận, không tin returnUrl

- **Decision**: `PaymentWaiting` poll `GET /subscriptions/me` (+ `GET /subscriptions/me/wallet` cho nạp ví) mỗi 3s trong 2 phút đầu, sau đó giãn 10s đến tối đa 15 phút; kèm nút "Tôi đã thanh toán" (fetch ngay) và "Mở lại trang PayOS".
- **Rationale**: `returnUrl`/`cancelUrl` chỉ là UX điều hướng, trạng thái thật nằm ở backend qua webhook PayOS. Poll trực tiếp `orderCode` là tốt nhất nhưng backend hiện tại chưa có endpoint tra cứu theo `orderCode`, nên poll gián tiếp qua ví/subscription là khả thi ngay.
- **Alternatives considered**: SSE realtime cho payment — loại cho v1 vì backend chưa có kênh SSE payment (SSE hiện chỉ có cho wardrobe upload); polling + manual refresh đủ đạt SC-002 (2 phút).

## Decision 3: Tách Payment khỏi Profile, thêm PendingPayment có kind

- **Decision**: Tạo `lib/features/payment/` (hoặc `features/profile/data/payment_repository.dart` nếu muốn đổi nhỏ): `PaymentRepository` + `PaymentKind { walletTopUp, directPurchase }` + `PendingPayment { orderCode, amount, kind, label, paymentUrl, createdAt }`. `PaymentWaitingScreen` nhận `PendingPayment`, không nhận mỗi `PaymentLinkModel`.
- **Rationale**: Lỗi lớn nhất hiện tại là waiting screen hardcode `249.000đ / Premium (30 ngày)` (`payment_waiting_screen.dart`) và chỉ poll subscription nên nạp ví không bao giờ success. `PendingPayment` buộc mọi caller truyền đúng amount/label/kind.
- **Alternatives considered**: Giữ nguyên `ProfileRepository` + thêm `if (isTopUp)` rải rác — loại vì logic phân nhánh sẽ phình ở UI, khó test.

## Decision 4: Deep-link return cần thêm package + config native

- **Decision**: Thêm `app_links` ( Dok: `smartwardrobe://wallet/topup/*`, `smartwardrobe://subscription/*`; web dùng `${Uri.base.origin}/profile...`), cấu hình `intent-filter` Android + URL scheme iOS. V1 vẫn chạy được chỉ bằng polling nếu deep-link chưa xong, deep-link là cải tiến UX không chặn release.
- **Rationale**: `returnUrl`/`cancelUrl` deep-link đã được truyền trong code nhưng chưa có listener nên user quay lại app thủ công. Có listener giúp tự trigger refresh khi return.
- **Alternatives considered**: Dùng `uni_links` đời cũ — loại, `app_links` là bản kế tiếp được maintain.

## Decision 5: Guard chống double-submit + validation 10.000đ ở client

- **Decision**: `_isProcessing` / `isCreatingPurchase` disable nút trong lúc tạo link; validate `>= 10.000đ` trước khi gọi API; preset `50k/100k/200k/500k` giữ nguyên.
- **Rationale**: Đạt FR-012/SC-004, tránh 2 `orderCode` cho 1 ý định. Validation server vẫn là chốt chặn cuối.
- **Alternatives considered**: Debounce generic toàn app — loại, guard cục bộ ở flow payment đủ và rõ ràng hơn.

## Decision 6: Test bằng flutter_test hiện có, chưa cần integration harness mới

- **Decision**: Unit/widget test cho `formattedAmount/VND`, `isIncome/typeLabel`, guard min-amount, routing waiting với `PendingPayment` đúng/sai kind. Manual quickstart cho flow thật với PayOS sandbox.
- **Rationale**: `pubspec.yaml` đã có `flutter_test`, `flutter_lints`; chưa có `integration_test`/`mockito` nên không hứa hẹn harness mới trong scope rebuild này.
- **Alternatives considered**: Thêm `mockito` + golden test — để backlog, không chặn v1.
