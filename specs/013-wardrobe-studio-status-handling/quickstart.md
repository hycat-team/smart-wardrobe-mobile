# Quickstart: Kiểm chứng 013 — Wardrobe Landing, Studio Canvas & Status Handling

**Feature**: `013-wardrobe-studio-status-handling` | **Date**: 2026-09-28

Hợp đồng: [contracts/retry-analysis.contract.md](./contracts/retry-analysis.contract.md), [contracts/canvas-layout.contract.md](./contracts/canvas-layout.contract.md), [contracts/status-ui-matrix.contract.md](./contracts/status-ui-matrix.contract.md); state: [data-model.md](./data-model.md).

## 0. Điều kiện

- BE local chạy (nginx `:8080`, đã triển khai BE 023), có wardrobe/retry-analysis/SSE.
- `.env`: `API_BASE_URL=http://localhost:8080/api/v1` (+ Android `10.0.2.2`).
- `flutter pub get`.

## 1. Lệnh

```powershell
flutter pub get
flutter analyze
flutter test test/canvas_layout_test.dart test/wardrobe_retry_test.dart

flutter run -d chrome --web-port=8081   # Web
flutter run                              # Android
```

## 2. Kịch bản

### QS-001 — Landing Wardrobe (US1)
1. Đăng xuất → đăng nhập (mật khẩu và Google) → vào thẳng `/wardrobe`, tab Tủ đồ nổi bật.
2. Mở lại app khi còn phiên → vẫn `/wardrobe`; deep-link chờ (vd bài viết) vẫn ưu tiên đích chờ.
3. **Kỳ vọng**: <300ms sau xác thực; không hồi quy guard/pendingRedirect. (FR-001/002, SC-001)

### QS-002 — Trạng thái phân tích AI (US2)
1. Nạp ảnh nhiều món → thẻ lỗi "Ảnh có nhiều món", **không** nút Thử lại, có gợi ý ảnh khác.
2. Nạp ảnh đơn món AI chưa rõ loại → "Cần chọn danh mục" → chọn "Áo" → gửi lại → về "Đang phân tích" → hoàn tất.
3. Giả lập lỗi tạm thời → nút "Thử lại" → bấm 2 lần liên tiếp chỉ gửi 1 request.
4. Ngắt mạng giữa SSE → mở lại/kéo làm mới → trạng thái đồng bộ, không kẹt processing.
5. **Kỳ vọng**: đúng ma trận [status-ui-matrix](./contracts/status-ui-matrix.contract.md). (FR-012..017, SC-005/006)

### QS-003 — Studio Canvas (US3)
1. Mở set Áo khoác + Áo + Quần + Giày + Túi/Kính → áo trên, quần dưới, giày đáy, khoác phủ áo, phụ kiện lệch bên, tỉ lệ dọc/ngang đúng, vừa khung không cần kéo tay.
2. Mở outfit đầm liền thân + khoác + giày → đầm trung tâm, khoác phủ ngoài.
3. Mở outfit cũ (tọa độ legacy) → không bay hình; màn hình nhỏ → co vừa khung.
4. **Kỳ vọng**: đúng [canvas-layout](./contracts/canvas-layout.contract.md). (FR-005..011, SC-003/004)

### QS-004 — Gỡ SnackBar lưu (US4)
1. Phối + "Lưu Trang Phục" → về `/outfits` ngay, **không** SnackBar thành công; lưu lỗi mạng → vẫn báo lỗi rõ.
2. **Kỳ vọng**: chuyển hướng <500ms. (FR-003/004, SC-002)

## 3. Kết quả mong đợi

- Tất cả QS pass; `flutter analyze` 0 issues; test liên quan pass.
- Không hồi quy deep-link/guard/paywall/nav 012.
