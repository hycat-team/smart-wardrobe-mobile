# Implementation Plan: Premium Payment Mobile (Parity FE)

**Branch**: `001-premium-payment-mobile` | **Date**: 2026-09-11 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-premium-payment-mobile/spec.md`

## Summary

Đưa thanh toán gói Premium trên mobile lên parity đầy đủ với FE: mua trực tiếp VietQR/PayOS, mua bằng ví, nạp ví, chi tiết gói + toggle tự động gia hạn. Tận dụng code đã có (~80%: màn nâng cấp, màn chờ polling, provider/repository ví) và lấp 3 lỗ hổng đã xác minh: giá ghi cứng ở màn chờ, thiếu đón deep link `smartwardrobe://`, thiếu toggle gia hạn. Xem chi tiết trong [research.md](./research.md), [data-model.md](./data-model.md), [contracts/billing-api.md](./contracts/billing-api.md), [quickstart.md](./quickstart.md).

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x

**Primary Dependencies**: `flutter_riverpod` 2.x (state), `go_router` 14.x (routing), `dio` 5.x + `http` (network/SSE), `flutter_secure_storage` (token), `url_launcher` 6.x (mở PayOS), `app_links` (mới — đón deep link, xem R-01), `google_fonts`, `intl`

**Storage**: Không thêm storage mới — token trong secure storage; trạng tháiephemeral trong Riverpod (`SubscriptionOverviewState.activePaymentLink`)

**Testing**: `flutter_test` + kiểm chứng tay theo `quickstart.md` (PayOS sandbox); `flutter analyze` phải sạch lỗi mới

**Target Platform**: Android + iOS (ưu tiên), Flutter Web (`--web-port=8081`) tương thích qua origin URL

**Project Type**: mobile-app (Flutter, feature-first: `lib/features/profile`, `lib/core/{network,router,theme}`)

**Performance Goals**: Phát hiện thanh toán thành công chậm nhất sau 1 chu kỳ polling (3s) kể từ khi backend xác nhận; màn nâng cấp mở dưới 2s sau đăng nhập

**Constraints**: PayOS `description` ≤ 25 ký tự (Gotcha 6, phía backend); không nhúng key thanh toán vào app; không tin query param deep link — xác thực duy nhất qua `GET /subscriptions/me`; file tiếng Việt viết UTF-8 (Gotcha 5)

**Scale/Scope**: 1 feature module (`profile`: 4 màn hình + provider/repository/model hiện có), ~6 file sửa + native config 2 platform + 1 dependency mới

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` của mobile là template chưa điền (placeholder), nên gate suy từ `PROJECT_AGENT_GUIDE.md` + nguyên tắc speckit:

- [x] Scope = full parity đã chốt với user (FR-010) — không phình thêm (wallet chi tiết ngoài nạp/mua là out of scope).
- [x] Không phá gotcha: giữ header `Accept-Encoding: identity`, đúng endpoint `/me/wardrobe-items` (không liên quan nhưng không đụng), bottom sheet/ListTile đúng quy tắc.
- [x] Bảo mật: token qua Bearer + secure storage, returnUrl custom scheme không lộ dữ liệu nhạy cảm.
- [x] Design: Quiet Luxury tokens + touch target ≥ 44px (qua skill `ui-ux-pro-max` khi implement).
- [x] Post-design re-check: research/data-model/contracts/quickstart nhất quán với spec, không phát sinh violation.

## Project Structure

### Documentation (this feature)

```text
specs/001-premium-payment-mobile/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
│   └── billing-api.md   # Backend API + deep link contract
├── checklists/
│   └── requirements.md  # Spec quality checklist
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
smart-wardrobe-mobile/
├── lib/
│   ├── core/
│   │   ├── network/        # api_client (Dio + Accept-Encoding: identity), sse_service
│   │   ├── router/         # app_router + deep-link handler mới (app_links stream)
│   │   └── theme/          # Quiet Luxury tokens
│   └── features/
│       └── profile/
│           ├── data/           # profile_repository (thêm toggleAutoRenew)
│           ├── providers/      # profile_provider (thêm auto-renew state)
│           ├── models/         # user_profile_models (đã đủ field)
│           └── presentation/   # subscription_detail/upgrade/waiting + topup_bottom_sheet
├── android/app/src/main/
│   └── AndroidManifest.xml     # thêm intent-filter smartwardrobe://
├── ios/Runner/
│   └── Info.plist              # thêm CFBundleURLSchemes
├── pubspec.yaml                # thêm app_links
└── test/
    └── widget/                 # test màn chờ (giá động), toggle gia hạn
```

**Structure Decision**: Giữ nguyên feature-first hiện có của mobile; deep-link handler đặt cạnh `app_router` để điều hướng GoRouter trực tiếp; không tạo module mới.

## Complexity Tracking

> Không có violation — không điền.
