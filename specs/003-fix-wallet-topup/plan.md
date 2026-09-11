# Implementation Plan: Fix Wallet Top-Up Flow

**Branch**: `003-fix-wallet-topup` | **Date**: 2026-09-11 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/003-fix-wallet-topup/spec.md`

## Summary

Sửa luồng nạp tiền ví đang vỡ 3 điểm: (1) nhấn Nạp không tới được trang QR — mở browser ngoài rồi đẩy sang màn hình chờ của luồng Premium; (2) tự báo "nâng cấp Premium thành công" dù chỉ nạp ví, vì màn hình chờ poll `isPremium`; (3) kẹt ở trang Gói Hội Viên & Hạn Mức thay vì về ví. Cách tiếp cận (chi tiết trong [research.md](research.md)): màn hình QR nạp ví trong app (render từ `paymentUrl`, package `qr_flutter`), tách luồng nạp ví khỏi màn hình chờ Premium bằng `PaymentPurpose`, xác nhận thành công bằng chênh lệch số dư ví + đối chiếu statements (không cần API backend mới), đích đến sau nạp là `/profile/wallet`.

## Technical Context

**Language/Version**: Dart 3.13 / Flutter 3.47.2 (stable)

**Primary Dependencies**: flutter_riverpod 2.x, go_router 14.x, dio, url_launcher (hiện có) + mới `qr_flutter` (render QR trong app)

**Storage**: N/A — số dư ví server-side; token vẫn qua flutter_secure_storage như hiện tại

**Testing**: flutter_test (widget test cho parse số tiền + watch-state) + QA thủ công trên emulator theo quickstart.md

**Target Platform**: Android emulator (API 37, emulator-5554) là mục tiêu kiểm thử chính; iOS/Web không đổi hành vi

**Project Type**: mobile-app (Flutter)

**Performance Goals**: Poll xác nhận mỗi 3s; phát hiện thành công trong ~10s sau khi tiền vào; timeout 900s khớp hạn QR PayOS

**Constraints**: Không thay đổi API backend; không sửa native (AndroidManifest/deep-link dời giai đoạn sau); giữ nguyên luồng mua Premium (hồi quy); tuân thủ tokens Quiet Luxury + 6 Gotchas trong PROJECT_AGENT_GUIDE.md

**Scale/Scope**: ~5 file sửa + 1 màn hình mới + 1 dependency mới; chỉ chạm `features/profile`

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` là template chưa phê chuẩn (toàn placeholder) → không có gate ràng buộc nào áp dụng. Thay vào đó áp dụng conventions dự án (skill closy-mobile-flutter): Riverpod cho business logic, GoRouter cho điều hướng, Dio giữ header `Accept-Encoding: identity`, UI theo tokens Quiet Luxury. Không vi phạm — không cần Complexity Tracking.

*Re-check sau Phase 1*: thiết kế chỉ dùng lại providers/routes/models hiện có + 1 enum + 1 screen + 1 dep UI chuẩn → PASS, không vi phạm.

## Project Structure

### Documentation (this feature)

```text
specs/003-fix-wallet-topup/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/
│   └── topup-flow.md    # Phase 1 output (/speckit-plan command)
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
lib/
├── core/
│   └── router/
│       └── app_router.dart                 # MODIFY: thêm route /profile/wallet/topup-qr, truyền PaymentPurpose
└── features/
    └── profile/
        ├── data/
        │   └── profile_repository.dart     # REUSE: getWallet/getWalletStatements/createWalletTopUp (không sửa)
        ├── models/
        │   └── user_profile_models.dart    # MODIFY: thêm enum PaymentPurpose (nhỏ)
        ├── providers/
        │   └── profile_provider.dart       # MODIFY: WalletNotifier thêm startTopUpWatch/checkTopUpOnce/cancelTopUpWatch
        └── presentation/
            ├── payment_waiting_screen.dart         # MODIFY: số tiền động (formattedAmount), nhận purpose
            ├── wallet_detail_screen.dart           # MODIFY: reload số dư khi resume/quay về
            └── widgets/
                ├── topup_bottom_sheet.dart         # MODIFY: chuẩn hóa parse tiền 1 hàm + push route QR mới
                └── topup_qr_screen.dart            # NEW: màn hình QR + chờ + thành công luồng nạp ví

pubspec.yaml  # MODIFY: thêm qr_flutter
test/
└── features/profile/wallet_topup_test.dart  # NEW: test parse tiền + logic watch-state
```

**Structure Decision**: Single-project Flutter layout hiện có của repo; thay đổi khoanh vùng trong `features/profile`, tuân thủ phân lớp data/providers/presentation sẵn có.

## Complexity Tracking

> Không có vi phạm Constitution Check → mục này để trống.
