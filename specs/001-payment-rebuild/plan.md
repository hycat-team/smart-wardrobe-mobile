# Implementation Plan: Payment Rebuild

**Branch**: `001-payment-rebuild` | **Date**: 2026-09-12 | **Spec**: `specs/001-payment-rebuild/spec.md`

**Input**: Feature specification from `specs/001-payment-rebuild/spec.md` — làm lại payment: nạp ví PayOS (P1), mua gói bằng ví (P1), mua trực tiếp (P2), waiting + lịch sử đúng trạng thái (P2).

## Summary

Giữ kiến trúc hiện tại (Riverpod + GoRouter + Dio + `url_launcher` external) nhưng sửa 2 lỗi chặn release: waiting hardcode `249.000đ/Premium` và poll sai kind (nạp ví poll subscription nên không bao giờ success). Cách làm: tách `PaymentRepository`, thêm `PaymentKind` + `PendingPayment {orderCode, amount, kind, label, paymentUrl}`, waiting generic poll theo kind (ví: snapshot balance; gói: `isPremium`), guard double-submit, deep-link return qua `app_links`. Chi tiết xem `research.md`, `data-model.md`, `contracts/payment-api.md`, `quickstart.md`.

## Technical Context

**Language/Version**: Dart 3.x, Flutter 3.x

**Primary Dependencies**: `flutter_riverpod` 2.5.1 (`StateNotifierProvider`), `go_router` 14.2, `dio` 5.4 (+ Bearer interceptor, `Accept-Encoding: identity` non-web), `url_launcher` 6.3 (`externalApplication`), `google_fonts`, `flutter_secure_storage`, `flutter_dotenv`; thêm mới `app_links` cho deep-link return

**Storage**: Không thêm local DB; nguồn thật là backend (`/subscriptions/me*`, `/wallet*`); client chỉ giữ snapshot balance + `PendingPayment` trong memory để đối soát

**Testing**: `flutter_test` + `flutter_lints` hiện có; unit/widget cho format VND, `isIncome/typeLabel`, validate min 10k, waiting theo kind; manual theo `quickstart.md` với PayOS sandbox

**Target Platform**: iOS / Android / Web (`flutter run -d chrome --web-port=8081`)

**Project Type**: mobile-app (module `features/profile`, khả năng tách `features/payment`)

**Performance Goals**: Poll 3s trong 2 phút đầu, giãn 10s đến trần 15 phút; giao dịch ngoài thành công phản ánh trong 2 phút (SC-002); nạp ví end-to-end dưới 3 phút (SC-001)

**Constraints**: PayOS `description <= 25 ký tự`; nạp tối thiểu 10.000đ; bắt buộc mở checkout ngoài để app-switch banking; `returnUrl` chỉ là UX, trạng thái chốt bằng poll backend; BottomSheet phải bọc `SingleChildScrollView` (Gotcha 4)

**Scale/Scope**: ~8 file payment hiện tại (`profile_repository.dart`, `profile_provider.dart`, `user_profile_models.dart`, `payment_waiting_screen.dart`, `wallet_detail_screen.dart`, `subscription_upgrade_screen.dart`, `topup_bottom_sheet.dart`, `app_router.dart`); 14 FR, 4 user stories

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Constitution repo hiện là template placeholder (chưa có nguyên tắc/gate thực thi) nên không có gate nào để vi phạm. Áp dụng thay thế bằng Definition of Done của skill `closy-mobile-flutter`: `flutter analyze` sạch lỗi mới, không vi phạm 6 Gotchas, tuân thủ Quiet Luxury tokens + safe-area + bottom-nav, giữ Dio header `Accept-Encoding: identity`.

Re-check sau Phase 1: thiết kế không thêm kiến trúc mới ngoài 1 repository + 2 model wrapper + 1 package deep-link; không vi phạm đơn giản hóa — tách Payment là cần thiết để xóa nhánh `if (isTopUp)` rải ở UI.

## Project Structure

### Documentation (this feature)

```text
specs/001-payment-rebuild/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
│   └── payment-api.md
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── constants/app_constants.dart      # baseUrl, key lưu token
│   ├── network/api_client.dart           # Dio + Bearer + Accept-Encoding
│   └── router/app_router.dart            # /profile/wallet, /subscription*, waiting nhận PendingPayment
└── features/
    ├── profile/
    │   ├── data/profile_repository.dart          # giữ phần profile, chuyển payment sang repo mới
    │   ├── data/payment_repository.dart          # MỚI: topup/purchase/purchase-with-wallet/wallet/statements
    │   ├── models/user_profile_models.dart       # thêm PaymentKind + PendingPayment, bỏ fallback 249k
    │   ├── providers/profile_provider.dart       # tách payment notifier dùng PaymentRepository
    │   └── presentation/
    │       ├── payment_waiting_screen.dart       # generic theo PendingPayment, poll theo kind
    │       ├── wallet_detail_screen.dart
    │       ├── subscription_upgrade_screen.dart
    │       └── widgets/topup_bottom_sheet.dart   # + SingleChildScrollView + guard + returnUrl
    └── payment/                                  # PHƯƠNG ÁN B: dời các file payment sang đây nếu muốn tách sạch
```

**Structure Decision**: Mặc định sửa tại chỗ trong `features/profile` + 1 file `payment_repository.dart` mới để diff nhỏ, review nhanh; chỉ tách thư mục `features/payment/` khi team đồng ý dời waiting + wallet + upgrade (nội dung không đổi, chỉ đổi import + route).

## Complexity Tracking

> Không có vi phạm constitution cần biện minh (constitution là placeholder). Ghi nhận 1 điểm phức tạp có chủ ý:

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Thêm `PaymentRepository` + `PendingPayment` thay vì tái dùng `ProfileRepository` + `PaymentLinkModel` | Xóa hardcode amount/label và poll sai kind — nguyên nhân trực tiếp của SC-003/SC-002 fail | Giữ repo chung + `if (isTopUp)` ở UI làm logic phân nhánh phình ở 3 màn hình, khó test và dễ tái hardcode |

## Phases (gợi ý cho /speckit-tasks)

- **Phase A (P1)**: `PaymentRepository` + `PaymentKind/PendingPayment` + sửa `TopUpBottomSheet` (validate, guard, returnUrl) + waiting poll ví bằng snapshot balance.
- **Phase B (P1)**: Mua bằng ví (confirm dialog, đủ/thiếu tiền, refresh ví + subscription + statements).
- **Phase C (P2)**: Mua trực tiếp + waiting poll `isPremium` + mở lại PayOS + hết hạn/hủy + rời an toàn + deep-link `app_links` + đổi route extra.
- **Phase D (P2)**: Lịch sử ví (empty-state, refresh, đúng chiều thu-chi) + regression `flutter analyze` + `quickstart.md`.
