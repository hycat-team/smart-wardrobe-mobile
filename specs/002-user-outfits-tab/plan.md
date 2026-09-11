# Implementation Plan: User Outfits Tab

**Branch**: `002-user-outfits-tab` | **Date**: 2026-09-11 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/002-user-outfits-tab/spec.md`

## Summary

Đưa danh sách outfits của user ra bottom nav: tái dùng nguyên `OutfitsListScreen` vào nhánh shell mới `/my-outfits` giữa Stylist và Profile, thêm tab Outfits (icon `style_*`, nhãn "Outfits"), Profile dời sang index 4. Thêm cờ `showBackButton` để ẩn nút back trong ngữ cảnh tab. Chi tiết trong [research.md](./research.md), [data-model.md](./data-model.md), [contracts/navigation.md](./contracts/navigation.md), [quickstart.md](./quickstart.md).

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x

**Primary Dependencies**: `go_router` 14.x (`StatefulShellRoute.indexedStack`), `flutter_riverpod` 2.x (`outfitsListProvider` hiện có)

**Storage**: Không thêm — dùng API + provider hiện có

**Testing**: `flutter_test` + kiểm chứng tay theo `quickstart.md`; `flutter analyze` sạch lỗi mới

**Target Platform**: Android + iOS (+ Flutter Web tương thích)

**Project Type**: mobile-app (Flutter, `lib/features/outfit_studio`, `lib/core/router`, `lib/shared/widgets`)

**Performance Goals**: Mở tab hiện cache lưới ngay (provider đã fetch), ảnh lưới dùng `memCacheWidth/Height` hiện có

**Constraints**: Index tab và thứ tự `StatefulShellBranch` phải đồng bộ tuyệt đối; không đổi nhãn/hành vi 4 tab cũ; file tiếng Việt UTF-8

**Scale/Scope**: ~3 file sửa (`app_router.dart`, `scaffold_with_nav_bar.dart`, `outfits_list_screen.dart`), 0 model/provider mới

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] Scope đúng spec đã duyệt (tab + nhánh shell + cờ back); không sửa nhãn 4 tab cũ, không đụng luồng Studio/Stylist.
- [x] Không phá gotcha: bottom sheet chi tiết đã bọc scroll; route `/outfits` cũ giữ nguyên.
- [x] Bảo mật: tab nằm trong shell chịu redirect auth; dữ liệu theo token hiện tại + reset session bao phủ.
- [x] Post-design re-check: research/data-model/contracts/quickstart nhất quán, không violation.

## Project Structure

### Documentation (this feature)

```text
specs/002-user-outfits-tab/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
│   └── navigation.md    # Tab order + routes + widget contract
├── checklists/
│   └── requirements.md  # Spec quality checklist
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
smart-wardrobe-mobile/
├── lib/
│   ├── core/router/app_router.dart
│   │   └── thêm StatefulShellBranch(/my-outfits) giữa stylist và profile
│   ├── shared/widgets/scaffold_with_nav_bar.dart
│   │   └── thêm nav item Outfits index 3, Profile dời sang 4
│   └── features/outfit_studio/presentation/outfits_list_screen.dart
│       └── thêm cờ showBackButton (mặc định true)
└── test/ (nếu có widget test cho tab bar)
```

**Structure Decision**: Không tạo module/file mới ngoài artifact spec; thay đổi cô lập trong 3 file UI + router hiện có.

## Complexity Tracking

> Không có violation — không điền.
