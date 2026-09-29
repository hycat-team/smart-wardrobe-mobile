# Feature Specification: Community Social trên Mobile

**Feature Branch**: `011-community-social`

**Created**: 2026-09-27

**Status**: Draft

**Input**: User description: "Đọc smart-wardrobe-fe để hiểu cấu trúc/API/docs của chức năng community và lên kế hoạch code community cho mobile."

## Context

Backend đã có đầy đủ API community (spec FE `022-community-social`, tài liệu `contracts/frontend-integration.md` + `community-api-contract.md`). Mobile cần dựng lại trải nghiệm mạng xã hội thời trang này (bảng tin, đăng bài, thích, bình luận, theo dõi, hồ sơ công khai, tìm kiếm) trên nền app Closy hiện có.

## Clarifications

### Session 2026-09-27

- Q: Điểm vào Community trên mobile? → A: Route toàn màn hình, vào từ Home (banner/quick action) + menu Hồ sơ; giữ 5 tab (không thêm bottom-nav tab).
- Q: App mobile có chức năng kiểm duyệt admin không? → A: Ngoài phạm vi v1 — admin kiểm duyệt trên web.
- Q: Mobile v1 làm cả ảnh + video hay chỉ ảnh? → A: Cả ảnh + video (upload + phát) — parity FE.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Khám phá bảng tin & xem chi tiết bài đăng (Priority: P1)

Người dùng (kể cả khách chưa đăng nhập) mở màn Community để xem bảng tin thời trang, chuyển giữa "Khám phá" và "Đang theo dõi", sắp xếp "Nổi bật"/"Mới nhất", và mở chi tiết một bài đăng (bài `outfit` hiển thị bộ phối; bài `media` hiển thị ảnh/video).

**Why this priority**: Bảng tin + chi tiết bài là lõi trải nghiệm cộng đồng, mang lại giá trị ngay cả khi chưa có tương tác.

**Independent Test**: Mở Community, đổi tab/sort, mở chi tiết một bài `outfit` và một bài `media`; nội dung + tác giả + phương tiện hiển thị đúng.

**Acceptance Scenarios**:

1. **Given** đang ở bảng tin, **When** chọn tab "Khám phá" + sort "Mới nhất", **Then** danh sách bài `published` hiển thị theo thời gian giảm dần kèm tác giả/nội dung/ảnh.
2. **Given** đã đăng nhập và có theo dõi tác giả A, **When** chuyển tab "Đang theo dõi", **Then** thấy bài của A và bài của chính mình.
3. **Given** khách chưa đăng nhập, **When** chọn tab "Đang theo dõi", **Then** app yêu cầu đăng nhập và không gọi dữ liệu cá nhân.
4. **Given** bài `outfit`, **When** mở chi tiết, **Then** hiển thị ảnh bìa bộ phối + tên bộ phối.
5. **Given** bài `media`, **When** mở chi tiết, **Then** hiển thị đúng lưới ảnh hoặc trình phát video.

---

### User Story 2 - Soạn thảo & chia sẻ bài đăng (Priority: P1)

Người dùng đã đăng nhập tạo bài mới bằng cách chọn một bộ phối từ tủ đồ (`outfit`) hoặc tải ảnh/video (`media`) kèm nội dung; có thể sửa/xóa bài của mình.

**Why this priority**: Cho phép người dùng đóng góp nội dung — điều kiện để cộng đồng có dữ liệu.

**Independent Test**: Tạo bài `outfit` (chọn bộ phối) và bài `media` (1–10 tệp); bài xuất hiện đầu bảng tin; sửa nội dung và xóa thành công.

**Acceptance Scenarios**:

1. **Given** chọn `outfit`, **When** chọn bộ phối hợp lệ + nhập nội dung, **Then** bài `published` hiện trên bảng tin.
2. **Given** chọn `media`, **When** tải 1–10 tệp hợp lệ + nhập nội dung, **Then** tệp được upload và bài xuất bản.
3. **Given** bài trống (không nội dung, không media), **When** nhấn đăng, **Then** app chặn và báo lỗi rõ.
4. **Given** bài của chính mình, **When** sửa tiêu đề/nội dung, **Then** cập nhật ngay, **không** đổi `postType`.

---

### User Story 3 - Thích & xem danh sách người thích (Priority: P2)

Người dùng thích/bỏ thích bài viết (phản hồi tức thì) và xem danh sách người đã thích.

**Why this priority**: Tăng tương tác và động lực sáng tạo.

**Independent Test**: Nhấn thích → icon + số đếm đổi ngay; mở danh sách người thích (phân trang).

**Acceptance Scenarios**:

1. **Given** chưa thích, **When** nhấn Thích, **Then** icon đổi + số +1 ngay lập tức (optimistic).
2. **Given** đã thích, **When** nhấn lại, **Then** về chưa thích + số -1.
3. **Given** nhấn vào số lượt thích, **Then** mở danh sách người thích phân trang kèm hồ sơ.

---

### User Story 4 - Bình luận phân cấp (Priority: P2)

Người dùng bình luận, trả lời bình luận (lồng cấp), sửa/xóa bình luận của mình.

**Why this priority**: Kênh giao tiếp hai chiều giữa người xem và tác giả.

**Independent Test**: Gửi bình luận gốc, trả lời, sửa, xóa; kiểm tra thứ tự và placeholder "Bình luận đã bị xóa".

**Acceptance Scenarios**:

1. **Given** nhập nội dung hợp lệ (≤1000 ký tự), **When** gửi, **Then** bình luận gốc hiện đầu danh sách, tổng bình luận +1.
2. **Given** có bình luận gốc, **When** trả lời, **Then** phản hồi lồng bên dưới theo thứ tự cũ→mới.
3. **Given** là chủ bình luận, **When** sửa, **Then** cập nhật tại chỗ.
4. **Given** bình luận gốc có phản hồi, **When** chủ xóa, **Then** hiện "Bình luận đã bị xóa", giữ phản hồi.
5. **Given** bình luận không có phản hồi, **When** xóa, **Then** biến mất hoàn toàn.

---

### User Story 5 - Theo dõi & hồ sơ công khai (Priority: P3)

Người dùng theo dõi/bỏ theo dõi tác giả, mở trang cá nhân công khai (chỉ số + bài đăng), và xem danh sách following/followers có tìm kiếm.

**Why this priority**: Xây dựng đồ thị xã hội, định vị style curator.

**Independent Test**: Follow trên thẻ bài/Profile; mở trang `/users/{username}` xem thống kê + bài; mở danh sách follow và lọc.

**Acceptance Scenarios**:

1. **Given** chưa theo dõi, **When** nhấn "Theo dõi", **Then** nút đổi + followerCount +1 (optimistic).
2. **Given** mở hồ sơ công khai, **Then** hiển thị hồ sơ + bài viết + post/follower/following.
3. **Given** xem hồ sơ của chính mình (`isMe`), **Then** thấy cả bài `hidden` kèm huy hiệu.
4. **Given** mở danh sách follow, **When** nhập từ khóa, **Then** lọc theo username/họ tên.

---

### User Story 6 - Tìm kiếm người dùng & bài viết (Priority: P3)

Người dùng tìm kiếm theo từ khóa, kết quả chia 2 khối (Người dùng / Bài viết 30 ngày gần nhất).

**Why this priority**: Tăng khả năng khám phá nội dung mới.

**Independent Test**: Nhập từ khóa → thấy 2 khối kết quả; đổi filter users/posts hoạt động độc lập.

**Acceptance Scenarios**:

1. **Given** nhập từ khóa (≥1 ký tự), **When** tìm, **Then** trả 2 khối users + posts.
2. **Given** kết quả bài viết, **Then** chỉ bài `published` trong 30 ngày gần nhất.
3. **Given** đổi filter sang chỉ "Người dùng" hoặc chỉ "Bài viết", **Then** phân trang đúng nhóm, không lỗi chéo.

---

### Edge Cases

- **Tác giả xem bài bị ẩn**: bài `hidden` vẫn hiển thị với tác giả kèm huy hiệu; người khác nhận 404.
- **Bình luận gốc bị xóa còn phản hồi**: hiển thị "Bình luận đã bị xóa", giữ phản hồi.
- **Rate limit (429)**: hiển thị **SnackBar không chặn** (thông báo nhẹ), không retry dồn dập.
- **Media quá giới hạn**: chặn trước khi upload (ảnh >10MB, video >100MB/>60s), >10 tệp.
- **Mất liên kết `outfit`**: bài vẫn hiển thị nội dung + fallback an toàn.
- **Tự theo dõi chính mình**: ẩn nút follow; BE từ chối (400).
- **Thiếu avatar/gender**: avatar chữ cái đầu; xử lý key vắng an toàn.
- **`user` null (BE tạm lỗi enrichment)**: fallback an toàn, không crash.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: App PHẢI có màn Community với bảng tin hỗ trợ tab `explore` (mặc định) / `following`, và sort `hot` (mặc định) / `latest`.
- **FR-002**: Tab `following` PHẢI yêu cầu đăng nhập; khách chọn sẽ được mời đăng nhập (không gọi dữ liệu cá nhân).
- **FR-003**: App PHẢI gửi/đọc `postType` (`outfit`|`media`) và `mediaType` (`image`|`video`) dạng **chữ thường**.
- **FR-004**: App PHẢI đọc thông tin tác giả từ **object lồng `user`** (`post.user`, `comment.user`, `follow.user`) và truy cập phòng thủ khi `user` có thể null/vắng `avatarUrl`/`gender`.
- **FR-005**: Màn chi tiết bài PHẢI hiển thị: bài `outfit` → ảnh bìa + tên bộ phối (`outfit.coverImageUrl/name`); bài `media` → lưới ảnh hoặc trình phát video (theo thứ tự `sortOrder`).
- **FR-006**: Tạo bài `outfit` PHẢI chọn `outfitId` hợp lệ thuộc sở hữu người dùng; tạo bài `media` PHẢI có `content` không rỗng HOẶC ≥1 media (tối đa 10 tệp).
- **FR-007**: Upload tệp PHẢI lấy chữ ký từ BE kèm `resourceType` (`image`|`video`) rồi upload Cloudinary đúng endpoint theo `resourceType` (tái dùng mô hình upload hiện có của app).
- **FR-008**: App PHẢI cho phép sửa bài của chính mình (tiêu đề/nội dung/outfit/media — **không** đổi `postType`) và xóa bài của mình.
- **FR-009**: Thích/Bỏ thích PHẢI cập nhật **optimistic** (icon + `likeCount`) và đồng bộ khi có lỗi.
- **FR-010**: App PHẢI có danh sách người thích phân trang (`items: CommunityUserRes[]` + `metadata`).
- **FR-011**: Bình luận gốc PHẢI sắp **mới nhất trước**; phản hồi trong mỗi gốc sắp **cũ nhất trước**; `replyCount` chỉ ở gốc.
- **FR-012**: Chủ bình luận PHẢI sửa/xóa được; bình luận gốc bị xóa còn phản hồi → hiển thị "Bình luận đã bị xóa".
- **FR-013**: Follow/Unfollow PHẢI cập nhật **optimistic**; nút tự ẩn khi người xem là chính tác giả.
- **FR-014**: App PHẢI có màn **hồ sơ công khai** (`/users/{username}`): hồ sơ + `followerCount/followingCount/postCount` + danh sách bài; bài của chính mình gồm cả `hidden` kèm huy hiệu.
- **FR-015**: Danh sách follow PHẢI hỗ trợ `type` (`following`|`followers`|cả hai) + lọc `q`, hiển thị `relation` và `followedAt` (mới nhất trước).
- **FR-016**: Màn tìm kiếm PHẢI gọi `/search` và hiển thị 2 khối độc lập (users + posts) với phân trang riêng; bài chỉ trong **30 ngày** gần nhất, `published`.
- **FR-017**: App PHẢI xử lý phản hồi: envelope `{message, data?}` (`data` có thể **vắng**); lỗi `{status, title?, message?, errors?}`; map 400/401/403/404/429 sang thông báo tiếng Việt.
- **FR-018**: App PHẢI validate client-side trước khi gửi: `title` ≤150, `content` bài ≤5000, bình luận ≤1000 (đã trim, không rỗng), ≤10 media, ảnh ≤10MB, video ≤100MB & ≤60s.
- **FR-019**: App PHẢI hiển thị ảnh qua `ClosyNetworkImage` (memCache hợp lý) và có trạng thái loading/empty/error + kéo làm mới cho feed/danh sách.
- **FR-020**: Khách chưa đăng nhập PHẢI xem được nội dung công khai (feed explore, chi tiết bài, hồ sơ công khai, tìm kiếm); mọi thao tác ghi (đăng, thích, bình luận, theo dõi) PHẢI yêu cầu đăng nhập.
- **FR-021**: `sharePath` của bài PHẢI khớp tuyến chi tiết bài trong app.
- **FR-022**: App PHẢI KHÔNG hiển thị/logic các trường resale/transfer (`items`, `totalPrice`, `contactInfo`, `transferState`, ...).

### Key Entities

- **CommunityUser**: Hồ sơ thành viên (`userId`, `username`, `firstName?`, `lastName?`, `avatarUrl?`, `gender?` 1=Nam/2=Nữ/3=Khác).
- **Post**: Bài đăng (`publicId`, `user`, `postType`, `status` published|hidden, `title?`, `content`, `outfit?`, `media?`, `likeCount`, `commentCount`, `isLiked`, `isFollowingAuthor`, `sharePath`).
- **OutfitBrief**: Bộ phối liên kết (`id`, `name`, `coverImageUrl?`).
- **Comment**: Bình luận (`id`, `user`, `content`, `parentCommentId?`, `replyCount`, `isDeleted`, `createdAt`).
- **FollowRelationship**: Quan hệ theo dõi (`user`, `relation` following|follower, `followedAt`).
- **PublicProfile**: Hồ sơ công khai (`user`, `stats`, `isFollowing`, `isMe`).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Người dùng thấy 10 bài đầu + ảnh sắc nét trong < 2 giây trên mạng thông thường.
- **SC-002**: Thích/Bỏ thích phản hồi UI < 100ms (optimistic), không giật lag.
- **SC-003**: 100% bài `outfit` hiển thị đúng ảnh bìa + tên bộ phối.
- **SC-004**: Hoàn tất tạo + xuất bản một bài < 60 giây.
- **SC-005**: Follow/Bỏ theo dõi phản hồi nút tức thì và đồng bộ số liệu toàn app.
- **SC-006**: 100% lỗi từ máy chủ (gồm 429/400) hiển thị tiếng Việt rõ ràng.
- **SC-007**: 0% crash do truy cập sai cấu trúc `user` lồng (kể cả khi `user` null).
- **SC-008**: Tỉ lệ tìm kiếm thành công (users + posts) > 90% ngay lần đầu.

## Assumptions

- **Điểm vào Community**: màn Community dạng **route toàn màn hình**, truy cập từ **Home (banner/quick action)** và **menu Hồ sơ**; **không** thêm bottom-nav tab trong v1 (đã chốt ở Clarifications).
- **Nền tảng v1**: Android + Web (dev Chrome) như app hiện tại; **iOS ngoài phạm vi v1**.
- **Phiên**: mobile dùng **Bearer token** (khác web dùng cookie); endpoint community có auth optional cho đọc.
- **Upload**: dùng lại mô hình `upload-signature` → Cloudinary của app (giống tủ đồ).
- **Media**: v1 gồm **cả ảnh + video** (upload + phát trong chi tiết bài) — parity FE (đã chốt ở Clarifications); cần thư viện phát video và bộ chọn/quay video.
- **Admin moderation**: **ngoài phạm vi** app mobile v1 (đã chốt ở Clarifications) — thực hiện trên web admin.
- **API**: base `/api/v1`, envelope `{message, data?}`, phân trang `{items, metadata}`; tham chiếu FE `specs/022-community-social/contracts/frontend-integration.md`.
- **Outfit picker**: dùng API danh sách outfit hiện có của app.
- **Resale/transfer**: đã bị loại bỏ hoàn toàn ở backend — mobile không xây dựng lại.
