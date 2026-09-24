# Implementation Plan: Web Payment Redirect

**Branch**: `009-web-payment-redirect` | **Date**: 2026-09-24 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/009-web-payment-redirect/spec.md`

## Summary

Chuyển luồng payment mobile sang chỉ-hiển-thị: giữ xem danh sách gói (tên, giá, thời hạn, quyền lợi) và xem số dư + lịch sử ví ở chế độ chỉ đọc; gỡ bỏ mọi hành vi khởi tạo/mở thanh toán trong app (link PayOS, QR, WebView, form nhập số tiền, nút mua bằng ví, `TopUpBottomSheet`); thay bằng hướng dẫn văn bản thuần túy (địa chỉ website + các bước tự mở trình duyệt, đăng nhập cùng tài khoản, thanh toán/nạp trên web); tự động tải lại gói + ví khi quay lại app để phản ánh kết quả web. Áp dụng thống nhất Android và iOS, không thêm dependency mới.

## Technical Context

**Language/Version**: Dart `>=3.0.0 <4.0.0`, Flutter (Material, `uses-material-design: true`)

**Primary Dependencies**: `flutter_riverpod ^2.5.1` (Subscription/Wallet providers), `go_router ^14.2.0` (routing màn hình profile/gói/ví), `dio ^5.4.3+1` (đọc gói/trạng thái/ví), `google_fonts`, `intl` (định dạng giá VNĐ). `url_launcher` và `app_links` HIỆN CÓ trong pubspec nhưng PHẢI KHÔNG được dùng cho bất kỳ đường thanh toán/mở website nào trong feature này (theo Clarification Q1).

**Storage**: N/A phía mobile (không thêm cache/schema mới; trạng thái gói/ví đọc từ backend qua API hiện có; hướng dẫn web là nội dung tĩnh + chuỗi địa chỉ website từ cấu hình app).

**Testing**: `flutter_test` + `flutter_lints ^4.0.0`; kiểm chứng chính bằng kịch bản thủ công trong `quickstart.md` (quét toàn bộ điểm vào gói/ví, xác minh không còn checkout; xác minh auto-refresh sau thanh toán web). Không thêm framework test mới.

**Target Platform**: Android + iOS (áp dụng thống nhất, theo Clarification Q5).

**Project Type**: mobile-app (single Flutter project).

**Performance Goals**: Quay lại app từ nền thấy trạng thái mới trong vòng 2 phút ở 95% lượt thử (SC-003); thao tác tải lại gói/ví khi resume không treo UI (có loading + lỗi thân thiện tiếng Việt, nút thử lại).

**Constraints**:
- KHÔNG `launchUrl` / mở trình duyệt / WebView / QR cho thanh toán hay website từ app (FR-003, FR-006; Clarification Q1).
- KHÔNG form nhập số tiền, KHÔNG nút nạp ví / mua bằng ví trong app (FR-004; Clarification Q4).
- Hướng dẫn web chỉ là văn bản đọc được: địa chỉ website đầy đủ + yêu cầu cùng tài khoản + các bước (FR-002, FR-005, FR-006).
- Giữ hiển thị đầy đủ giá gói trên mobile (FR-001; Clarification Q2).
- Không thêm dependency, không thay đổi backend/website trong phạm vi này.
- Mọi thông báo lỗi tiếng Việt + bước tiếp theo (FR-010).

**Scale/Scope**: Phạm vi `lib/features/profile/` — các màn hình `subscription_upgrade_screen`, `subscription_detail_screen`, `wallet_detail_screen`, widget `closy_wallet_card`, `topup_bottom_sheet`, `payment_waiting_screen` / `payment_result_screen`, `utils/payment_link_opener`, providers `profile_provider` (subscription/wallet), `data/payment_repository`; không chạm các feature khác.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

> Constitution hiện tại (`.specify/memory/constitution.md`) chỉ là template placeholder, chưa có nguyên tắc ràng buộc nào được phê chuẩn — không có gate nào để vi phạm. Các kiểm tra dưới đây là áp dụng theo tinh thần mặc định (đơn giản, không phát sinh thư viện, kiểm chứng được).

- [x] Simplicity: không thêm project/module/dependency; chỉ gỡ đường thanh toán và thay bằng nội dung tĩnh + tái sử dụng API đọc hiện có.
- [x] No new library: không tạo package mới; thay đổi nằm trong `lib/features/profile/`.
- [x] Testability: mỗi user story có Independent Test + `quickstart.md` tương ứng; SC-001/SC-003 kiểm chứng thủ công được.
- [x] No scope creep: backend/website/IAP ngoài phạm vi; mobile không giữ logic tạo link thanh toán.

Re-check sau Phase 1: PASS — thiết kế (research/data-model/contracts/quickstart) không giới thiệu dependency, schema hay API mới; mọi ràng buộc FR-003/FR-006 được giữ trong contracts.

## Project Structure

### Documentation (this feature)

```text
specs/009-web-payment-redirect/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
│   └── web-handoff-contract.md
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── network/api_client.dart
│   └── theme/ (AppColors)
├── features/
│   └── profile/
│       ├── data/payment_repository.dart      # giữ API đọc; ngưng dùng API tạo link/mua
│       ├── providers/profile_provider.dart   # giữ load subscription/wallet/statements; ngưng topUp/purchase paths
│       ├── models/user_profile_models.dart   # giữ SubscriptionPlan/UserSubscription/Wallet/Statements (chỉ đọc)
│       ├── presentation/
│       │   ├── subscription_upgrade_screen.dart
│       │   ├── subscription_detail_screen.dart
│       │   ├── wallet_detail_screen.dart
│       │   ├── payment_waiting_screen.dart   # ngưng điều hướng tới sau đổi luồng
│       │   ├── payment_result_screen.dart    # ngưng điều hướng tới sau đổi luồng
│       │   └── widgets/
│       │       ├── closy_wallet_card.dart
│       │       └── topup_bottom_sheet.dart   # ngưng sử dụng (không còn call site)
│       └── utils/payment_link_opener.dart    # ngưng sử dụng cho thanh toán
```

**Structure Decision**: Single Flutter project — mọi thay đổi nằm trong `lib/features/profile/` hiện có; tài liệu feature nằm trong `specs/009-web-payment-redirect/`. Không tạo thư mục nguồn mới.

## Complexity Tracking

> Không có vi phạm Constitution cần biện minh (constitution là placeholder; thiết kế không thêm độ phức tạp mới).

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |
