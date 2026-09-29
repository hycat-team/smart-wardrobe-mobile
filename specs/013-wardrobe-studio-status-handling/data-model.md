# Data Model: 013-wardrobe-studio-status-handling

**Feature**: `013-wardrobe-studio-status-handling` | **Date**: 2026-09-28

## 1. WardrobeItem (mở rộng, tương thích BE 023)

Thuộc `lib/features/wardrobe/models/wardrobe_models.dart`. `status` số nguyên giữ nguyên.

| Field | Type | Nguồn | Ghi chú |
|---|---|---|---|
| `status` | `int` | BE | `0 inWardrobe` · `3 processing` · `4 failed` · `5 needsReview` |
| `fashionItem.reviewReason` | `String?` | `data.fashionItem` | Mã rà soát; `needs_review` luôn là `uncertain_category` |
| `fashionItem.processingErrorReason` | `String?` | `data.fashionItem` | Mã lỗi khi `failed`; **không** ở cấp root |
| `taskId` | `String?` | batch/retry response | Dùng subscribe SSE; khử trùng theo `itemId` |

Validation:
- Parse camelCase trước (`reviewReason`), snake_case dự phòng (`review_reason`) — BE đã camelCase.
- Mã lạ ngoài bảng 5 mã ⇒ message mặc định, không so khớp chuỗi (theo BE guide §2.5).
- UI hiển thị theo **tên trạng thái**, không hardcode số ở widget mới.

State transitions (theo BE state machine):
```text
processing → completed | failed | needs_review
failed --retry-analysis--> processing   (trừ ảnh không hợp lệ: backend 400)
needs_review --retry-analysis+categoryId--> processing → completed | failed
```

## 2. ReasonCode (enum nội bộ, phục vụ gate UI)

| Mã | Nhóm | Trạng thái | Retry | UI |
|---|---|---|---|---|
| `uncertain_category` | review | needs_review | ✅ bắt buộc `categoryId` | Chọn category + "Gửi phân tích lại" |
| `multiple_items_detected` | error | failed | ❌ | "Ảnh có nhiều món" + gợi ý ảnh khác, ẩn retry |
| `full_body_outfit_detected` | error | failed | ❌ | "Ảnh toàn thân" + gợi ý cận cảnh, ẩn retry |
| `analysis_temporary_error` | error | failed | ✅ | Nút "Thử lại" |
| `auto_retry_exceeded` | error | failed | ✅ | Nút "Thử lại" |

## 3. StudioCanvasItem (mở rộng `CanvasItem`)

| Field | Type | Nguồn | Ghi chú |
|---|---|---|---|
| `positionX/positionY` | `double` | FE placement / saved | Độ lệch so với tâm canvas |
| `baseScale` | `double` (mới) | FE `placement.scale` | vd 100; nhân với ratio ra px hiển thị |
| `boxRatioW/boxRatioH` | `double` (mới) | FE `ROLE_BOUNDING_BOX_RATIOS` | vd bottom 1.9×2.3 |
| `scale` | `double` (giữ) | user zoom | Mặc định 1.0 |
| `layerOrder` | `int` (giữ) | FE `zIndex` | 9 accessories … 2 other |
| `role` | `String` (giữ) | `normalizeRole` | Chuẩn hóa theo R1 |

Kích thước render: `w = baseScale × boxRatioW × scale × fitK`, `h = baseScale × boxRatioH × scale × fitK`.

## 4. OutfitComposition

`SEPARATE_PIECES` | `FULLBODY` | `INCOMPLETE` (= SEPARATE_PIECES với vai trò hiện có, theo clarify Q3).

Quy tắc: có fullbody ⇒ loại top/bottom (FR-010); dedupe vai trò chính giữ 1 (trừ accessory/other); accessory 2+ so le cánh đối diện.

## 5. Quan hệ

- `WardrobeNotifier` --quản lý--> `WardrobeItem[]` --subscribe--> SSE `taskId`; `retryAnalysis` trả `taskId` mới → subscribe lại.
- `OutfitStudioProvider`/`OutfitsListProvider` --dựng--> `CanvasItem[]` qua `canvas_layout.dart` (thuần logic, test được).
- Router: `kPostLoginRoute` + redirect → `/wardrobe`; giữ `pendingRedirect`.
