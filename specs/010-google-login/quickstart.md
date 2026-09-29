# Quickstart: Kiểm chứng Đăng nhập bằng Google

**Feature**: `010-google-login` | **Date**: 2026-09-25

Mục tiêu: chứng minh tính năng hoạt động end-to-end trên **Android** và **Web (Chrome dev)** với BE local. Chi tiết hợp đồng xem [contracts/google-login.md](./contracts/google-login.md); thực thể/logic xem [data-model.md](./data-model.md).

## 0. Điều kiện tiên quyết

- BE local chạy: `docker compose -f deployments/docker-compose.yml up -d` (nginx `:8080`). Đã xác minh `POST /api/v1/auth/google` tồn tại.
- Google Cloud đã cấu hình: OAuth client **Web** (client id dev) + Authorized JavaScript origins chứa origin web dev. (Dependency ngoài mã nguồn.)
- `.env` của app có `API_BASE_URL=http://localhost:8080/api/v1`, `API_BASE_URL_ANDROID=http://10.0.2.2:8080/api/v1`, và **`GOOGLE_CLIENT_ID`** (dev) / **`GOOGLE_CLIENT_ID_PROD`** / **`GOOGLE_CLIENT_ID_V2`** (xem `contracts/google-login.md` §6 — app tự chọn theo host `API_BASE_URL`).
- `flutter pub get` (dependencies gồm `google_sign_in`).

## 1. Lệnh chạy

```powershell
flutter pub get
flutter analyze
flutter test test\google_login_test.dart

# Web (Chrome dev) — CORS BE allow 8081/3000
flutter run -d chrome --web-port=8081

# Android (emulator/thiết bị)
flutter run
```

## 2. Kịch bản kiểm chứng

### QS-001 — Đăng nhập Google tài khoản mới (P1)
1. Mở app ở màn Đăng nhập trên Android hoặc Web.
2. Bấm **"Tiếp tục với Google"**, chọn một tài khoản Google chưa từng dùng với Closy.
3. **Kỳ vọng**: vào màn chính (Home) với phiên hợp lệ; `GET /me` trả đúng hồ sơ; không hiện lỗi. (FR-001..005)

### QS-002 — Auto-link tài khoản đã có (email đã xác thực) (P1)
1. Dùng email Google trùng với một tài khoản Closy đã tồn tại (đã xác thực).
2. Đăng nhập Google.
3. **Kỳ vọng**: vào **đúng tài khoản cũ** (không tạo trùng) + **thông báo nhẹ** về liên kết. (FR-006)

### QS-003 — Huỷ ở màn Google (P2)
1. Bấm Google rồi **đóng/huỷ** màn chọn tài khoản.
2. **Kỳ vọng**: quay lại màn Đăng nhập, **không** báo lỗi nghiêm trọng, nút bấm lại được. (FR-008, FR-012)

### QS-004 — Bảng lỗi (P2)
1. Thử các tài khoản/điều kiện: email Google chưa verify; email trùng tài khoản chưa verify; email đã liên kết Google khác; tài khoản bị khoá; idToken sai/hết hạn; BE tắt (mất kết nối).
2. **Kỳ vọng**: mỗi ca hiển thị **đúng thông báo tiếng Việt** tương ứng; không crash; cho thử lại. (FR-007)

### QS-005 — Tự làm mới token (P3)
1. Đăng nhập Google; để access token hết hạn (hoặc ép 401).
2. Thực hiện một thao tác cần xác thực (mở tủ đồ/hồ sơ).
3. **Kỳ vọng**: app tự refresh (single-flight), thao tác tiếp tục **không** bắt đăng nhập lại. Nếu refresh thất bại → tự đăng xuất về `/login`. (FR-009)

### QS-006 — Đăng xuất (P3)
1. Đăng nhập Google → bấm Đăng xuất.
2. **Kỳ vọng**: gọi `/auth/logout`; token bị xoá; trạng thái reset sạch (session-scope); về `/login`. Mở lại app → vẫn ở màn Đăng nhập. (FR-010)

### QS-007 — Khôi phục phiên khi mở lại app (P1)
1. Đăng nhập Google, đóng và mở lại app (token còn hiệu lực).
2. **Kỳ vọng**: vẫn ở trạng thái đã đăng nhập, không phải đăng nhập Google lại. (SC-005)

### QS-008 — Web redirect (Chrome dev) (P1)
1. `flutter run -d chrome --web-port=8081` (BE local chạy; `FRONT_END_ORIGIN` của BE có `http://localhost:8081`).
2. Bấm **"Tiếp tục với Google"** → trình duyệt rời app sang Google → chọn/đồng ý tài khoản.
3. **Kỳ vọng**: BE đặt cookie HttpOnly rồi redirect về `http://localhost:8081/auth/callback`; app gọi `GET /me` (kèm cookie) → vào Home.
4. **Thất bại**: BE redirect về kèm `?error=` → app hiển thị thông báo tiếng Việt tương ứng rồi về `/login`.
5. **Không cần "Authorized JavaScript origins"** (khác GIS) ⇒ không còn lỗi `400: origin_mismatch`.

## 3. Kết quả mong đợi tổng hợp

- Tất cả QS pass; `flutter analyze` 0 issues; test unit/widget liên quan pass.
- Không rò rỉ token/dữ liệu giữa các tài khoản (session reset đúng).
- Client ID lấy từ ENV, không hardcode; đổi ENV sang prod hoạt động mà không sửa code. (FR-011)

## 4. Ghi chú

- Web: nút Google **do SDK render** — nếu nút không hiện, kiểm tra Authorized JS origins và `GOOGLE_CLIENT_ID`.
- Android: nút tự vẽ + `authenticate()` — nếu lỗi, kiểm tra `serverClientId` và cấu hình OAuth Android/web client.
- iOS ngoài phạm vi v1.
