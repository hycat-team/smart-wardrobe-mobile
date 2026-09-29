# Quickstart: Kiểm chứng 012 — Community Home, Bulk Add, Catalog & Google Login

**Feature**: `012-community-nav-catalog` | **Date**: 2026-09-27

Hợp đồng: [contracts/ui-behavior-contracts.md](./contracts/ui-behavior-contracts.md); state: [data-model.md](./data-model.md).

## 0. Điều kiện

- BE local chạy (`docker compose ... up -d`, nginx `:8080`), có wardrobe/system-catalog/auth.
- `.env`: `API_BASE_URL=http://localhost:8080/api/v1` (+ Android `10.0.2.2`).
- `flutter pub get`.

## 1. Lệnh

```powershell
flutter pub get
flutter analyze
flutter test test\nav_test.dart test\upload_bulk_test.dart test\auth_google_test.dart

flutter run -d chrome --web-port=8081   # Web (Google cần Authorized JS origin)
flutter run                              # Android
```

## 2. Kịch bản

### QS-001 — Điều hướng Community (US1)
1. Mở app → thanh dưới là **[Tủ đồ, Cộng đồng, Phối đồ AI, Stylist AI, Hồ sơ]**, **không có Home**.
2. Bấm Cộng đồng → mở màn Community. Vào `.../home` (nếu nhập) → tự về Community.
3. **Kỳ vọng**: không lỗi điều hướng; vào app sau login ở Community. (FR-001..004, FR-014, SC-001/005)

### QS-002 — Nạp nhiều ảnh (US2)
1. Tủ đồ → "Thêm đồ" → chọn **nhiều ảnh** (vd 4) từ thư viện.
2. **Kỳ vọng**: hiển thị tiến trình `x/4`; các món lần lượt xuất hiện (optimistic + AI xong).
3. Thử 1 ảnh lỗi (tệp hỏng/mất mạng) → ảnh khác vẫn vào tủ; có nút Thử lại phần lỗi. (FR-005..008, SC-002)

### QS-003 — Tủ hệ thống ẩn món thiếu ảnh (US3)
1. Mở "Tủ đồ hệ thống".
2. **Kỳ vọng**: món **thiếu ảnh** (ao/quan/giay hiện tại) **không xuất hiện**, không chọn được; nếu rỗng → empty state tiếng Việt.
3. Khi BE bổ sung ảnh → món xuất hiện và thêm được đúng ảnh. (FR-009, FR-010, SC-003)

### QS-004 — Google login đúng tài khoản (US5)
1. Đăng nhập Google tài khoản **A** → ghi nhận hồ sơ/tủ đồ A.
2. Đăng xuất → đăng nhập Google tài khoản **B** (khác A) → hồ sơ/tủ đồ là **B**.
3. **Kỳ vọng**: không dùng chung phiên; account chooser hiển thị khi cần. (FR-012/013, SC-004)

### QS-005 — Việt hoá (US6)
1. Duyệt: đăng nhập, tủ đồ, studio, stylist, community, hồ sơ, marketplace.
2. **Kỳ vọng**: nhãn/nút/hint/thông báo **tiếng Việt**; không còn "Home/Wardrobe/Profile/Digital Closet/Retry/Search...". (FR-015..018, SC-006)

## 3. Kết quả mong đợi

- Tất cả QS pass; `flutter analyze` 0 issues; test liên quan pass.
- Không hồi quy deep-link/guard/paywall.

## 4. Ghi chú

- Google trên web cần thêm `http://localhost:8081` vào Authorized JavaScript origins (ngoài phạm vi code).
- Món hệ thống thiếu ảnh: app ẩn; muốn hiện lại cần **BE bổ sung ảnh**.
