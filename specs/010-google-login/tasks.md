---
description: "Task list — Đăng nhập bằng Google (010-google-login)"
---

# Tasks: Đăng nhập bằng Google (Google Sign-In)

**Input**: Design documents from `specs/010-google-login/`

**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/google-login.md`, `quickstart.md`, `.specify/memory/constitution.md`

**Tests**: Có — bắt buộc theo DoD dự án (`flutter analyze` 0 issues + `flutter test` liên quan).

**Organization**: Task nhóm theo user story để mỗi story triển khai/kiểm thử độc lập.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Chạy song song được (khác file, không phụ thuộc task chưa xong)
- **[Story]**: US1 / US2 / US3 (ánh xạ spec.md)
- Mọi task có đường dẫn file cụ thể

## Path Conventions

Flutter feature-first: `lib/core/**`, `lib/features/auth/**`, `test/**`.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Thêm dependency, cấu hình client ID qua ENV, và điều kiện tiên quyết nền tảng.

- [X] T001 Add `google_sign_in: ^7.2.0` vào `pubspec.yaml` và chạy `flutter pub get`
- [X] T002 [P] Thêm `GOOGLE_CLIENT_ID` (dev/localhost), `GOOGLE_CLIENT_ID_PROD` (api.closy.hycat.online), `GOOGLE_CLIENT_ID_V2` (api-v2.closy.hycat.online) vào `.env` và placeholder (không chứa giá trị prod thật) vào `.env.example`
- [X] T003 [P] Thêm getter `AppConstants.googleClientId` trong `lib/core/constants/app_constants.dart`: ưu tiên `--dart-define=GOOGLE_CLIENT_ID` > chọn theo host `API_BASE_URL` (`localhost`/`10.0.2.2` → dev, `api.closy.hycat.online` → prod, `api-v2.closy.hycat.online` → v2) > `GOOGLE_CLIENT_ID`
- [X] T004 [P] Configure/verify **Google Cloud prerequisites cho từng môi trường**: OAuth client Web (authorized JavaScript origin dev + origin prod/v2) + OAuth Android cho package `com.smartwardrobe.smart_wardrobe`; ghi lại vào `docs/google-login-frontend-guide.md`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Model, đổi phiên, refresh rotation, wiring session — BẮT BUỘC xong trước mọi user story.

**⚠️ CRITICAL**: Không bắt đầu user story nào trước khi hoàn tất phase này.

- [X] T005 Thêm model/enum Google auth trong `lib/features/auth/models/auth_models.dart`: `GoogleLoginRequest` (idToken, deviceName), `GoogleSignInOutcome` (success, linkedExistingAccount, errorCode, message), `AuthErrorCode` enum (cancelled, emailUnverified, emailRegistered, accountLinked, accountDisabled, exchangeFailed, invalidToken, serverError, network) + parse `TokenRes` và map lỗi HTTP→mã
- [X] T006 [P] Thêm `refreshSession(oldRefreshToken, deviceName)` và chỉnh `logout()` (gửi body `{refreshToken}` + Bearer) trong `lib/features/auth/data/auth_repository.dart`
- [X] T007 Thêm `loginWithGoogle(idToken, deviceName)` trong `lib/features/auth/data/auth_repository.dart` (gọi `POST /auth/google`, lưu access/refresh token, trả `GoogleSignInOutcome`) — phụ thuộc T005, T006
- [X] T008 Cài interceptor 401 → refresh **single-flight** + callback forced-logout trong `lib/core/network/api_client.dart` (retry 1 lần; refresh fail → phát tín hiệu đăng xuất) — phụ thuộc T006
- [X] T009 Nối forced-logout vào `lib/features/auth/providers/auth_provider.dart` (refresh fail → `logout()` + bump `sessionProvider` + điều hướng `/login`) — phụ thuộc T008
- [X] T010 [P] Thêm unit test map lỗi HTTP/status → `AuthErrorCode`/message trong `test/google_login_test.dart`

**Checkpoint**: Nền tảng sẵn sàng — bắt đầu user story.

---

## Phase 3: User Story 1 - Đăng nhập/đăng ký bằng Google (Priority: P1) 🎯 MVP

**Goal**: Nút "Tiếp tục với Google" ở Login/Register → lấy ID token → đổi phiên → vào app; tạo tài khoản mới hoặc auto-link tài khoản cũ (thông báo nhẹ).

**Independent Test**: Bấm Google ở màn Đăng nhập, chọn tài khoản → vào màn chính với phiên hợp lệ (`GET /me` OK); tài khoản cũ được auto-link + thông báo nhẹ.

### Implementation for User Story 1

- [X] T011 [US1] Tạo widget `GoogleSignInButton` trong `lib/features/auth/presentation/widgets/google_sign_in_button.dart`: Android nút tự vẽ + `GoogleSignIn.instance.authenticate()`; Web dùng `web.renderButton(...)`; khởi tạo SDK với `clientId`/`serverClientId = AppConstants.googleClientId`; có loading + disable (FR-001, FR-002, FR-012)
- [X] T012 [US1] Thêm `loginWithGoogle()` vào `AuthNotifier` trong `lib/features/auth/providers/auth_provider.dart` (set `isLoading`, gọi repo, set `isAuthenticated`/`user`, xử lý `GoogleSignInOutcome`) — phụ thuộc T007, T009
- [X] T013 [P] [US1] Gắn `GoogleSignInButton` vào `lib/features/auth/presentation/login_screen.dart`; sau đăng nhập điều hướng `pendingRedirect` hoặc `/wardrobe` (FR-005)
- [X] T014 [P] [US1] Gắn `GoogleSignInButton` vào `lib/features/auth/presentation/register_screen.dart` (cùng hành vi)
- [X] T015 [US1] Hiển thị **thông báo nhẹ** (SnackBar) khi tài khoản được auto-link (`linkedExistingAccount`) tại `login_screen.dart`/`register_screen.dart` (FR-006)
- [X] T016 [P] [US1] Unit/widget test: nút Google render + loading disable + gọi `loginWithGoogle` trong `test/google_login_test.dart`

**Checkpoint**: US1 hoàn chỉnh và test độc lập được (MVP).

---

## Phase 4: User Story 2 - Xử lý lỗi & huỷ (Priority: P2)

**Goal**: Huỷ và mọi ca lỗi đều phản hồi tiếng Việt rõ ràng, không crash.

**Independent Test**: Mô phỏng từng mã lỗi/huỷ → thấy đúng thông báo, UI ổn định, nút bấm lại được.

### Implementation for User Story 2

- [X] T017 [US2] Hoàn thiện hiển thị lỗi + xử lý huỷ trong `lib/features/auth/providers/auth_provider.dart` và `lib/features/auth/presentation/login_screen.dart`/`register_screen.dart`: `cancelled` → quay lại không báo nặng; các lỗi còn lại theo bảng mã (FR-007, FR-008)
- [X] T018 [P] [US2] Mở rộng test: mỗi `AuthErrorCode` → message đúng, `cancelled` không set errorMessage, trong `test/google_login_test.dart`

**Checkpoint**: US1 + US2 hoạt động độc lập.

---

## Phase 5: User Story 3 - Duy trì phiên, refresh & đăng xuất (Priority: P3)

**Goal**: Phiên bền vững, tự refresh khi 401, refresh fail thì đăng xuất; logout thu hồi + xoá token + reset state; phiên khôi phục khi mở lại app.

**Independent Test**: Ép access token hết hạn → app tự refresh (không bắt đăng nhập lại); refresh fail → về `/login`; logout → token bị thu hồi/xoá; mở lại app vẫn phiên cũ.

### Implementation for User Story 3

- [X] T019 [US3] Hoàn thiện luồng refresh fail → đăng xuất an toàn + điều hướng `/login` (ràng buộc auth guard) — `lib/core/network/api_client.dart`, `lib/features/auth/providers/auth_provider.dart`
- [X] T020 [US3] Hoàn thiện `logout()` thu hồi refresh token + xoá token + reset session-scope trong `lib/features/auth/data/auth_repository.dart` và `lib/features/auth/providers/auth_provider.dart` (FR-010)
- [X] T021 [P] [US3] Unit test: refresh single-flight (nhiều 401 → 1 refresh) + refresh fail → logout, trong `test/google_login_test.dart`
- [X] T022 [US3] Thêm ca Google vào integration test (đổi `idToken` thật/skip khi thiếu) trong `test/auth_integration_test.dart`
- [X] T023 [US3] Verify **khôi phục phiên Google khi mở lại app** (token còn hạn → vẫn đăng nhập, không bắt đăng nhập lại): thêm ca test trong `test/google_login_test.dart` (dùng `checkAuthStatus`) + đối chiếu QS-007 (SC-005)

**Checkpoint**: Toàn bộ user story hoạt động độc lập.

---

## Phase 6: Polish & Cross-Cutting Concerns

- [X] T024 [P] Cập nhật `.env.example` + ghi chú cấu hình Google Cloud (authorized origins / Android client) trong `docs/google-login-frontend-guide.md`
- [X] T025 Chạy `flutter analyze` (0 issues) và `flutter test` liên quan; sửa mọi vấn đề
- [X] T026 Chạy `quickstart.md` QS-001..**QS-008** trên **Chrome (web)** và **Android**; ghi kết quả (các mục QA redirect của guide §5 là **N/A** với luồng GIS)
- [X] T027 [P] Cập nhật `docs/work-log-<yyyy-mm-dd>.md` (spec 010, task xong/còn, file mới/sửa, việc cần user)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: không phụ thuộc — bắt đầu ngay (T004 là prerequisite chặn QS thủ công T026)
- **Foundational (Phase 2)**: phụ thuộc Setup — **CHẶN** mọi user story
- **User Stories (Phase 3+)**: đều phụ thuộc Foundational; song song nếu đủ người, hoặc tuần tự P1→P2→P3
- **Polish (Phase 6)**: sau khi các story mong muốn xong

### User Story Dependencies

- **US1 (P1)**: sau Foundational — độc lập. Cần T011–T012 (button + notifier).
- **US2 (P2)**: sau Foundational — hoàn thiện xử lý lỗi quanh US1 (`loginWithGoogle` + UI).
- **US3 (P3)**: sau Foundational — dùng interceptor/wiring T008–T009; logic độc lập với US1/US2.

### Within Each User Story

- Model trước service/repository; repository trước notifier; notifier trước UI; core trước tích hợp.

### Parallel Opportunities

- T002, T003, T004 (Setup) song song
- T006 và T010 (Foundational) song song
- T013, T014 (US1 UI) song song; T016 song song
- T018, T021 (tests) song song ở phase tương ứng
- T024, T027 (Polish) song song

---

## Parallel Example: User Story 1

```bash
# UI 2 màn song song:
Task: "T013 [US1] Gắn GoogleSignInButton vào login_screen.dart"
Task: "T014 [US1] Gắn GoogleSignInButton vào register_screen.dart"
Task: "T016 [US1] Test nút Google + loading trong test/google_login_test.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1)

1. Phase 1 Setup → Phase 2 Foundational (CRITICAL)
2. Phase 3 US1 → **DỪNG & KIỂM CHỨNG** độc lập (QS-001, QS-002, QS-007, QS-008)
3. Demo/deploy nếu sẵn sàng

### Incremental Delivery

1. Setup + Foundational → nền tảng
2. US1 → test (QS-001/002/007/008) → demo (MVP)
3. US2 → test lỗi/huỷ (QS-003/004) → demo
4. US3 → test refresh/logout/restore (QS-005/006/007) → demo
5. Polish: analyze/test + QS đầy đủ + work-log

---

## Notes

- [P] = khác file, không phụ thuộc
- Không hardcode client ID; luôn qua ENV (T002/T003)
- Web dùng nút do SDK render; Android nút tự vẽ (T011)
- iOS ngoài phạm vi v1
- Tuân thủ constitution: no-mock, Quiet Luxury UI, UTF-8 khi sửa file
- T004 (prerequisite Google Cloud) là dependency ngoài mã nguồn — cần xong trước khi chạy QS thủ công (T026)

---

## Phase 7: Convergence

- [X] T028 Hiển thị thông báo auto-link khi đăng nhập Google **trên web** (FR-006, partial): `AuthCallbackScreen` đọc cờ liên kết do BE trả khi redirect về (đề xuất `?linked=1`) và hiện SnackBar không chặn; nếu BE chưa trả cờ, phối hợp BE bổ sung — file `lib/features/auth/presentation/auth_callback_screen.dart`
- [X] T029 Thêm test cho luồng web redirect (plan: web redirect, partial): `AppConstants.googleWebRedirectUrl` tạo đúng `.../auth/google?redirectUrl=<origin>/auth/callback`; `AuthCallbackScreen` xử lý `?error=` → message + điều hướng `/login` — file `test/google_login_test.dart`
- [X] T030 Đồng bộ đích điều hướng sau đăng nhập giữa `login_screen` và `auth_callback_screen` (FR-005, partial): thống nhất dùng `pendingRedirect` hoặc cùng một đích mặc định — file `lib/features/auth/presentation/login_screen.dart`, `lib/features/auth/presentation/auth_callback_screen.dart`
- [X] T031 Dọn dependency không còn dùng trực tiếp sau khi web chuyển sang redirect (plan, unrequested): gỡ `google_sign_in_web`, `google_sign_in_platform_interface` khỏi `pubspec.yaml` nếu không cần khai báo tường minh (hoặc thêm ghi chú lý do giữ) — file `pubspec.yaml`

---

## Phase 8: Convergence

- [X] T032 Đảm bảo SSE phân tích tủ đồ và chat stream hoạt động với **phiên cookie web** (plan: web session, partial): `sse_service.dart` và `stylist_repository.dart` cần gửi credentials (cookie) trên web (vd `BrowserClient(withCredentials)` cho `package:http`) và không gửi `?token=web_session_active`; kiểm chứng trên `POST /auth/google` web session — file `lib/core/network/sse_service.dart`, `lib/features/stylist/data/stylist_repository.dart`
- [X] T033 Xử lý 401 cho phiên cookie web một cách rõ ràng (FR-009, plan: web session, partial): khi không có refresh token (web), tránh forced-logout nhầm — thống nhất hành vi "hết phiên → về /login" và ghi chú giới hạn refresh của web — file `lib/core/network/api_client.dart`
