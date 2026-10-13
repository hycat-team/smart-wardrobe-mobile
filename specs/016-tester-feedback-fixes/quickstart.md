# Quickstart — Kiểm chứng "Sửa lỗi theo phản hồi tester (đợt 1)"

**Feature**: `016-tester-feedback-fixes` · **Date**: 2026-10-13

Hướng dẫn chạy và kiểm chứng end-to-end cho 7 nhóm việc. Chi tiết quyết định ở
[research.md](./research.md), dữ liệu/bất biến ở [data-model.md](./data-model.md), hợp đồng
ở [contracts/](./contracts/).

---

## 1. Chuẩn bị

```powershell
flutter pub get                 # lần đầu kéo flutter_markdown_plus
$env:API = 'http://localhost:5000/api/v1'
$env:CLD = 'dzvwkngxu'
```

Chạy app (chọn 1):

```powershell
# Web (Edge, dev nhanh)
make run

# Android emulator (kiểm vùng chạm / kéo thả thật)
make dev DEVICE=android
# hoặc thủ công:
flutter run --dart-define=API_BASE_URL=$env:API `
  --dart-define=API_BASE_URL_ANDROID=http://10.0.2.2:5000/api/v1 `
  --dart-define=CLOUDINARY_CLOUD_NAME=$env:CLD
```

Tài khoản thử: `user / 123456`. BE local bật sẵn.

### Tĩnh (bắt buộc trước khi bàn giao)

```powershell
flutter analyze                 # 0 issues mới
flutter test test/canvas_layout_test.dart test/studio_canvas_placement_test.dart `
  test/studio_drawer_category_test.dart test/studio_clear_all_test.dart `
  test/stylist_markdown_render_test.dart test/community_search_filter_test.dart `
  test/wardrobe_status_widget_test.dart
```

---

## 2. Kịch bản kiểm chứng

### WS-A · Thêm món không tràn biên (US1, P1)

1. Mở **Phối đồ** → tab **Studio Thủ Công**.
2. Kéo khay tủ đồ lên, lần lượt chạm thêm: 1 **phụ kiện**, 1 **giày**, 1 món **"khác"**.
3. **Kỳ vọng**: mỗi món xuất hiện **trọn vẹn trong khung canvas**, không bị cắt/ra ngoài.
4. Lặp trên **3 kích thước màn hình** (nhỏ 320×520, trung 390×700, lớn 430×932) → mỗi món vẫn trọn trong biên (SC-001).
5. Kéo/scale món vẫn hoạt động; không làm xê dịch các món khác khi thêm.

### WS-B · "Áo khoác" + khay mượt + đóng bằng icon (US2, P1)

1. Trong khay tủ đồ: có chip **"Áo khoác"**; chạm → chỉ hiện áo khoác.
2. Chạm chip **"Áo"** → không còn áo khoác trong danh sách.
3. Kéo khay lên/xuống liên tục → không giật/khựng rõ; canvas không nhảy.
4. Ở trạng thái mở, chạm **icon mũi tên xuống** ở thanh tiêu đề → khay thu gọn.

### WS-C · Nút "Xóa tất cả" (US3, P2)

1. Thêm vài món lên canvas.
2. Bấm **"Xóa tất cả"** ở thanh công cụ bên phải → xác nhận.
3. **Kỳ vọng**: canvas trống; canvas trống thì nút không hiện/không khả dụng.

### WS-D · Chat AI Markdown (US4, P2)

1. Mở **Stylist AI**, gửi câu hỏi khiến AI trả lời có danh sách/đậm.
2. **Kỳ vọng**: đậm/nghiêng/danh sách/liên kết/mã hiển thị đúng định dạng; **không** thấy
   ký tự `*`, `#`, `-` thô.
3. Quan sát lúc AI đang trả lời → phần đã nhận vẫn định dạng, không nhấp nháy lỗi.

### WS-E · Gỡ ô "Demo" (US5, P3)

1. Mở màn **Tạo Tài Khoản**.
2. **Kỳ vọng**: không còn chip **"Điền mẫu tự động (Demo)"**; form đăng ký gửi OTP bình thường.

### WS-F · Gỡ nút Studio ở chi tiết món (US6, P3)

1. Tủ đồ → mở chi tiết một món.
2. **Kỳ vọng**: thanh đáy **không** còn nút **"Phối đồ Studio"**; nút **"Chỉnh sửa"** vẫn chạy.

### WS-G · Bỏ hàng lọc loại bài trong tìm kiếm (US7, P3)

1. Community → mở **Tìm kiếm**, nhập từ khoá, xem tab **Bài viết**.
2. **Kỳ vọng**: **không** còn chip `Tất cả bài / Bộ phối / Ảnh/Video`; kết quả gồm mọi loại bài.
3. Hàng `Tất cả/Tác giả/Bài viết` vẫn còn và hoạt động.

---

## 3. Kết quả mong đợi (map với Success Criteria)

| SC | Kiểm chứng |
|---|---|
| SC-001 | 100% món (phụ kiện/giày/khác) nằm trọn trong canvas ở ≥3 kích thước màn hình (WS-A) |
| SC-002 | Kéo khay không giật thấy rõ (WS-B) |
| SC-003 | Đóng khay bằng 1 thao tác chạm icon mũi tên (WS-B) |
| SC-004 | "Xóa tất cả" xoá sạch canvas (có xác nhận) (WS-C) |
| SC-005 | 0 ký tự Markdown thô lộ ra trong câu trả lời AI (WS-D) |
| SC-006 | Màn đăng ký không còn điều khiển "Demo" (WS-E) |
| SC-007 | Chi tiết món không còn lối vào Studio (WS-F) |
| SC-008 | Tìm kiếm Community không còn hàng lọc loại bài (WS-G) |

---

## 4. Ghi chú kiểm thử tự động

- `flutter test` không tải được `google_fonts` → dùng font dự phòng; phép đo bề rộng/nhãn
  chỉ mang tính tương đối (không dùng để assert "vừa khít px"). Đo thật trên máy cho UI.
- Hai test được **sửa có chủ đích** (không phải hồi quy): `community_search_filter_test.dart`
  (bỏ assert hàng 2), `wardrobe_status_widget_test.dart` (bỏ assert nút Studio).
- Ghi work-log `docs/work-log-2026-10-13.md` khi hoàn tất (spec nào, task nào, file, việc cần user).
