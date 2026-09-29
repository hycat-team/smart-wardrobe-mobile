# Quickstart: Kiểm chứng Community Social trên Mobile

**Feature**: `011-community-social` | **Date**: 2026-09-27

Chi tiết hợp đồng: [contracts/community-mobile.md](./contracts/community-mobile.md); thực thể/logic: [data-model.md](./data-model.md).

## 0. Điều kiện tiên quyết

- BE local chạy (`docker compose -f deployments/docker-compose.yml up -d`; nginx `:8080`), có đủ API community (`/posts`, `/users`, `/search`).
- `.env` app: `API_BASE_URL=http://localhost:8080/api/v1` (+ Android `10.0.2.2`).
- Có sẵn: 1 tài khoản thường (`user/123456`) có outfit trong tủ; tài khoản thứ hai để test follow; ít nhất vài bài `published` + 1 bài `outfit`.
- `flutter pub get` (deps gồm `video_player`).

## 1. Lệnh chạy

```powershell
flutter pub get
flutter analyze
flutter test test\community_*.dart

flutter run -d chrome --web-port=8081   # Web dev
flutter run                              # Android
```

## 2. Kịch bản kiểm chứng

### QS-001 — Bảng tin & chi tiết (P1)
1. Từ Home → mở **Community**.
2. Đổi tab Khám phá/Đang theo dõi + sort Nổi bật/Mới nhất; cuộn tải thêm.
3. Mở 1 bài `outfit` (thấy ảnh bìa + tên bộ phối) và 1 bài `media` (thấy lưới ảnh/ video phát được).
4. **Kỳ vọng**: danh sách đúng, phân trang mượt, ảnh sắc nét (ClosyNetworkImage), không crash. (FR-001/003/005/019)

### QS-002 — Đăng bài outfit & media (P1)
1. Đăng nhập → **Tạo bài** → chọn `outfit`, chọn bộ phối từ tủ, nhập nội dung → Đăng.
2. Tạo bài `media`: chọn 1–3 ảnh (và 1 video) → nhập nội dung → Đăng.
3. Thử đăng bài trống (không nội dung, không media) → bị chặn + báo lỗi.
4. Sửa nội dung bài của mình → lưu; xóa bài của mình.
5. **Kỳ vọng**: bài xuất hiện đầu feed; validate đúng; sửa/xóa thành công. (FR-006/008/018)

### QS-003 — Thích & danh sách người thích (P2)
1. Nhấn Thích → icon + số đổi **ngay** (optimistic); nhấn lại bỏ thích.
2. Mở danh sách người thích → phân trang, hiển thị hồ sơ.
3. **Kỳ vọng**: phản hồi <100ms, rollback khi lỗi mạng. (FR-009/010, SC-002)

### QS-004 — Bình luận phân cấp (P2)
1. Gửi bình luận gốc → hiện đầu danh sách, tổng +1.
2. Trả lời bình luận → lồng dưới, thứ tự cũ→mới.
3. Sửa bình luận của mình; xóa bình luận gốc còn reply → hiện "Bình luận đã bị xóa".
4. **Kỳ vọng**: đúng thứ tự, placeholder đúng. (FR-011/012)

### QS-005 — Theo dõi & hồ sơ công khai (P3)
1. Mở hồ sơ tác giả → nhấn Theo dõi → nút + followerCount đổi ngay.
2. Xem `/users/{username}`: thống kê + bài viết; mở danh sách following/followers + lọc `q`.
3. Xem hồ sơ của chính mình → thấy bài `hidden` kèm huy hiệu.
4. **Kỳ vọng**: optimistic, số liệu đồng bộ; ẩn nút follow với chính mình. (FR-013/014/015, SC-005)

### QS-006 — Tìm kiếm (P3)
1. Nhập từ khóa → 2 khối Người dùng / Bài viết; đổi filter users/posts.
2. **Kỳ vọng**: bài chỉ trong 30 ngày; phân trang 2 khối độc lập. (FR-016)

### QS-007 — Guest & lỗi (P2)
1. Đăng xuất → xem feed explore/detail/profile/search OK.
2. Chọn tab "Đang theo dõi" hoặc nhấn Thích/Bình luận/Theo dõi → được mời đăng nhập (lưu đích đến).
3. Giả lập 429 (thao tác nhanh liên tục) → thông báo nhẹ tiếng Việt, không crash.
4. **Kỳ vọng**: đọc công khai OK; ghi yêu cầu đăng nhập; lỗi tiếng Việt. (FR-002/017/020, SC-006)

## 3. Kết quả mong đợi tổng hợp

- Tất cả QS pass; `flutter analyze` 0 issues; unit/widget test `community_*` pass.
- Ảnh qua `ClosyNetworkImage`; video phát được; không crash với `user` null/thiếu avatar.
- `sharePath` mở đúng chi tiết bài trong app.

## 4. Ghi chú

- Dùng chung 1 tài khoản để test cả guest (đăng xuất) và user.
- Video Android/Web dùng `video_player`; nếu video không phát, kiểm tra URL Cloudinary (`resourceType=video`).
