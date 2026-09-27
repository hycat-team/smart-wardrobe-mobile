# Phase 1 Data Model: Đăng nhập bằng Google

**Feature**: `010-google-login` | **Date**: 2026-09-25

Không tạo bảng/migration mới (BE đã có). Dưới đây là các thực thể/logic phía app.

## Entities

### GoogleIdentity (tạm thời, không lưu)

| Field | Type | Ghi chú |
|---|---|---|
| `idToken` | `String` | Danh tính Google lấy từ SDK; gửi 1 lần tới BE, **không** lưu cục bộ |

- Nguồn: Android (`serverClientId`) / Web (GIS button). iOS ngoài scope.
- Ràng buộc: không rỗng (nếu rỗng → huỷ/lỗi, không gọi BE).

### ClosySession

| Field | Type | Ghi chú |
|---|---|---|
| `accessToken` | `String` | JWT; validate đủ 3 phần trước khi lưu |
| `refreshToken` | `String` | Dùng để làm mới phiên; lưu secure |

- Storage keys (đã có): `sw_auth_token`, `sw_refresh_token` (`AppConstants`).
- Ràng buộc: access token phải đủ 3 phần `header.payload.signature` (tái dùng `SecureStorageService`/`AuthRepository`).

### GoogleSignInOutcome (kết quả trả về cho UI)

| Field | Type | Ghi chú |
|---|---|---|
| `success` | `bool` | Đăng nhập thành công hay không |
| `linkedExistingAccount` | `bool` | `true` khi email Google đã liên kết vào tài khoản cũ → UI hiển thị thông báo nhẹ (FR-006) |
| `errorCode` | `AuthErrorCode?` | Có khi `success == false` |
| `message` | `String?` | Message tiếng Việt để hiển thị (ưu tiên message BE) |

### AuthErrorCode (enum)

| Giá trị | Nguồn | Ý nghĩa / UI |
|---|---|---|
| `cancelled` | SDK (người dùng huỷ) | Quay lại màn Đăng nhập, **không** báo lỗi nặng (FR-008) |
| `emailUnverified` | 400 `email_unverified` | "Email Google chưa được xác thực." |
| `emailRegistered` | 400 `email_registered` | "Email đã được đăng ký. Vui lòng đăng nhập bằng mật khẩu." |
| `accountLinked` | 409 `account_linked` | "Email đã liên kết với tài khoản Google khác." |
| `accountDisabled` | 403 `account_disabled` | Tài khoản bị vô hiệu hoá — liên hệ CSKH |
| `exchangeFailed` | 400 `exchange_failed` | "Không hoàn tất được đăng nhập, vui lòng thử lại." |
| `invalidToken` | 400 (token sai/hết hạn) | "Phiên Google không hợp lệ, thử lại." |
| `serverError` | 500 | "Có lỗi xảy ra, vui lòng thử lại sau." |
| `network` | DioException connection/timeout | "Không thể kết nối đến máy chủ." |

### AuthState (mở rộng, hiện có)

- Tái dùng `isLoading` cho trạng thái đang đăng nhập Google (nút hiển thị spinner, disable — FR-012).
- Không thêm trường bắt buộc mới; nếu thêm phải có default (null-safety, constitution II).

## State transitions (luồng đăng nhập Google)

```text
Unauthenticated
  → [bấm Google, SDK mở] → AcquiringIdentity
      ├─ người dùng huỷ → Unauthenticated (không lỗi nặng)
      └─ có idToken → ExchangingWithBackend
            ├─ 200 TokenRes → save session → Authenticated (+ notice nếu auto-link)
            └─ lỗi (map AuthErrorCode) → Unauthenticated (hiện message)

Authenticated
  → [API trả 401] → Refreshing
      ├─ refresh OK → retry request → Authenticated
      └─ refresh fail → Logout → Unauthenticated (/login)
  → [đăng xuất] → revoke + clear token + bump session → Unauthenticated
```

## Validation rules (từ FR)

- **FR-002/003**: chỉ gọi BE khi có `idToken` không rỗng.
- **FR-004**: chỉ lưu token khi access token đúng định dạng JWT 3 phần.
- **FR-006**: `linkedExistingAccount` bật thông báo nhẹ, không chặn luồng.
- **FR-009**: refresh phải single-flight; thất bại → đăng xuất.
- **FR-010**: đăng xuất revoke + xoá token + reset state/session.
- **FR-011**: client ID lấy từ ENV, không hardcode.
