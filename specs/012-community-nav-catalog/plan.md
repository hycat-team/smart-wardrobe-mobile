# Implementation Plan: Community Home, Bulk Add & System Catalog Admin

**Branch**: `012-community-nav-catalog` | **Date**: 2026-09-27 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/012-community-nav-catalog/spec.md`

## Summary

Bốn thay đổi trên app mobile Closy (một spec, nhiều story độc lập):
1. **Điều hướng**: thay tab Home bằng **Community**, đổi chỗ Community ↔ Wardrobe → thứ tự **[Tủ đồ, Cộng đồng, Phối đồ AI, Stylist AI, Hồ sơ]**; ẩn Home; `/home` redirect → `/community`.
2. **Nạp nhiều món cùng lúc**: chọn **nhiều ảnh** (`pickMultiImage`) → upload từng ảnh lên Cloudinary → batch-upload; xử lý độc lập từng ảnh + tiến trình + hạn mức gói.
3. **Tủ đồ hệ thống**: giữ tính năng; **ẩn món thiếu ảnh** (hiện 3 món `imageUrl` rỗng) → không cho thêm; BE bổ sung ảnh mẫu.
4. **Fix Google login**: mỗi tài khoản Google vào **đúng** tài khoản Closy (hiện nhiều tài khoản GG vào cùng 1 tài khoản).
5. **Việt hoá toàn bộ UI** (US6): thay chuỗi tiếng Anh (nav, app bar, nút, hint, thông báo) sang tiếng Việt.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x (`sdk: '>=3.0.0 <4.0.0'`)

**Primary Dependencies**: `flutter_riverpod ^2.5.1`, `go_router ^14.2.0`, `dio ^5.4.3`, `image_picker ^1.1.2` (**dùng `pickMultiImage`**), `google_sign_in ^7.2.0` (+`_web`), `video_player`, `google_fonts`, `flutter_secure_storage`. **Không thêm dependency mới** (icon Community = `Icons.public`).

**Storage**: `flutter_secure_storage` (token/session); state trong Riverpod.

**Testing**: `flutter_test` (unit/widget với `ProviderScope` overrides); integration test lên BE local.

**Target Platform**: Android + Web (dev Chrome).

**Project Type**: mobile-app (Flutter feature-first).

**Performance Goals**: nạp N ảnh hiển thị tiến trình; thao tác nav tức thời; không chặn UI khi upload nhiều ảnh.

**Constraints**: giữ cô lập phiên theo tài khoản (không rò rỉ A→B); Việt hoá chỉ **chuỗi hiển thị** (không đổi route/logic); giữ `kotlin.incremental=false`; UTF-8 khi sửa file.

**Scale/Scope**: `lib/shared/widgets/scaffold_with_nav_bar.dart`, `lib/core/router/app_router.dart`, `lib/features/home/**` (ẩn), `lib/features/wardrobe/{providers,data,presentation}` (multi-upload, catalog filter), `lib/features/auth/**` (Google login fix), và **rà chuỗi tiếng Việt trên toàn bộ màn người dùng thấy**.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Nguyên tắc (constitution) | Trạng thái | Ghi chú |
|---|---|---|
| I. Spec-Driven & Verify-First | PASS | `/speckit.specify → clarify → plan`; kết thúc analyze/test + work-log |
| II. Feature-First + Riverpod | PASS | Sửa trong feature tương ứng; `ref.watch/read`; state null-safe |
| III. Không Mock Khi Đã Có API | PASS | Dùng API thật (wardrobe/system-catalog/auth) |
| IV. Quiet Luxury & Media | PASS | Icon tab đồng nhất; ảnh qua `ClosyNetworkImage`; media video không đổi |
| V. Gotcha Windows & Build | PASS | UTF-8; giữ `kotlin.incremental=false` |
| VI. An Toàn Phát Hành & Secrets | PASS | Không secret mới; release flags không đổi |

**Kết luận**: Không vi phạm — không cần Complexity Tracking.

**Re-check sau Phase 1**: PASS (data-model/contracts không phát sinh vi phạm).

## Project Structure

### Documentation (this feature)

```text
specs/012-community-nav-catalog/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── ui-behavior-contracts.md
└── tasks.md            # /speckit.tasks
```

### Source Code (repository root)

```text
lib/shared/widgets/scaffold_with_nav_bar.dart   # đổi 5 tab → [Tủ đồ, Cộng đồng, Phối đồ AI, Stylist AI, Hồ sơ]; bỏ Home; icon Community
lib/core/router/app_router.dart                 # bỏ branch /home khỏi shell; thêm redirect /home → /community; giữ /community + /users/:username
lib/features/home/**                            # ẩn Home (không còn là tab; có thể giữ file hoặc bỏ)
lib/features/wardrobe/providers/upload_wardrobe_provider.dart   # multi-upload (pickMultiImage + xử lý từng ảnh + tiến trình)
lib/features/wardrobe/presentation/wardrobe_screen.dart         # bottom sheet chọn ảnh: thêm "chọn nhiều"; hiển thị tiến trình
lib/features/wardrobe/providers/system_catalog_provider.dart    # ẩn món thiếu ảnh (isInMyWardrobe/catalog list)
lib/features/wardrobe/presentation/system_catalog_screen.dart   # ẩn/disable món thiếu ảnh
lib/features/auth/providers/auth_provider.dart                  # clear session trước login; fallback
lib/features/auth/data/auth_repository.dart                     # (nếu cần) đảm bảo ghi đè token
lib/features/auth/presentation/widgets/google_sign_in_button.dart # signOut/disconnect trước authenticate để chọn tài khoản
lib/features/auth/presentation/login_screen.dart                # chuỗi tiếng Việt
# Rà chuỗi tiếng Việt: marketplace, outfit_studio, stylist, profile, wardrobe, privacy, payment...
test/community_*  (đã có); test/nav_test.dart (mới); test/upload_bulk_test.dart (mới); test/auth_google_test.dart (mở rộng)
```

**Structure Decision**: Giữ kiến trúc feature-first; các sửa nằm rải ở `shared/`, `core/router`, `features/{wardrobe,auth}` và rà soát chuỗi trên `features/*`. Không tạo module mới.

## Complexity Tracking

> Không có vi phạm constitution — bảng này để trống.
