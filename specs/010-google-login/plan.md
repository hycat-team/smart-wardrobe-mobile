# Implementation Plan: Đăng nhập bằng Google (Google Sign-In)

**Branch**: `010-google-login` | **Date**: 2026-09-25 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/010-google-login/spec.md`

## Summary

Bổ sung đăng nhập/đăng ký bằng Google cho app Flutter (Android + Web dev), dùng **google_sign_in ^7.2.0** để lấy **ID token**, rồi đổi lấy phiên Closy (access/refresh token) qua **`POST /auth/google`** của BE (`http://localhost:8080` ở dev). Kèm theo: tự động **làm mới token (refresh rotation)** dùng chung cho mọi luồng đăng nhập (interceptor 401 trong `ApiClient`), xử lý bảng lỗi tiếng Việt, thông báo nhẹ khi tài khoản được auto-link. **Google Client ID cấu hình theo môi trường qua ENV** (`GOOGLE_CLIENT_ID` cho dev, `GOOGLE_CLIENT_ID_PROD`, `GOOGLE_CLIENT_ID_V2` — app tự chọn theo host `API_BASE_URL`). iOS ngoài phạm vi v1.

> **Guide alignment** (`docs/google-login-frontend-guide.md`):
> - Web dùng **luồng redirect do BE điều khiển (guide §1 – khuyến nghị)**: nút web điều hướng tới `GET {API_BASE}/auth/google?redirectUrl=<origin>/auth/callback`; BE đặt cookie HttpOnly rồi quay về `/auth/callback` (app gọi `GET /me` để xác nhận). **Không dùng GIS** — GIS đòi "Authorized JavaScript origins" nên gặp `400: origin_mismatch` khi origin dev chưa đăng ký.
> - Android vẫn native: lấy **ID token** → `POST /auth/google` → Bearer.
> - QA web: `quickstart.md` **QS-008**.
> - Endpoint/refresh/logout/bảng lỗi khớp guide §3.3–§4. Tham chiếu hợp đồng backend: `docs/google-login-frontend-guide.md` + spec BE/FE `021-google-login`.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x (`sdk: '>=3.0.0 <4.0.0'`)

**Primary Dependencies**: `flutter_riverpod ^2.5.1`, `go_router ^14.2.0`, `dio ^5.4.3`, `flutter_secure_storage ^9.2.2`, `flutter_dotenv ^5.2.1`; **mới: `google_sign_in ^7.2.0`** (flutter.dev; Android SDK 21+, Web)

**Storage**: `flutter_secure_storage` cho token (access/refresh); `.env` cho cấu hình (client ID, base URL)

**Testing**: `flutter_test` (unit/widget với `ProviderScope` overrides); integration test gọi BE local (mẫu `test/auth_integration_test.dart`)

**Target Platform**: Android (minSdk 21+) + Web (Chrome dev). iOS ngoài phạm vi v1.

**Project Type**: mobile-app (Flutter, feature-first layered: `lib/core` → `lib/features/<domain>/{models,data,providers,presentation}` → `lib/shared`)

**Performance Goals**: hoàn tất đăng nhập Google < 30 giây (SC-001); không chặn UI thread khi lấy token/đổi phiên.

**Constraints**: Mô hình phiên **Bearer** (không cookie); refresh rotation bắt buộc (FR-009); **client ID theo môi trường** (dev/prod/v2) qua ENV, không hardcode/không commit giá trị prod; release flag `ENABLE_PAID_FEATURES` không đổi; giữ `kotlin.incremental=false` (KT-66598).

**Scale/Scope**: Nhỏ gọn — 2 màn UI (Login/Register) + 1 thông báo nhẹ; chạm `lib/features/auth/**`, `lib/core/network/api_client.dart`, `lib/core/constants/app_constants.dart`, `pubspec.yaml`, `.env(.example)`, Android/Web config.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Nguyên tắc (constitution) | Trạng thái | Ghi chú |
|---|---|---|
| I. Spec-Driven & Verify-First | PASS | Đi qua `/speckit.specify → clarify → plan`; kết thúc bằng analyze/test + work-log |
| II. Feature-First Layered & Riverpod | PASS | Đặt logic ở `lib/features/auth/**`; dùng `Repository → Dio`; `ref.watch`/`ref.read`; state null-safe |
| III. Không Mock Khi Đã Có API | PASS | Gọi thẳng endpoint BE thật (`/auth/google`, `/auth/refresh-token`, `/auth/logout`); không bịa endpoint |
| IV. Quiet Luxury & Media | PASS | Nút Google theo palette hiện có; không dùng màu thuần; không ảnh hưởng media |
| V. Gotcha Windows & Build | PASS | Giữ UTF-8 khi sửa file; không đổi `kotlin.incremental=false` |
| VI. An Toàn Phát Hành & Secrets | PASS | `GOOGLE_CLIENT_ID` qua ENV/`--dart-define`, không hardcode; không commit secrets; không đổi release flag |

**Kết luận**: Không có vi phạm — không cần Complexity Tracking.

**Re-check sau Phase 1 (design)**: vẫn **PASS** — data-model/contracts/quickstart không phát sinh vi phạm: không mock BE (III), client ID qua ENV không hardcode (VI), mô hình Bearer thống nhất Android+Web, refresh single-flight làm ở `core/network` (II), không đụng media/palette (IV).

## Project Structure

### Documentation (this feature)

```text
specs/010-google-login/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── google-login.md
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── constants/app_constants.dart      # + googleClientId (dart-define > .env)
│   ├── network/api_client.dart           # + interceptor 401 → refresh rotation
│   └── ...
├── features/auth/
│   ├── data/auth_repository.dart         # + loginWithGoogle, refreshSession, logout
│   ├── models/auth_models.dart           # + GoogleLoginResponse/AuthErrorCode/SignInOutcome
│   ├── providers/auth_provider.dart      # + loginWithGoogle(), refresh/logout wiring
│   └── presentation/
│       ├── login_screen.dart             # + nút "Tiếp tục với Google"
│       ├── register_screen.dart          # + nút "Tiếp tục với Google"
│       └── widgets/google_sign_in_button.dart   # (mới) Android custom + Web SDK button
└── ...

test/
├── auth_integration_test.dart            # + ca Google (endpoint thật)
└── google_login_test.dart                # (mới) unit: error mapping, refresh single-flight
```

**Structure Decision**: Giữ kiến trúc feature-first hiện có; toàn bộ tính năng nằm trong `lib/features/auth/`, phần dùng chung (refresh interceptor, config) đặt ở `lib/core/`. Không tạo module mới.

## Complexity Tracking

> Không có vi phạm constitution — bảng này để trống.
