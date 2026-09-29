# Implementation Plan: Wardrobe Default Landing, Studio Canvas Presentation & AI Analysis Status Handling

**Branch**: `013-wardrobe-studio-status-handling` | **Date**: 2026-09-28 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/013-wardrobe-studio-status-handling/spec.md` (đã clarify 4 câu, checklist 16/16).

## Summary

Bốn thay đổi độc lập trên app mobile Closy:
1. **Điều hướng (US1)**: điểm đến mặc định sau đăng nhập/khôi phục phiên → `/wardrobe` (Web + Android), thay default Community của spec 012.
2. **Trạng thái phân tích AI (US2)**: áp dụng hợp đồng BE 023 — 4 trạng thái (`processing/completed/failed/needs_review`), mã lý do trong `fashionItem`, `retry-analysis` kèm `categoryId` (bắt buộc khi needsReview), cấm retry ảnh không hợp lệ, khóa double-tap.
3. **Studio Canvas (US3)**: port nguyên mô hình giải phẫu FE (`outfit-canvas-layout.ts`) — bảng tọa độ 2 chế độ, bbox theo vai trò, z-order, phụ kiện so le, loại trừ top/bottom khi fullbody, restore legacy, vừa-khung; thay slot vuông 200×200 hiện tại.
4. **Bỏ SnackBar thành công (US4)**: gỡ banner đáy màn hình khi lưu outfit, giữ thông báo lỗi + điều hướng `/outfits` ngay.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x (`sdk: '>=3.0.0 <4.0.0'`)

**Primary Dependencies**: `flutter_riverpod ^2.5.1`, `go_router ^14.2.0`, `dio ^5.4.3`, `flutter_secure_storage`, `google_fonts`. **Không thêm dependency mới.**

**Storage**: `flutter_secure_storage` (token/session); state trong Riverpod (`StateNotifierProvider`).

**Testing**: `flutter_test` — unit thuần-Dart cho `canvas_layout.dart`, provider test với repository fake, widget test badge/retry/router; integration lên BE local khi có.

**Target Platform**: Android + Web (dev Chrome `--web-port=8081`).

**Project Type**: mobile-app (Flutter feature-first).

**Performance Goals**: SC-001 redirect <300ms; SC-002 chuyển hướng sau lưu <500ms; canvas resolve O(n), fit O(n); SSE cập nhật tức thời không refetch toàn trang.

**Constraints**: Giữ nguyên `WardrobeItem.status` số nguyên (3/0/4/5); UI theo tên trạng thái. Việt hoá chỉ chuỗi hiển thị (không đổi route/logic). Giữ `kotlin.incremental=false`. UTF-8 khi sửa file. Cấm `confirm-review` (BE đã gỡ). Không sửa BE/FE từ repo mobile (chỉ đọc tham khảo).

**Scale/Scope**: `lib/core/router/app_router.dart`, `lib/features/wardrobe/{models,data,providers,presentation}`, `lib/features/outfit_studio/{layout,models,providers,presentation}`, `test/**`. Canvas hiển thị 450–650px chiều cao vùng vẽ.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Nguyên tắc (constitution) | Trạng thái | Ghi chú |
|---|---|---|
| I. Spec-Driven & Verify-First | PASS | `specify → clarify (4 Q) → plan`; kết thúc analyze/test + work-log |
| II. Feature-First + Riverpod | PASS | Sửa trong feature tương ứng; `ref.watch/read`; state null-safe; API xác minh từ BE guide (không bịa) |
| III. Không Mock Khi Đã Có API | PASS | Dùng `retry-analysis` thật; FE/BE chỉ đọc tham khảo, không sửa |
| IV. Quiet Luxury & Media | PASS | Gỡ snackbar thành công; badge Quiet Luxury; ảnh qua `ClosyNetworkImage` + `memCacheWidth` |
| V. Gotcha Windows & Build | PASS | UTF-8; giữ `kotlin.incremental=false` |
| VI. An Toàn Phát Hành & Secrets | PASS | Không secret mới; không đụng BE/FE; release flags không đổi |

**Kết luận**: Không vi phạm — không cần Complexity Tracking.

**Re-check sau Phase 1**: PASS (data-model/contracts không phát sinh vi phạm).

## Project Structure

### Documentation (this feature)

```text
specs/013-wardrobe-studio-status-handling/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── retry-analysis.contract.md
│   ├── canvas-layout.contract.md
│   └── status-ui-matrix.contract.md
└── tasks.md            # /speckit.tasks
```

### Source Code (repository root)

```text
lib/core/router/app_router.dart                          # kPostLoginRoute + redirect → '/wardrobe'
lib/features/wardrobe/models/wardrobe_models.dart        # reviewReason/processingErrorReason
lib/features/wardrobe/data/wardrobe_repository.dart      # retryAnalysis()
lib/features/wardrobe/providers/wardrobe_provider.dart   # submitNeedsReview/retryFailed + lock + SSE msg
lib/features/wardrobe/presentation/wardrobe_screen.dart  # badge theo mã lý do
lib/features/wardrobe/presentation/item_detail_screen.dart # khối review/retry theo mã lý do
lib/features/outfit_studio/layout/canvas_layout.dart     # bảng FE + restore + fit
lib/features/outfit_studio/models/outfit_models.dart     # CanvasItem.baseScale/boxRatioW/H
lib/features/outfit_studio/providers/outfit_studio_provider.dart   # loadFromAIRecommendation (bảng mới)
lib/features/outfit_studio/providers/outfits_list_provider.dart    # loadIntoStudio (restore mới)
lib/features/outfit_studio/presentation/outfit_studio_screen.dart  # render box chữ nhật + gỡ snackbar
test/canvas_layout_test.dart  (mới); test/wardrobe_retry_test.dart (mới); mở rộng router/widget tests
```

**Structure Decision**: Giữ kiến trúc feature-first; sửa rải ở `core/router`, `features/wardrobe`, `features/outfit_studio`. Không tạo module mới.

## Complexity Tracking

> Không có vi phạm constitution — bảng này để trống.
