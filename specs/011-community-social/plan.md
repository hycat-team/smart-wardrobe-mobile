# Implementation Plan: Community Social trên Mobile

**Branch**: `011-community-social` | **Date**: 2026-09-27 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/011-community-social/spec.md`

## Summary

Dựng module **Community** cho app Flutter (Android + Web dev): bảng tin (explore/following, sort hot/latest), chi tiết bài (outfit/media + video), soạn/sửa/xóa bài, thích, bình luận phân cấp, theo dõi + hồ sơ công khai, tìm kiếm. Gọi thẳng API community của BE (`/api/v1`), tái dùng mô hình upload **signature → Cloudinary** (ảnh + video) và `ClosyNetworkImage`. Vào từ **Home + menu Hồ sơ** dạng route toàn màn hình (giữ 5 tab). Khách xem được nội dung công khai; thao tác ghi yêu cầu đăng nhập. Admin moderation **ngoài phạm vi v1**.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x (`sdk: '>=3.0.0 <4.0.0'`)

**Primary Dependencies**: `flutter_riverpod ^2.5.1`, `go_router ^14.2.0`, `dio ^5.4.3`, `flutter_secure_storage ^9.2.2`, `cached_network_image ^3.3.1`, `image_picker ^1.1.2`, `google_fonts ^6.2.1`; **mới: `video_player`** (phát video), (tuỳ chọn `chewie` cho UI player)

**Storage**: `flutter_secure_storage` (token Bearer); không có DB cục bộ (chỉ cache ảnh qua `cached_network_image`)

**Testing**: `flutter_test` (unit/widget với `ProviderScope` overrides); integration test gọi BE local (mẫu `test/auth_integration_test.dart`)

**Target Platform**: Android (minSdk 21+) + Web (Chrome dev); iOS ngoài phạm vi

**Project Type**: mobile-app (Flutter, feature-first layered)

**Performance Goals**: 10 bài đầu + ảnh sắc nét < 2s (SC-001); like/follow phản hồi UI < 100ms nhờ optimistic (SC-002/005)

**Constraints**: Bearer token (mobile); guest chỉ đọc; upload qua BE signature → Cloudinary (`image`/`video`); giới hạn media/rate-limit của BE; giữ `kotlin.incremental=false`; UTF-8 khi sửa file

**Scale/Scope**: Module mới `lib/features/community/**` (~5 màn + widgets), thêm route + điểm vào Home/Profile; tái dùng `ApiClient`, `CloudinaryService`, `ClosyNetworkImage`, pattern load-more/optimistic hiện có

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Nguyên tắc (constitution) | Trạng thái | Ghi chú |
|---|---|---|
| I. Spec-Driven & Verify-First | PASS | Đi qua `/speckit.specify → clarify → plan`; kết thúc analyze/test + work-log |
| II. Feature-First + Riverpod | PASS | Đặt ở `lib/features/community/**`; `Repository → Dio`; `ref.watch`/`ref.read`; state null-safe |
| III. Không Mock Khi Đã Có API | PASS | Gọi thẳng API BE; không mock/không bịa endpoint |
| IV. Quiet Luxury & Media | PASS | UI theo palette; ảnh qua `ClosyNetworkImage`; video player tối giản |
| V. Gotcha Windows & Build | PASS | UTF-8; giữ `kotlin.incremental=false` |
| VI. An Toàn Phát Hành & Secrets | PASS | Không secret mới; upload qua signature BE; release flag không đổi |

**Kết luận**: Không vi phạm — không cần Complexity Tracking.

**Re-check sau Phase 1**: vẫn PASS (data-model/contracts/quickstart: no-mock, Bearer, media qua ClosyNetworkImage/video_player).

## Project Structure

### Documentation (this feature)

```text
specs/011-community-social/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── community-mobile.md
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
lib/features/community/
├── data/
│   ├── community_repository.dart      # posts, like, comments
│   ├── user_social_repository.dart    # follow, public profile, follows
│   └── community_search_repository.dart
├── models/
│   ├── community_user.dart
│   ├── post_models.dart               # Post, OutfitBrief, PostMedia
│   ├── comment_models.dart
│   ├── profile_models.dart            # PublicProfile, FollowUser, stats
│   └── search_models.dart
├── providers/
│   ├── community_feed_provider.dart   # feed tabs/sort + infinite scroll
│   ├── post_detail_provider.dart
│   ├── post_composer_provider.dart    # create/update + upload ảnh/video
│   ├── comments_provider.dart
│   ├── user_social_provider.dart      # follow, profile, follows list
│   └── community_search_provider.dart
└── presentation/
    ├── community_feed_screen.dart
    ├── post_detail_screen.dart
    ├── post_composer_screen.dart
    ├── public_profile_screen.dart
    ├── community_search_screen.dart
    └── widgets/
        ├── post_card.dart
        ├── comment_tile.dart
        ├── media_grid.dart
        ├── community_video_player.dart
        ├── follow_button.dart
        └── outfit_picker_sheet.dart

lib/core/router/app_router.dart        # + routes: /community, /community/posts/:id, /community/create, /community/search, /users/:username
lib/features/home/presentation/home_screen.dart     # + entry (banner/quick action)
lib/features/profile/presentation/profile_screen.dart # + menu "Cộng đồng"
lib/core/services/cloudinary_service.dart           # + upload video (resourceType)
test/community_*.dart                               # unit/widget tests
```

**Structure Decision**: Giữ kiến trúc feature-first hiện có; toàn bộ tính năng trong `lib/features/community/**`; chỉ sửa `app_router`, Home, Profile menu và mở rộng `CloudinaryService` cho video.

## Complexity Tracking

> Không có vi phạm constitution — bảng này để trống.
