# Quickstart — Kiểm chứng "Canvas một món mỗi loại"

**Feature**: `017-canvas-single-item` · **Date**: 2026-10-13

Chi tiết quyết định ở [research.md](./research.md), bất biến ở [data-model.md](./data-model.md),
quy tắc ở [contracts/canvas-rules.md](./contracts/canvas-rules.md).

---

## 1. Chuẩn bị

```powershell
flutter pub get
$env:API = 'http://localhost:5000/api/v1'
$env:CLD = 'dzvwkngxu'
make run          # web trên Edge :8081
# hoặc: make dev DEVICE=android
```

Tài khoản: `user / 123456`. BE local bật ở `http://localhost:8080`.

### Tĩnh

```powershell
flutter analyze
flutter test test/studio_single_item_per_role_test.dart test/canvas_outerwear_layout_test.dart test/studio_canvas_placement_test.dart
```

---

## 2. Kịch bản kiểm chứng

### US1 · Một món mỗi loại (P1)

1. Mở **Phối đồ → Studio Thủ Công**, kéo khay lên.
2. Thêm **một áo** (A) → canvas có 1 áo.
3. Thêm **một áo khác** (B) → **canvas vẫn chỉ 1 áo**, là áo B (áo A bị gỡ). Có toast thông báo.
4. Thêm **một quần** → áo B giữ nguyên, canvas có áo + quần.
5. Thêm **một quần khác** → chỉ quần bị thay.
6. Thêm **hai phụ kiện khác nhau** → **cả hai cùng tồn tại** (không bị thay).

### US1b · Đầm ↔ áo (Q2)

7. Canvas đang có áo + quần. Thêm **đầm** → **áo bị gỡ, quần giữ nguyên** (đầm + quần).
8. Thêm **áo** trở lại → **đầm bị gỡ**; áo + quần.

### US1c · Thay tại chỗ & kích thước món phụ (bản chỉnh 2026-10-13)

8b. Kéo một đôi giày tới vị trí bất kỳ và đổi kích thước, rồi thêm một đôi giày khác → đôi mới **nằm đúng vị trí + kích thước đôi cũ** (thay tại chỗ), không nhảy về vị trí chuẩn.
8c. Thêm giày/nón/phụ kiện → **to hơn** so với trước (áo `112`, đầm `118`, nón `76`, giày `80`, phụ kiện `74`); **phụ kiện nép sát cột giữa** ở vùng trên (cao hơn áo, thấp hơn nón).

### US2 · Áo khoác chồng nhẹ, không che kín lớp nền (P1)

9. Thêm **áo**, rồi thêm **áo khoác** → áo khoác **rộng bằng & ngang hàng** với áo, chồng **≤ 40%** lên áo, đặt ở **phía đối diện phụ kiện**; áo **không bị dời**.
10. Lặp với **đầm** rồi **áo khoác**.
11. Thêm **áo khoác** khi canvas trống (không lớp nền) → không bị lệch bất thường.
12. Thêm **quần** sau áo + áo khoác → áo **không bị dời**, không chồng lên quần.
13. Có **phụ kiện** ở bên trái → **áo khoác sang bên phải** (đối diện); thêm phụ kiện bên phải → áo khoác sang trái.
14. **Phụ kiện nép sát cột giữa** (áo/quần/nón/giày) nhưng **không đè** lên cột; cột giữa (áo/quần/nón/giày) **căn giữa và to**.

### US3 · Trải nghiệm thay thế (P2)

12. Sau khi thay thế, món mới **đang được chọn**, nằm trọn trong khung; có phản hồi rõ ràng.

---

## 3. Kết quả mong đợi (map Success Criteria)

| SC | Kiểm chứng |
|---|---|
| SC-001 | Không bao giờ có 2 món cùng loại cơ bản (bước 3, 5, 7, 8) |
| SC-002 | Áo khoác rộng bằng áo, chồng ≤40% áo, đối diện phụ kiện (bước 9, 10, 13) |
| SC-003 | Món mới nằm trọn trong khung (bước 3–12) |
| SC-004 | Thêm vào canvas trống không gỡ nhầm (bước 11) |
| FR-001 | Phụ kiện/mũ nhiều món vẫn giữ (bước 6) |

---

## 4. Ghi chú

- Test unit thuần (không widget): dùng `ProviderContainer` + `addItemToCanvas` (mẫu
  `test/studio_canvas_placement_test.dart`). Assert theo bất biến INV-1/3/5/6.
- Ghi `docs/work-log-<yyyy-mm-dd>.md` khi hoàn tất.
