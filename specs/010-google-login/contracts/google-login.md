# Contract: Mobile ↔ Backend — Google Login

**Feature**: `010-google-login` | **Date**: 2026-09-25
**Nguồn**: BE thật (`services/account` — `GoogleLoginReq`, `RefreshTokenReq`, `LogoutReq`, `TokenRes`) + `docs/google-login-frontend-guide.md`.

Base URL = `{API_BASE}/api/v1`. Dev: `API_BASE=http://localhost:8080` (web/desktop); Android emulator `http://10.0.2.2:8080`.

## 1. Đổi Google ID token lấy phiên

`POST /auth/google`

Headers: `Content-Type: application/json`

Request body:
```json
{ "idToken": "<google-id-token>", "deviceName": "Android" }
```

Response 200:
```json
{ "message": "...", "data": { "accessToken": "<jwt>", "refreshToken": "<jwt>" } }
```

- App lưu `accessToken` + `refreshToken` vào secure storage.
- Gọi `GET /me` (Bearer) để lấy hồ sơ (tái dùng luồng hiện có).

## 2. Làm mới phiên (refresh rotation)

`POST /auth/refresh-token`

Request body:
```json
{ "oldRefreshToken": "<refresh-token>", "deviceName": "Android" }
```
Response 200: `data: { accessToken, refreshToken }` (refresh token cũ bị thu hồi — **lưu token mới**).

- Kích hoạt khi API trả **401**; **single-flight**; retry request gốc 1 lần.
- Refresh thất bại → đăng xuất, về `/login`.

## 3. Đăng xuất

`POST /auth/logout`
Headers: `Authorization: Bearer <accessToken>`
Request body: `{ "refreshToken": "<refresh-token>" }`

- Sau khi gọi (kể cả lỗi), app **xoá token cục bộ** + reset session-scope.

## 4. Hồ sơ sau đăng nhập

`GET /me` — Bearer access token. Trả `data: { id, username, email, firstName, lastName, roleSlug, avatarUrl, ... }` (tái dùng `AuthRepository.getCurrentUser`).

## 5. Bảng lỗi

| Tình huống | HTTP | `error`/mã | App xử lý |
|---|---|---|---|
| Người dùng huỷ tại Google | — | `access_denied` (SDK) | Quay lại Đăng nhập, không báo lỗi nặng |
| Email Google chưa xác thực | 400 | message BE | Hiện message |
| Email trùng tài khoản chưa verify | 400 | `email_registered` | Gợi ý đăng nhập bằng mật khẩu |
| Email đã liên kết Google khác | 409 | `account_linked` | Hiện message |
| Tài khoản bị khoá | 403 | `account_disabled` | Thông báo liên hệ CSKH |
| Code/đổi phiên thất bại | 400 | `exchange_failed` | Thử lại |
| ID token sai/hết hạn | 400 | message BE | Yêu cầu thử lại |
| Lỗi hệ thống | 500 | server_error | Thử lại |
| Mất kết nối/timeout | — | DioException | "Không thể kết nối đến máy chủ" |
| **Auto-link thành công** | 200 | — | Hiện thông báo nhẹ (không chặn) |

BE luôn trả `message` tiếng Việt; app ưu tiên hiển thị message BE, fallback theo mã.

## 6. Cấu hình (ENV)

| Biến | Bắt buộc | Ý nghĩa |
|---|---|---|
| `API_BASE_URL` | có | Base API (đã có trong `.env`) |
| `API_BASE_URL_ANDROID` | có (Android) | Base API cho emulator |
| `GOOGLE_CLIENT_ID` | **mới** | Web/Server client id cho **dev (localhost:8080 / 10.0.2.2:8080)** |
| `GOOGLE_CLIENT_ID_PROD` | **mới** | Client id cho `https://api.closy.hycat.online` |
| `GOOGLE_CLIENT_ID_V2` | **mới** | Client id cho `https://api-v2.closy.hycat.online` |

**Bảng client ID theo môi trường** (app tự chọn theo host của `API_BASE_URL`):

| API host | ENV key | Client ID |
|---|---|---|
| `localhost:8080`, `10.0.2.2:8080` | `GOOGLE_CLIENT_ID` | `368645245473-u71cfbe461nl51us9dmlta6vfgcdun8a.apps.googleusercontent.com` |
| `api.closy.hycat.online` | `GOOGLE_CLIENT_ID_PROD` | `368645245473-5ovjq88e58p97u81asjssbt2bt8bnpt9.apps.googleusercontent.com` |
| `api-v2.closy.hycat.online` | `GOOGLE_CLIENT_ID_V2` | `368645245473-egk412r1rhc7s0iloms9e4mjh7bptsj3.apps.googleusercontent.com` |

Thứ tự chọn (hàm `AppConstants.googleClientId`): `--dart-define=GOOGLE_CLIENT_ID` (override) > theo host của `API_BASE_URL` > `GOOGLE_CLIENT_ID`. **Không hardcode trong mã.**

> Lý do phải theo môi trường: mỗi BE env verify một allow-list `GOOGLE_CLIENT_IDS` riêng; idToken phát hành cho client id của môi trường nào chỉ được BE môi trường đó chấp nhận.

## 7. Ghi chú nền tảng (v1: Android + Web)

- **Android**: nút tự vẽ + `GoogleSignIn.instance.authenticate()`; khởi tạo với `serverClientId` = **Web client id của môi trường** (guide §0: "nếu mobile dùng server client ID thì dùng `WEB_CLIENT_ID`"). `deviceName = "Android"` (guide §3.1 minh hoạ `Build.MODEL`; ta dùng hằng đơn giản — không đổi hợp đồng API).
- **Web (Chrome dev)**: nút **do SDK render** (`web.renderButton`) vì `supportsAuthenticate()` là `false`; khởi tạo với `clientId` = Web client id của môi trường; origin dev phải nằm trong Authorized JavaScript origins (Google Cloud — dependency). `deviceName = "Web"`.
- iOS: ngoài phạm vi v1.

## 8. Lưu trữ & header

- Storage keys: `sw_auth_token`, `sw_refresh_token` (đã có).
- Mọi API xác thực: `Authorization: Bearer <accessToken>` (interceptor hiện có).
