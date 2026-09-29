# Phase 1 Data Model: Community Social trên Mobile

**Feature**: `011-community-social` | **Date**: 2026-09-27

Ánh xạ hợp đồng BE (đã chuẩn hoá lowercase & nested `user`). Không có DB cục bộ.

## Entities

### CommunityUser
| Field | Type | Ghi chú |
|---|---|---|
| `userId` | `String` | |
| `username` | `String` | |
| `firstName` | `String?` | |
| `lastName` | `String?` | |
| `avatarUrl` | `String?` | omitempty — có thể vắng → fallback avatar chữ cái đầu |
| `gender` | `int?` | 1=Nam, 2=Nữ, 3=Khác; `0`/vắng = không xác định |

- Getters: `displayName` (first+last → username), `initials`, `genderLabel`.

### OutfitBrief
| Field | Type |
|---|---|
| `id` | `String` |
| `name` | `String` |
| `coverImageUrl` | `String?` |

### PostMedia
| Field | Type | Ghi chú |
|---|---|---|
| `id` | `String` | |
| `mediaType` | `'image' \| 'video'` | lowercase |
| `mediaUrl` | `String` | |
| `publicId` | `String?` | |
| `sortOrder` | `int` | thứ tự hiển thị |

### Post
| Field | Type | Ghi chú |
|---|---|---|
| `id` | `String` | |
| `publicId` | `String` | dùng cho route/share |
| `user` | `CommunityUser?` | nested (breaking); có thể null |
| `postType` | `'outfit' \| 'media'` | |
| `status` | `'published' \| 'hidden' \| 'deleted'` | chỉ `published`/`hidden` xuất hiện |
| `title` | `String?` | ≤150 |
| `content` | `String` | ≤5000 |
| `outfit` | `OutfitBrief?` | có khi `outfit` |
| `likeCount` / `commentCount` | `int` | |
| `isLiked` / `isFollowingAuthor` | `bool` | `isFollowingAuthor=false` nếu là tác giả |
| `sharePath` | `String` | `/community/posts/{publicId}` |
| `media` | `List<PostMedia>` | ≤10 |
| `createdAt` / `updatedAt` | `String` | ISO |

- Getters: `coverImageUrl` (outfit cover → media[0] → null), `hasMedia`, `isHidden`, `isOwnedBy(userId)`.

### Comment
| Field | Type | Ghi chú |
|---|---|---|
| `id` | `String` | |
| `user` | `CommunityUser?` | nested |
| `content` | `String` | rỗng khi `isDeleted` còn reply; ≤1000 |
| `parentCommentId` | `String?` | vắng khi là gốc |
| `replyCount` | `int` | chỉ gốc; con = 0 |
| `isDeleted` | `bool` | hiển thị "Bình luận đã bị xóa" |
| `createdAt` | `String` | |

### FollowUser
| Field | Type | Ghi chú |
|---|---|---|
| `user` | `CommunityUser` | |
| `relation` | `'following' \| 'follower'` | khi không truyền `type` → trả cả hai |
| `followedAt` | `String` | sort mới nhất trước |

### PublicProfile (+ Stats)
| Field | Type |
|---|---|
| `user` | `CommunityUser` |
| `stats.followerCount/followingCount/postCount` | `int` |
| `isFollowing` | `bool` |
| `isMe` | `bool` |

### SearchResult
| Field | Type |
|---|---|
| `users` | `PaginationResult<CommunityUser>` (phẳng) |
| `posts` | `PaginationResult<Post>` |

## Request DTOs

- `CreatePostReq`: `postType` ('outfit'|'media'), `title?`, `content`, `outfitId?` (bắt buộc khi outfit), `media?: PostMediaReq[]`.
- `UpdatePostReq`: `title?`, `content`, `outfitId?`, `media?` — **không** có `postType`.
- `PostMediaReq`: `mediaType` ('image'|'video'), `mediaUrl`, `publicId?`, `sortOrder`.
- `AddCommentReq`: `content`, `parentCommentId?`.
- `LikePostReq`: `isLiked`. `FollowReq`: `isFollowing`.

## State classes (Riverpod `StateNotifier`)

- **CommunityFeedState**: `items`, `tab`(explore|following), `sort`(hot|latest), `postType?`, `page`, `total`, `isLoading`, `isLoadingMore`, `hasMore`, `errorMessage`.
- **PostDetailState**: `post`, `isLoading`, `errorMessage`.
- **CommentsState**: `roots`, `repliesByRoot`, `isLoading`, `isSubmitting`, `errorMessage` (thứ tự: gốc mới→cũ; reply cũ→mới).
- **PublicProfileState**: `profile`, `posts`, `postsPage`, `hasMore`, `isLoading`, `errorMessage`.
- **FollowListState**: `type`(following|followers|all), `query`, `items`, `page`, `hasMore`.
- **SearchState**: `query`, `users`, `posts`, `usersPage`, `postsPage`, `isLoading`.
- **PostComposerState**: `postType`, `content`, `title`, `selectedOutfitId`, `media[]`, `isUploading`, `progress`, `isSubmitting`, `errorMessage`.

## Validation rules (từ FR/§3.12)

- `title` ≤ 150; `content` bài ≤ 5000; bình luận (trim) ≤ 1000 & không rỗng.
- `outfit` ⇒ bắt buộc `outfitId` thuộc sở hữu user.
- `media` ⇒ `content` khác rỗng HOẶC ≥1 media; ≤10 tệp; ảnh ≤10MB; video ≤100MB & ≤60s.
- `page ≥ 1`, `limit` mặc định 20 (≤100).

## State transitions

```text
Feed: idle → loading → loaded | error; loadMore: single-flight, dedupe, stop khi hết.
Compose: idle → picking/validating → uploading(Cloudinary) → submitting(POST) → success → refresh feed.
Like/Follow: idle → optimisticApplied → (server OK) confirmed | (error) rollback.
Comment: idle → submitting → appended (gốc đầu / reply cuối) | error.
Detail: (hidden + viewer là tác giả) → 200 kèm badge; (hidden/deleted + người khác) → 404.
```

**Output**: entities + rules + transitions sẵn sàng cho `/speckit.tasks`.
