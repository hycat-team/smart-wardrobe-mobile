# Phase 0 Research: Đăng nhập bằng Google

**Feature**: `010-google-login` | **Date**: 2026-09-25

Mọi `NEEDS CLARIFICATION` trong Technical Context đã được giải quyết. Các quyết định dưới đây dựa trên: source code hiện tại của app, hợp đồng BE thật (`POST /auth/google`, `POST /auth/refresh-token`, `POST /auth/logout` đã xác minh trên BE local), và tài liệu chính thức của `google_sign_in`.

---

## R1 — Thư viện Google Sign-In

- **Decision**: Dùng `google_sign_in: ^7.2.0` (federated plugin: android/ios/web), hỗ trợ Android SDK 21+ và Web.
- **Rationale**: Là plugin chính thức của flutter.dev, hỗ trợ đúng 2 nền tảng trong phạm vi v1 (Android + Web); API v7 gom về `GoogleSignIn.instance` với `initialize()/authenticate()/authenticationEvents` (thay cho API cũ `GoogleSignIn()`).
- **Alternatives considered**: `google_sign_in` 6.x (API cũ, đang bị thay thế); tự viết platform channel (chi phí lớn, không cần thiết); `google_sign_in_web` trực tiếp (không đủ cho Android).

## R2 — Khác biệt luồng theo nền tảng

- **Decision**: **Android** native: nút tự vẽ + `GoogleSignIn.instance.authenticate()` → ID token → `POST /auth/google` (Bearer). **Web** dùng **luồng redirect do BE điều khiển (guide §1)**: điều hướng tới `GET {API_BASE}/auth/google?redirectUrl=<origin>/auth/callback`; BE đặt cookie HttpOnly rồi quay về `/auth/callback`; app xác nhận phiên qua `GET /me` (kèm cookie).
- **Rationale**: Luồng redirect **không cần "Authorized JavaScript origins"** → tránh `400: origin_mismatch` (đã gặp thực tế khi origin dev chưa đăng ký); cũng là luồng guide §1 khuyến nghị.
- **Alternatives considered**: GIS ID token (§2) — yêu cầu Authorized JavaScript origins nên bị chặn ở dev; đã bỏ để chuyển sang redirect.

## R3 — Cấu hình Client ID theo môi trường (ENV)

- **Decision**: Client ID (loại **Web/Server**) **phụ thuộc môi trường backend**, vì mỗi BE env verify danh sách `GOOGLE_CLIENT_IDS` riêng — idToken phát hành cho client id nào thì chỉ BE của môi trường đó chấp nhận:

  | API host | ENV key | Client ID |
  |---|---|---|
  | `localhost:8080` / `10.0.2.2:8080` (dev) | `GOOGLE_CLIENT_ID` | `368645245473-u71cfbe461nl51us9dmlta6vfgcdun8a.apps.googleusercontent.com` |
  | `api.closy.hycat.online` | `GOOGLE_CLIENT_ID_PROD` | `368645245473-5ovjq88e58p97u81asjssbt2bt8bnpt9.apps.googleusercontent.com` |
  | `api-v2.closy.hycat.online` | `GOOGLE_CLIENT_ID_V2` | `368645245473-egk412r1rhc7s0iloms9e4mjh7bptsj3.apps.googleusercontent.com` |

  `AppConstants.googleClientId` chọn theo thứ tự: `--dart-define=GOOGLE_CLIENT_ID` (override) > theo host của `API_BASE_URL` > `GOOGLE_CLIENT_ID` (dev). **Android** dùng giá trị này làm `serverClientId`; **Web không cần client id** (BE xử lý OAuth trong luồng redirect).
- **Rationale**: Đổi môi trường chỉ cần đổi ENV, không sửa code; khớp allow-list `GOOGLE_CLIENT_IDS` của từng BE env (dev/prod/v2).
- **Alternatives considered**: Dùng một ID chung cho mọi môi trường (sai — BE mỗi env có allow-list riêng); hardcode (bị cấm bởi constitution); tách nhiều ID theo nền tảng iOS/Android (iOS ngoài scope, Android dùng Web client id làm serverClientId).

## R4 — Đổi ID token lấy phiên Closy

- **Decision**: `POST {API_BASE}/api/v1/auth/google` với body `{ "idToken": <string>, "deviceName": <string> }` → `data: { accessToken, refreshToken }`. Lưu cả hai vào `flutter_secure_storage` (validate JWT access token đủ 3 phần như hiện có).
- **Rationale**: Khớp `GoogleLoginReq`/`TokenRes` của BE; tái dùng `SecureStorageService` hiện có.
- **Alternatives considered**: Luồng redirect cookie (ngoài phạm vi v1).

## R5 — Refresh rotation (FR-009, dùng chung mọi luồng)

- **Decision**: Thêm interceptor trong `ApiClient`: khi gặp 401, **single-flight** gọi `POST /auth/refresh-token {oldRefreshToken, deviceName}` → cập nhật token mới → **retry** request gốc 1 lần. Nếu refresh thất bại → buộc đăng xuất (bump `sessionProvider`, xoá token) và đưa về `/login`.
- **Rationale**: Hiện `ApiClient` mới có TODO cho 401; token sống ~60 phút nên không refresh sẽ đăng xuất ngoài ý muốn. Single-flight tránh nhiều request refresh đồng thời.
- **Alternatives considered**: Chỉ logout khi 401 (loại ở clarification Q3); dùng package `dio` retry sẵn (không phù hợp vì cần logic refresh token riêng).

## R6 — Bảng lỗi & thông báo tiếng Việt

- **Decision**: Map lỗi theo `docs/google-login-frontend-guide.md` §4: `access_denied` (huỷ → im lặng/quay lại), `email_unverified` (400), `email_registered` (400), `account_linked` (409), `account_disabled` (403), `exchange_failed` (400), token không hợp lệ (400), lỗi hệ thống (500), mất kết nối. Hiển thị message BE (tiếng Việt) nếu có, fallback theo mã.
- **Rationale**: Bảo đảm thông báo rõ ràng, không crash, không liên kết nhầm.
- **Alternatives considered**: Hiển thị nguyên message BE cho mọi ca (không xử lý riêng "huỷ" sẽ gây cảnh báo sai).

## R7 — Tên thiết bị (`deviceName`)

- **Decision**: Gửi nhãn đơn giản theo nền tảng: Web → `"Web"`, Android → `"Android"`. Không thêm dependency `device_info_plus` trong v1.
- **Rationale**: BE chỉ cần định danh phiên; tránh thêm plugin ngoài phạm vi.
- **Alternatives considered**: `device_info_plus` (giá trị thấp, thêm phụ thuộc — cân nhắc sau).

## R8 — Phụ thuộc Google Cloud & BE (ngoài mã nguồn)

- **Decision**: Coi việc cấu hình Google Cloud là **dependency**: (a) Google Cloud có **OAuth client Web** với Authorized JavaScript origins chứa origin dev của Flutter web; (b) Android dùng chung Web client id làm `serverClientId` (không cần SHA-1 nếu chỉ lấy ID token qua serverClientId, nhưng cần thiết lập theo README `google_sign_in_android`); (c) BE đã cấu hình `GOOGLE_CLIENT_IDS`.
- **Rationale**: Đã xác minh `POST /api/v1/auth/google` tồn tại (HTTP 400 khi body rỗng) trên BE local.
- **Alternatives considered**: Mock BE (bị cấm bởi constitution III).

## R9 — Tích hợp state & điều hướng

- **Decision**: Thêm `AuthNotifier.loginWithGoogle()` trả `Future<bool>` + cờ `isLoading`; tái dùng `pendingRedirectProvider` để quay lại đích đến sau đăng nhập; auto-link hiển thị `SnackBar`/thông báo nhẹ (không chặn).
- **Rationale**: Đồng nhất với `login()` hiện có; giữ hành vi điều hướng/session-scope.
- **Alternatives considered**: Tạo provider riêng cho Google (dư thừa).

---

**Output**: Tất cả `NEEDS CLARIFICATION` đã được giải quyết; sẵn sàng cho Phase 1.
