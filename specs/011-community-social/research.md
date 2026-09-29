# Phase 0 Research: Community Social trên Mobile

**Feature**: `011-community-social` | **Date**: 2026-09-27

Nguồn: hợp đồng BE/FE `smart-wardrobe-fe/specs/022-community-social/contracts/{frontend-integration,community-api-contract}.md`, code app hiện tại, và tài liệu package Flutter.

---

## R1 — Phát video trong bài `media`

- **Decision**: Dùng **`video_player`** (chính thức Flutter) để phát video; bọc trong widget `CommunityVideoPlayer` (play/pause, loading, lỗi an toàn). Không dùng `chewie` ở v1 (tránh thêm phụ thuộc) trừ khi cần UI điều khiển đầy đủ.
- **Rationale**: `video_player` hỗ trợ Android/Web, đủ cho phát cơ bản; giảm phụ thuộc.
- **Alternatives considered**: `chewie` (UI sẵn nhưng thêm dep); WebView/HTML video (không đồng nhất Android).

## R2 — Chọn & validate media (ảnh + video)

- **Decision**: Dùng `image_picker` hiện có: `pickMultiImage` cho ảnh, `pickVideo` cho video. Validate client-side trước khi upload: tối đa **10 tệp**, ảnh ≤ **10MB**, video ≤ **100MB** và ≤ **60s** (đọc `XFile.length()`, và duration cho video nếu lấy được). Chặn sớm + thông báo tiếng Việt.
- **Rationale**: Tránh lãng phí băng thông/429/400; khớp giới hạn BE.
- **Alternatives considered**: Chỉ dựa BE trả lỗi (UX kém); thêm plugin nén video (ngoài phạm vi).

## R3 — Upload ảnh/video lên Cloudinary qua signature của BE

- **Decision**: Mở rộng `CloudinaryService` để nhận `resourceType` (`image`|`video`): lấy `GET /posts/upload-signature?resourceType=...` → POST multipart tới `https://api.cloudinary.com/v1_1/{cloud}/{resourceType}/upload` với `file, api_key, timestamp, signature, folder, public_id?`. Trả `{mediaUrl=secure_url, publicId}`.
- **Rationale**: Tái dùng mô hình upload của app (tủ đồ/avatar) và đúng hợp đồng (`UploadSignatureResult.resourceType`).
- **Alternatives considered**: Upload qua BE proxy (thêm tải BE, không cần thiết).

## R4 — Bảng tin + phân trang vô hạn

- **Decision**: Dùng `StateNotifier` + pattern load-more hiện có (single-flight, dedupe by `publicId`, cờ `hasMore` theo `metadata.totalItems/totalPages`). Tham số feed: `type` (explore/following), `sort` (hot/latest), `postType?`, `username?`, `page`, `limit=20`. Đổi tab/sort reset list.
- **Rationale**: Đồng nhất với wardrobe/outfits; tránh spinner vô hạn; xử lý pagination `{items, metadata}`.
- **Alternatives considered**: package pagination (thêm dep); load-all (không scale).

## R5 — Optimistic cho Like/Follow

- **Decision**: Cập nhật UI tức thời (`isLiked`/`likeCount`, `isFollowing`/`followerCount`) rồi gọi API `PUT /posts/{id}/like {isLiked}` / `PUT /users/{username}/follow {isFollowing}`; rollback nếu lỗi; đồng bộ lại các nơi hiển thị cùng bài/user.
- **Rationale**: SC-002/005 (<100ms); API idempotent.
- **Alternatives considered**: chờ server (UX chậm).

## R6 — Đọc `user` lồng an toàn (breaking)

- **Decision**: Model hoá `CommunityUser` và luôn truy cập phòng thủ: `post.user?.username`, xử lý `avatarUrl` vắng → avatar chữ cái đầu; `gender` số (1=Nam/2=Nữ/3=Khác, 0 vắng) → map nhãn; `user` có thể null khi BE enrichment lỗi.
- **Rationale**: FR-004/SC-007; tránh crash.
- **Alternatives considered**: giả định user luôn có (rủi ro crash).

## R7 — Routing & điểm vào

- **Decision**: Thêm route: `/community`, `/community/posts/:publicId`, `/community/create`, `/community/search`, `/users/:username`. Điểm vào: Home (banner/quick action) + menu Profile; màn full-screen (không thêm bottom tab). `sharePath` của BE (`/community/posts/{publicId}`) khớp route chi tiết.
- **Rationale**: Clarifications Q1; đồng bộ share link.
- **Alternatives considered**: bottom-nav tab (đã loại); nhúng trong Home (đã loại).

## R8 — Guest gating (đọc công khai, ghi cần đăng nhập)

- **Decision**: Cho phép gọi API đọc khi chưa đăng nhập (`/posts` explore, `/posts/{id}`, `/users/{username}`, `/search`). Với thao tác ghi (đăng/thích/bình luận/theo dõi) hoặc tab `following`: nếu chưa đăng nhập → lưu `pendingRedirect` + điều hướng `/login` (tái dùng guard hiện có). Xử lý 401 → mời đăng nhập.
- **Rationale**: FR-002/020; an toàn.
- **Alternatives considered**: bắt đăng nhập toàn bộ (loại — giảm khám phá).

## R9 — Map lỗi & rate limit

- **Decision**: Envelope `{message, data?}` (`data` có thể vắng); lỗi `{status, title?, message?, errors?}`. Map 400 (validate → hiện `message`/`errors[0].message`), 401 (đăng nhập), 403 (không phải chủ), 404 (không tìm thấy/đã ẩn), 429 (rate limit → thông báo nhẹ, không retry dồn dập). Dùng lại pattern `_extractErrorMessage` của app.
- **Rationale**: FR-017/SC-006.
- **Alternatives considered**: hiện raw error (kém).

## R10 — Render media & cache

- **Decision**: Ảnh qua `ClosyNetworkImage` (memCache ~400 grid, ~800 detail); video qua `video_player` (poster = `outfit.coverImageUrl` hoặc frame đầu). Grid tối đa 10 media theo `sortOrder`; danh sách dùng `AutomaticKeepAliveClientMixin`.
- **Rationale**: Constitution IV; SC-001/003.
- **Alternatives considered**: `Image.network` (bị cấm).

---

**Output**: Tất cả `NEEDS CLARIFICATION` đã giải quyết; sẵn sàng Phase 1.
