---
description: "Task list — Community Social trên Mobile (011-community-social)"
---

# Tasks: Community Social trên Mobile

**Input**: Design documents from `specs/011-community-social/`

**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/community-mobile.md`, `quickstart.md`, `.specify/memory/constitution.md`

**Tests**: Có — theo DoD dự án (`flutter analyze` 0 issues + `flutter test` liên quan).

**Organization**: Task nhóm theo user story để mỗi story triển khai/kiểm thử độc lập.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Chạy song song được (khác file, không phụ thuộc task chưa xong)
- **[Story]**: US1..US6 (ánh xạ spec.md)
- Mọi task có đường dẫn file cụ thể

## Path Conventions

Flutter feature-first: `lib/features/community/**`, `lib/core/**`, `test/**`.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Dependency + route + điểm vào.

- [X] T001 Thêm `video_player` vào `pubspec.yaml` và chạy `flutter pub get`
- [X] T002 [P] Tạo cấu trúc thư mục `lib/features/community/{data,models,providers,presentation/widgets}` (file rỗng/placeholder) theo `plan.md`
- [X] T003 [P] Thêm route vào `lib/core/router/app_router.dart`: `/community`, `/community/posts/:publicId`, `/community/create`, `/community/search`, `/users/:username` (đăng ký route + placeholder tối thiểu; screen thật tạo ở T017/T020/T023/T034/T038), `/users/:username` cho phép khách
- [X] T004 [P] Thêm điểm vào Community: quick action ở `lib/features/home/presentation/home_screen.dart` + menu "Cộng đồng" ở `lib/features/profile/presentation/profile_screen.dart` → `context.push('/community')`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Models, repository, upload video, shared widgets — BẮT BUỘC xong trước mọi story.

**⚠️ CRITICAL**: Không bắt đầu user story nào trước khi hoàn tất phase này.

- [X] T005 Tạo `CommunityUser` trong `lib/features/community/models/community_user.dart` (userId, username, firstName?, lastName?, avatarUrl?, gender?; getters `displayName`, `initials`, `genderLabel`)
- [X] T006 [P] Tạo models Post trong `lib/features/community/models/post_models.dart`: `Post`, `OutfitBrief`, `PostMedia`, `CreatePostReq`, `UpdatePostReq`, `PostMediaReq` (enum lowercase `outfit|media`, `image|video`)
- [X] T007 [P] Tạo `Comment` trong `lib/features/community/models/comment_models.dart` (id, user, content, parentCommentId?, replyCount, isDeleted, createdAt)
- [X] T008 [P] Tạo models profile trong `lib/features/community/models/profile_models.dart`: `PublicProfile`, `PublicProfileStats`, `FollowUser` (relation, followedAt)
- [X] T009 [P] Tạo models search trong `lib/features/community/models/search_models.dart`: `SearchResult` (users + posts phân trang)
- [X] T010 Mở rộng `lib/core/services/cloudinary_service.dart`: `uploadImage` → hỗ trợ `resourceType` (`image`|`video`), build URL `.../{resourceType}/upload`
- [X] T011 Tạo `lib/features/community/data/community_repository.dart`: `getCommunityPosts`, `getPostDetail`, `getUploadSignaturePost`, `createPost`, `updatePost`, `deletePost`, `likePost`, `getPostLikes`, `getPostComments`, `getCommentReplies`, `addComment`, `updateComment`, `deleteComment` (Dio)
- [X] T012 [P] Tạo `lib/features/community/data/user_social_repository.dart`: `followUser`, `getPublicProfile`, `getUserPosts`, `getUserFollows`
- [X] T013 [P] Tạo `lib/features/community/data/community_search_repository.dart`: `searchCommunity`
- [X] T014 Tạo helper `lib/features/community/data/community_error.dart`: map 400/401/403/404/429 → message tiếng Việt (tái dùng pattern `_extractErrorMessage`); hàm `requireLogin(context, ref, target)` lưu `pendingRedirect` → `/login`
- [X] T015 Tạo shared widgets: `lib/features/community/presentation/widgets/community_user_avatar.dart` (fallback chữ cái đầu), `media_grid.dart` (ảnh qua `ClosyNetworkImage` + video), `community_video_player.dart` (`video_player`)

**Checkpoint**: Nền tảng sẵn sàng — bắt đầu user story.

---

## Phase 3: User Story 1 - Bảng tin & chi tiết bài (Priority: P1) 🎯 MVP

**Goal**: Feed explore/following + sort hot/latest, cuộn vô hạn; chi tiết bài outfit/media + video.

**Independent Test**: Mở Community, đổi tab/sort, mở chi tiết 1 bài outfit + 1 bài media; phân trang mượt.

- [X] T016 [US1] Tạo `lib/features/community/providers/community_feed_provider.dart` (state items/tab/sort/page/total/hasMore; load-more single-flight + dedupe by publicId)
- [X] T017 [US1] Tạo `lib/features/community/presentation/community_feed_screen.dart` (tabs + sort + grid/list + loading/empty/error + pull-to-refresh) dùng `CommunityFeedProvider`
- [X] T018 [P] [US1] Tạo `lib/features/community/presentation/widgets/post_card.dart` (ảnh cover qua `ClosyNetworkImage`, badge `hidden`, video indicator)
- [X] T019 [US1] Tạo `lib/features/community/providers/post_detail_provider.dart` (fetch detail; xử lý hidden→badge nếu là tác giả)
- [X] T020 [US1] Tạo `lib/features/community/presentation/post_detail_screen.dart` (outfit cover + tên; media grid/video; nội dung; 404 → thông báo)
- [X] T021 [P] [US1] Test `test/community_feed_test.dart`: parse `Post` (nested user, lowercase), feed provider load-more/dedupe, detail hidden

**Checkpoint**: US1 hoàn chỉnh (MVP).

---

## Phase 4: User Story 2 - Soạn/sửa/xóa bài (Priority: P1)

**Goal**: Tạo bài `outfit` (chọn bộ phối) hoặc `media` (ảnh/video) + nội dung; sửa/xóa bài của mình.

**Independent Test**: Tạo bài outfit + media (1–3 ảnh + 1 video), validate bài trống, sửa nội dung, xóa.

- [X] T022 [US2] Tạo `lib/features/community/providers/post_composer_provider.dart` (postType, content, title, outfitId, media[], validate, upload signature→Cloudinary, submit POST/PUT)
- [X] T023 [US2] Tạo `lib/features/community/presentation/post_composer_screen.dart` (form + chọn loại + media picker + progress + lỗi; điều hướng về feed/chi tiết sau khi đăng)
- [X] T024 [P] [US2] Tạo `lib/features/community/presentation/widgets/outfit_picker_sheet.dart` (chọn outfit từ API outfits hiện có)
- [X] T025 [P] [US2] Thêm chọn media (ảnh qua `pickMultiImage`, video qua `pickVideo`) + validate (≤10 tệp, ảnh ≤10MB, video ≤100MB/60s) trong `lib/features/community/providers/post_composer_provider.dart`
- [X] T026 [P] [US2] Test `test/community_composer_test.dart`: validate (thiếu outfitId/media/nội dung; vượt giới hạn) + build DTO đúng

**Checkpoint**: US1 + US2 hoạt động độc lập.

---

## Phase 5: User Story 3 - Thích & danh sách người thích (Priority: P2)

**Goal**: Like/unlike optimistic + danh sách người thích phân trang.

**Independent Test**: Like → icon/số đổi ngay; mở danh sách người thích phân trang.

- [X] T027 [US3] Thêm like optimistic vào feed/detail provider: `lib/features/community/providers/community_feed_provider.dart` + `post_detail_provider.dart` (rollback khi lỗi; đồng bộ 2 nơi)
- [X] T028 [US3] Tạo `lib/features/community/presentation/widgets/post_likes_sheet.dart` (phân trang `getPostLikes`, hồ sơ từng user)
- [X] T029 [P] [US3] Test `test/community_like_test.dart`: optimistic + rollback, parse likes phân trang

**Checkpoint**: US1–US3 độc lập.

---

## Phase 6: User Story 4 - Bình luận phân cấp (Priority: P2)

**Goal**: Bình luận gốc (mới→cũ), trả lời (cũ→mới), sửa/xóa; placeholder "Bình luận đã bị xóa".

**Independent Test**: Gửi gốc, trả lời, sửa, xóa gốc còn reply; kiểm tra thứ tự + placeholder.

- [X] T030 [US4] Tạo `lib/features/community/providers/comments_provider.dart` (roots mới→cũ, replies cũ→mới theo root; add/update/delete; replyCount)
- [X] T031 [US4] Tạo `lib/features/community/presentation/widgets/comment_tile.dart` + tích hợp khu vực/modal bình luận vào `post_detail_screen.dart`
- [X] T032 [P] [US4] Test `test/community_comments_test.dart`: thứ tự, gốc bị xóa còn reply (`isDeleted`), cập nhật `commentCount`

**Checkpoint**: US1–US4 độc lập.

---

## Phase 7: User Story 5 - Theo dõi & hồ sơ công khai (Priority: P3)

**Goal**: Follow/unfollow optimistic; hồ sơ công khai (stats + bài, self thấy `hidden`); danh sách follow + lọc.

**Independent Test**: Follow trên thẻ/profile; mở `/users/{username}`; mở danh sách follow lọc `q`.

- [X] T033 [US5] Tạo `lib/features/community/providers/user_social_provider.dart` (follow optimistic + rollback; public profile; follows list theo type/q/phân trang)
- [X] T034 [US5] Tạo `lib/features/community/presentation/public_profile_screen.dart` (hồ sơ + stats + bài viết; badge `hidden` khi `isMe`; nút follow ẩn khi `isMe`)
- [X] T035 [P] [US5] Tạo `lib/features/community/presentation/widgets/follow_button.dart` (tái dùng trên post_card + profile) + `user_follows_sheet.dart` (lọc + relation)
- [X] T036 [P] [US5] Test `test/community_social_test.dart`: follow optimistic, parse `PublicProfile`/`FollowUser` (nested `user`, `relation`)

**Checkpoint**: US1–US5 độc lập.

---

## Phase 8: User Story 6 - Tìm kiếm (Priority: P3)

**Goal**: Tìm kiếm users + posts (30 ngày), 2 khối phân trang độc lập.

**Independent Test**: Nhập từ khóa → 2 khối kết quả; đổi filter users/posts.

- [X] T037 [US6] Tạo `lib/features/community/providers/community_search_provider.dart` (query + users/posts + phân trang riêng)
- [X] T038 [US6] Tạo `lib/features/community/presentation/community_search_screen.dart` (2 khối, debounce, empty/loading/error)
- [X] T039 [P] [US6] Test `test/community_search_test.dart`: parse `SearchResult`, phân trang 2 khối độc lập

**Checkpoint**: Toàn bộ user story độc lập.

---

## Phase 9: Polish & Cross-Cutting Concerns

- [X] T040 [P] Đồng bộ `sharePath` (`/community/posts/{publicId}`) với route chi tiết (mở link chia sẻ trong app)
- [X] T041 Chạy `flutter analyze` (0 issues) + `flutter test` liên quan; sửa mọi vấn đề
- [X] T042 Chạy `quickstart.md` QS-001..QS-007 trên **Chrome** + **Android**; ghi kết quả
- [X] T043 [P] Cập nhật `docs/work-log-<yyyy-mm-dd>.md` (spec 011, task xong/còn, file mới/sửa, việc cần user)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: bắt đầu ngay
- **Foundational (Phase 2)**: phụ thuộc Setup — **CHẶN** mọi user story
- **User Stories (Phase 3+)**: đều phụ thuộc Foundational; chạy tuần tự P1→P1→P2→P2→P3→P3 hoặc song song nếu đủ người
- **Polish (Phase 9)**: sau khi các story mong muốn xong

### User Story Dependencies

- **US1 (P1)**: cần T005–T011, T014–T018; độc lập.
- **US2 (P1)**: cần Foundational + US1 (post_card/detail để điều hướng sau đăng); T022–T026.
- **US3 (P2)**: cần Foundational + US1 (feed/detail provider); T027–T029.
- **US4 (P2)**: cần Foundational + US1 (detail); T030–T032.
- **US5 (P3)**: cần Foundational + US1 (post_card); T033–T036.
- **US6 (P3)**: cần Foundational; T037–T039.

### Within Each User Story

- Model/repo trước provider; provider trước UI; UI trước test.

### Parallel Opportunities

- T002, T003, T004 (Setup) song song
- T006, T007, T008, T009, T012, T013 (Foundational) song song
- T018, T021 (US1) song song
- T024, T025, T026 (US2) song song
- T029 (US3), T032 (US4), T036 (US5), T039 (US6) song song theo phase
- T040, T043 (Polish) song song

---

## Parallel Example: User Story 1

```bash
Task: "T018 [US1] post_card.dart"
Task: "T021 [US1] test/community_feed_test.dart"
```

---

## Implementation Strategy

### MVP First (US1)

1. Phase 1 Setup → Phase 2 Foundational (CRITICAL)
2. Phase 3 US1 → **DỪNG & KIỂM CHỨNG** (QS-001) → demo (xem feed/detail là giá trị đầu tiên)

### Incremental Delivery

1. Setup + Foundational → nền tảng
2. US1 → QS-001 → demo
3. US2 → QS-002 → demo
4. US3 → QS-003; US4 → QS-004; US5 → QS-005; US6 → QS-006
5. Polish: analyze/test + QS đầy đủ (QS-007 guest/lỗi) + work-log

---

## Notes

- [P] = khác file, không phụ thuộc
- Ảnh qua `ClosyNetworkImage`; video qua `video_player`; không dùng `Image.network` cho list/grid
- Guest đọc công khai; ghi cần đăng nhập (T014)
- Admin moderation ngoài phạm vi v1
- Không hardcode; dùng `ApiClient`/`CloudinaryService` hiện có
- FR-022: models KHÔNG khai báo field resale/transfer (`items`, `totalPrice`, `contactInfo`, `transferState`, `buyerUserId`, `soldAt`, ...) — kiểm tra khi review
