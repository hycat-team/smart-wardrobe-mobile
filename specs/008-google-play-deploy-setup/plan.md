# Implementation Plan: Google Play Deploy Setup

**Branch**: `008-google-play-deploy-setup` | **Date**: 2026-09-19 | **Spec**: specs/008-google-play-deploy-setup/spec.md

**Input**: Feature specification from `/specs/008-google-play-deploy-setup/spec.md`

## Summary

Đưa app Flutter (Android) lên Google Play theo 3 chặng: (1) cấu hình release đúng — application ID production, version, upload keystore + Gradle signing Kotlin DSL, API HTTPS thật, tắt cleartext, ẩn luồng trả phí kỹ thuật số — build AAB và phát lên Internal Testing; (2) hoàn tất hồ sơ cửa hàng + khai báo bắt buộc; (3) Closed Testing 12 tester × 14 ngày (tài khoản Personal mới) → Production access → Production release. Không đổi backend. Thay đổi chính nằm ở `android/` (signing + manifest), `lib/core/constants` (API config), entry point trả phí (feature flag), `.gitignore`, và tài liệu vận hành. Xem `research.md`, `data-model.md`, `contracts/`, `quickstart.md`.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x; Android Gradle (Kotlin DSL) với Java 17

**Primary Dependencies**: Flutter Gradle plugin, `flutter_dotenv`, `dio`, `app_links`, `url_launcher`; công cụ build: `flutter build appbundle`, JDK `keytool` (theo Flutter)

**Storage**: N/A (app dùng backend + `flutter_secure_storage`); artifact build ghi ra `build/app/outputs/`

**Testing**: `flutter analyze` sạch + `flutter test` baseline; release APK smoke test trên máy thật; manual QS-001→006 đối chiếu Play Console

**Target Platform**: Android (Google Play), minSdk/targetSdk theo Flutter mặc định

**Project Type**: mobile-app (single Flutter project) — release/ops configuration, không phải feature UI

**Performance Goals**: Build release thành công; cài/mở không crash; kết nối API production < 5s (mạng ổn định)

**Constraints**: Application ID chốt một lần (không đổi sau khi publish); `versionCode` tăng mỗi lần upload; không commit keystore/key.properties; release không dùng cleartext; bản Play đầu tiên ở chế độ miễn phí (không thu tiền kỹ thuật số); Android-only

**Scale/Scope**: ~8 file sửa trong repo + tài liệu; 3 user story; công việc Play Console là thủ công (không code); phụ thuộc điều kiện 12 tester × 14 ngày

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` vẫn là template placeholder → không có gate chính thức.

Gotcha/compliance tự áp:
- Không đổi backend/API contract; không thêm dependency runtime (chỉ có thể thêm dev-tooling icon/splash — cần cân nhắc).
- Thay đổi `app_constants.dart` phải giữ hành vi debug/local; chỉ siết release.
- Ẩn luồng trả phí phải không phá luồng đăng nhập/AI quota miễn phí; có thể bật lại sau.
- Bảo mật: keystore + mật khẩu ngoài repo; `.gitignore` cập nhật; không log secrets.

Post-design re-check: thay đổi chỉ ở cấu hình build/manifest/entry-point + tài liệu → passes. Complexity Tracking chỉ dùng nếu thêm dev-tooling icon/splash.

## Project Structure

### Documentation (this feature)

```text
specs/008-google-play-deploy-setup/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── release-config.md
│   └── play-listing.md
└── tasks.md             # Phase 2 output (NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
android/
├── app/build.gradle.kts                 # signingConfigs.release từ key.properties (Kotlin DSL)
├── app/src/main/AndroidManifest.xml     # bỏ usesCleartextTraffic; giữ deep-link scheme
├── app/src/debug/AndroidManifest.xml    # (thêm) cho phép cleartext chỉ ở debug/local
├── key.properties                       # (mới, KHÔNG commit) storeFile/passwords/alias
└── app/src/main/res/mipmap-*/ic_launcher.png  # icon thương hiệu (thay icon Flutter mặc định)

lib/
├── core/constants/app_constants.dart    # API_BASE_URL qua --dart-define; fail-fast release, bỏ [IP_ADDRESS]
├── core/config/release_flags.dart       # (mới) cờ ENABLE_PAID_FEATURES (compile-time)
├── core/router/app_router.dart          # chặn route wallet/subscription khi cờ tắt
└── features/profile/presentation/
    ├── profile_screen.dart              # ẩn mục Ví/Gói hội viên khi cờ tắt
    └── widgets/closy_wallet_card.dart   # ẩn thẻ ví khi cờ tắt

.gitignore                               # thêm android/key.properties, *.jks, *.keystore
pubspec.yaml                             # version 1.0.0+1; (tùy chọn) dev-tooling icon/splash
docs/                                    # privacy policy + hướng dẫn release (tài liệu vận hành)
```

**Structure Decision**: Single Flutter project, sửa tại chỗ (không tạo module mới). Phần lớn công việc là cấu hình `android/` + một feature flag nhỏ ở `lib/core` và 2 điểm UI profile; phần Play Console là checklist thủ công.

## Phases (for /speckit-tasks)

- **Phase A (P1 — US1)**: Release config & signed AAB → Internal Testing.
  - A1: Chốt application ID (giữ `com.smartwardrobe.smart_wardrobe`) + version `1.0.0+1`.
  - A2: Tạo upload keystore; `android/key.properties`; Gradle signing Kotlin DSL; giữ debug nguyên.
  - A3: `.gitignore` chặn `key.properties`/`*.jks`/`*.keystore`; xác minh `git status` sạch.
  - A4: API HTTPS qua `--dart-define API_BASE_URL`; fail-fast khi release còn `[IP_ADDRESS]`; bỏ `usesCleartextTraffic` (cleartext chỉ ở debug).
  - A5: Feature flag ẩn Ví/Gói hội viên + chặn route/deep-link thanh toán.
  - A6: Build AAB + release APK; smoke test checklist chức năng trên máy thật.
  - A7: Tạo app trên Play Console; upload AAB lên Internal Testing; mời tester nội bộ.
- **Phase B (P2 — US2)**: Store listing & khai báo bắt buộc.
  - B1: Icon/feature graphic/screenshots + mô tả ngắn/dài.
  - B2: Privacy policy công khai + Data Safety (khớp hành vi thật, có mã hóa khi truyền).
  - B3: Content rating, target audience, Ads declaration.
  - B4: App access + tài khoản test cho reviewer.
- **Phase C (P3 — US3)**: Closed Testing → Production.
  - C1: Closed Testing track + mời 15–20 tester, đảm bảo opt-in.
  - C2: Duy trì ≥ 12 tester opt-in liên tục 14 ngày (theo dõi).
  - C3: Apply Production access (trả lời trung thực).
  - C4: Production release + rollout + theo dõi Google review.
- **Phase D**: Final release checklist + hồi quy (credentials không lọt git, versionCode tăng).

## Complexity Tracking

> Chỉ điền nếu thêm dev-tooling (flutter_launcher_icons/flutter_native_splash) vào `pubspec.yaml`.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| (tùy chọn) thêm dev dependency icon/splash | Tạo bộ icon/feature graphic đúng chuẩn Play | Thay PNG thủ công dễ sai kích thước/adaptive icon; chấp nhận nếu đội muốn zero-dep |
