# Contract: Mobile ↔ Backend — Community

**Feature**: `011-community-social` | **Date**: 2026-09-27
**Nguồn**: BE/FE spec `022-community-social` (`contracts/frontend-integration.md`, `community-api-contract.md`).

Base URL = `{API_BASE}/api/v1`. Envelope `{ message, data? }` — `data` **vắng** khi không có payload. Phân trang: `{ items, metadata: { page, limit, totalItems, totalPages } }` (`limit` mặc định 20, ≤100).

Auth mobile: **Bearer** access token (guest gửi không token cho endpoint optional).

## 1. Endpoint

| Method | Path | Auth | Query / Body | `data` |
|---|---|---|---|---|
| GET | `/posts` | optional | `type`=explore\|following, `sort`=hot\|latest, `postType`, `username`, `page`, `limit` | `PaginationResult<Post>` |
| GET | `/posts/{publicId}` | optional | — | `Post` (hidden→404; tác giả 200) |
| GET | `/posts/upload-signature` | user | `resourceType=image\|video` | `UploadSignatureResult` |
| POST | `/posts` | user | `CreatePostReq` | `Post` (201) |
| PUT | `/posts/{publicId}` | owner | `UpdatePostReq` | `Post` |
| DELETE | `/posts/{publicId}` | owner | — | (vắng) |
| PUT | `/posts/{publicId}/like` | user | `{ isLiked }` | (vắng) |
| GET | `/posts/{publicId}/likes` | optional | `page`, `limit` | `PaginationResult<CommunityUser>` |
| GET | `/posts/{publicId}/comments` | optional | — | `Comment[]` (không phân trang) |
| GET | `/posts/{publicId}/comments/{id}/replies` | optional | — | `Comment[]` |
| POST | `/posts/{publicId}/comments` | user | `{ content, parentCommentId? }` | `Comment` (201) |
| PUT | `/posts/{publicId}/comments/{id}` | owner | `{ content }` | `Comment` |
| DELETE | `/posts/{publicId}/comments/{id}` | owner | — | (vắng) |
| PUT | `/users/{username}/follow` | user | `{ isFollowing }` | (vắng) |
| GET | `/users/{username}` | optional | — | `PublicProfile` |
| GET | `/users/{username}/posts` | optional | `page`, `limit` | `PaginationResult<Post>` (self gồm `hidden`) |
| GET | `/users/{username}/follows` | optional | `type`=following\|followers, `q`, `page`, `limit` | `PaginationResult<FollowUser>` |
| GET | `/search` | optional | `q`, `type`=all\|users\|posts, `postType`, `page`, `limit` | `SearchResult` |

> `{id}` comment là **UUID nội bộ**; `{publicId}` post là mã công khai 32 ký tự.

## 2. Payload chính

- `CreatePostReq`: `{ postType, title?, content, outfitId?, media?[] }` — `outfit` bắt buộc `outfitId`; `media` cần `content` hoặc ≥1 media.
- `UpdatePostReq`: `{ title?, content, outfitId?, media?[] }` — **không** đổi `postType`.
- `PostMediaReq`: `{ mediaType, mediaUrl, publicId?, sortOrder }`.
- `UploadSignatureResult`: `{ signature, timestamp, apiKey, publicId, folder, resourceType }` → upload tới `https://api.cloudinary.com/v1_1/{cloud}/{resourceType}/upload`.

## 3. Response shapes

- `Post`: `id, publicId, user, postType, status, title?, content, outfit?, likeCount, commentCount, isLiked, isFollowingAuthor, sharePath, media?[], createdAt, updatedAt`.
- `Comment`: `id, user, content, parentCommentId?, replyCount, isDeleted, createdAt`.
- `FollowUser`: `{ user, relation, followedAt }`.
- `PublicProfile`: `{ user, stats:{followerCount,followingCount,postCount}, isFollowing, isMe }`.
- `SearchResult`: `{ users: PaginationResult<CommunityUser>, posts: PaginationResult<Post> }`.

## 4. Bảng lỗi

| Tình huống | HTTP | App xử lý |
|---|---|---|
| Validate/định dạng sai | 400 | Hiện `message`/`errors[0].message` (tiếng Việt) |
| Guest gọi `following`/ghi | 401 | Mời đăng nhập (lưu `pendingRedirect` → `/login`) |
| Không phải chủ | 403 | Thông báo không có quyền |
| Không tìm thấy/đã ẩn | 404 | Thông báo nội dung không khả dụng |
| Vượt rate limit | 429 | Thông báo nhẹ, không retry dồn dập |

Error body: `{ status, title?, message?, errors?[{field,message}] }` (không có `data`).

## 5. Giới hạn & hành vi

- Giới hạn: title ≤150, content ≤5000, comment ≤1000, ≤10 media, ảnh ≤10MB, video ≤100MB/≤60s.
- Rate limit: bài ≤10/giờ, comment ≤60/giờ, follow ≤200/giờ, like ≤600/giờ.
- Feed/profile chỉ trả `published`; tác giả thấy bài `hidden` của mình (badge); không trả `deleted`.
- Like/Follow idempotent; tự follow chính mình → 400.
- Comment gốc mới→cũ; reply cũ→mới; gốc bị xóa còn reply → `isDeleted=true`, `content=""`.
- Search: user theo follower giảm dần; post chỉ trong **30 ngày** gần nhất, `published`.
- `sharePath` = `/community/posts/{publicId}` (khớp route chi tiết app).
