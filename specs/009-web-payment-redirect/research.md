# Research: Web Payment Redirect (Phase 0)

**Feature**: `009-web-payment-redirect` | **Date**: 2026-09-24

Tất cả unknowns trong Technical Context đã được giải quyết qua spec + 5 clarifications + khảo sát codebase hiện tại (`payment_repository.dart`, `subscription_upgrade_screen`, `wallet_detail_screen`, `closy_wallet_card`, `topup_bottom_sheet`, `payment_waiting_screen`, `payment_link_opener.dart`, `pubspec.yaml`). Không còn NEEDS CLARIFICATION.

## R1 — Cơ chế đưa người dùng lên website: văn bản thuần túy, không nút/link

- **Decision**: Hướng dẫn thanh toán web CHỈ là văn bản đọc được (địa chỉ website đầy đủ + 3 bước: tự mở trình duyệt → đăng nhập cùng tài khoản → thanh toán/nạp trên web). Không dùng `url_launcher.launchUrl`, không `app_links`, không WebView, không nút sao chép tự động.
- **Rationale**: Clarification Q1 chốt "chỉ hiện hướng dẫn tự mở" vì đây là phương án an toàn nhất cho vòng duyệt Play; bất kỳ nút mở link nào (kể cả trang chủ chung) cũng tạo dấu vết điều hướng thanh toán ngoài. FR-003/FR-006 cấm显式.
- **Alternatives considered**: Nút "Mở website chung" tới trang chủ/giá (bị loại — vẫn là điều hướng có chủ đích từ điểm mua); nút + sao chép địa chỉ (bị loại — sao chép tự động vẫn bị xem là hỗ trợ lách).

## R2 — Hiển thị giá gói trên mobile: giữ đầy đủ

- **Decision**: Giữ tên + giá VNĐ + thời hạn + quyền lợi/so sánh như hiện tại; chỉ gỡ mọi hành động khởi tạo thanh toán.
- **Rationale**: Clarification Q2 chốt "giữ đầy đủ giá"; spec ghi giá mobile chỉ mang tính giới thiệu, giá hiệu lực cuối cùng theo website. FR-001.
- **Alternatives considered**: Ẩn giá chỉ giữ quyền lợi (bị loại — giảm giá trị giới thiệu, user hoang mang); giá kèm ghi chú (không cần — Assumptions đã nêu giá web là chuẩn cuối).

## R3 — Đồng bộ sau thanh toán web: tự động khi quay lại app

- **Decision**: Tự động tải lại `getMySubscription` (+ quota) và `getWallet` (+ statements) mỗi khi quay lại app từ nền (`WidgetsBindingObserver.didChangeAppLifecycleState → resumed`) và khi mở lại màn hình gói/ví (`initState`/focus). Không yêu cầu bấm làm mới thủ công.
- **Rationale**: Clarification Q3 chốt "tự động khi quay lại"; pattern `WidgetsBindingObserver` đã tồn tại trong `payment_waiting_screen.dart:26,51-54` nên tái sử dụng nhất quán, chi phí thấp, đáp ứng SC-003 (2 phút).
- **Alternatives considered**: Chỉ nút làm mới thủ công (bị loại — user tưởng thanh toán lỗi, tăng khiếu nại SC-004); cả hai (thừa — auto đã đủ, giữ nút refresh sẵn có trên `wallet_detail_screen` AppBar như fallback hiển thị lỗi/thử lại là đủ, không thêm nút mới).

## R4 — Phạm vi gỡ bỏ luồng cũ: ẩn hoàn toàn, ngưng mọi call site tạo thanh toán

- **Decision**: Gỡ khỏi UI: form nhập số tiền + nút "Nạp tiền/Nạp Tiền Vào Ví" mở `TopUpBottomSheet` (3 call sites: `closy_wallet_card`, `wallet_detail_screen`, `subscription_upgrade_screen`), nút mua bằng ví (`purchasePlanWithWallet`), nút tạo link trực tiếp (`createDirectPurchase` → `payment_link_opener` → `PaymentWaitingScreen` → `PaymentResultScreen`). Giữ lại API đọc: `getSubscriptionPlans`, `getMySubscription`, `getDailyQuota`, `getWallet`, `getWalletStatements`.
- **Rationale**: Clarification Q4 chốt "ẩn hoàn toàn"; FR-004/FR-009 yêu cầu không còn form/nút và không xử lý link cũ. `PaymentRepository` hiện trộn cả đọc + tạo link trong một class nên plan là ngưng dùng (không gọi) các method tạo/mua ở tầng provider/UI thay vì xóa backend.
- **Alternatives considered**: Giữ nút nhưng chuyển thành mở hướng dẫn (bị loại — giữ lại affordance thanh toán gây nhầm lẫn và rủi ro duyệt); giữ mua bằng ví khi đủ số dư (bị loại — vẫn là giao dịch giá trị trong app, trái FR-004 đã chốt).

## R5 — Phạm vi nền tảng: thống nhất Android + iOS

- **Decision**: Một luồng duy nhất cho cả hai nền tảng, không rẽ nhánh theo `Platform.isAndroid`.
- **Rationale**: Clarification Q5; đơn giản hóa kiểm thử SC-001 (quét mọi điểm vào) và tránh lệch trải nghiệm/store policy (App Store có quy định tương tự).
- **Alternatives considered**: Chỉ đổi Android (bị loại — nhân đôi luồng, khó bảo trì, iOS vẫn rủi ro duyệt).

## R6 — Nguồn chuỗi địa chỉ website trong hướng dẫn

- **Decision**: Dùng một hằng số cấu hình duy nhất của app (ví dụ giá trị sẵn có trong cấu hình môi trường/app config như `.env`, không hardcode rải rác); hiển thị dạng văn bản, không gắn tham số gói/số tiền/user.
- **Rationale**: Spec Assumptions: website đã tồn tại ổn định; FR-002/FR-006 yêu cầu địa chỉ đầy đủ nhưng cấm deep-link checkout. Một nguồn duy nhất tránh lệch địa chỉ giữa các màn hình.
- **Alternatives considered**: Hardcode mỗi màn hình (bị loại — dễ lệch); truyền tham số gói/user vào link (bị cấm bởi FR-006).

## R7 — Giao dịch dang dở từ bản cũ

- **Decision**: Không mở/khôi phục `PaymentLinkModel`/`PendingPayment` cũ; nếu phát hiện đường vào màn hình chờ/kết quả cũ thì hiển thị thông báo hết hiệu lực + hướng dẫn lên website (FR-009).
- **Rationale**: Tránh user kẹt ở QR/link 15 phút đã hết hạn và tránh vô tình mở checkout cũ vi phạm FR-003.
- **Alternatives considered**: Cho phép hoàn tất link cũ (bị loại — trái mục tiêu tuân thủ).
