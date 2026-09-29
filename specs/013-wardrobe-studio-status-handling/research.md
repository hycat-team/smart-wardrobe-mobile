# Phase 0 Research: Wardrobe Default Landing, Studio Canvas & AI Analysis Status Handling

**Feature**: `013-wardrobe-studio-status-handling` | **Date**: 2026-09-28

Nguồn sự thật: `D:\_HYCAT\smart-wardrobe-fe\src\features\ai-stylist\utils\outfit-canvas-layout.ts` (529 dòng, đã đọc toàn bộ),
`D:\_HYCAT\smart-wardrobe-be\specs\023-analyze-status-handling\frontend-guide.md` (đã đọc toàn bộ),
code mobile hiện tại (`canvas_layout.dart`, `wardrobe_*`, `outfit_studio_*`, `app_router.dart`).

---

## R1 — Mô hình canvas giải phẫu của FE (nguồn sao chép)

- **Decision**: Port nguyên bảng số FE sang `canvas_layout.dart` mobile, giữ nguyên giá trị:
  - `ROLE_COORDINATES_SEPARATE`: headwear (0,-330,s80,z8), top (0,-140,s100,z5), outerwear (-25,-145,s105,z7), bottom (0,110,s100,z4), footwear (0,295,s80,z3), accessory (-240,40,s85,z9), other (250,180,s75,z2), fullbody-fallback (0,-15,s105,z5).
  - `ROLE_COORDINATES_FULLBODY`: headwear (0,-330,s80,z8), fullbody (0,-15,s105,z5), outerwear (-25,-130,s105,z7), footwear (0,295,s80,z3), accessory (-240,20,s85,z9), other (250,170,s75,z2) (+ top/bottom fallback).
  - `SECONDARY_ACCESSORY_COORDINATES`: (240,-100), (240,80), (-240,-120), scale 75, z9; món thứ 5+ → `x:240, y:80+(n-1)*60`.
  - `ROLE_BOUNDING_BOX_RATIOS`: headwear 1.8x1.4, top 2.1x2.1, outerwear 2.3x2.3, bottom 1.9x2.3, fullbody 2.1x3.2, footwear 1.8x1.3, accessory 1.6x1.6, other 2.0x2.0. Kích thước hiển thị = `placement.scale × ratio`.
  - Z-order: accessory 9 > headwear 8 > outerwear 7 > top/fullbody 5 > bottom 4 > footwear 3 > other 2 (khớp FR-008).
  - `normalizeFashionRole(rawRole, categorySlug)`: khớp từ khóa VI/EN theo thứ tự headwear → fullbody → outerwear → top → bottom → footwear → accessory → other; rỗng/không khớp thì fallback theo `categorySlug` (`ao-khoac`, `ao`/`ao-*`, `quan`/`vay-*`, `giay-*`, `phu-kien*`, `dam`, `mu`/`non`…).
  - `detectCompositionType`: có fullbody → `FULLBODY`; có top/bottom → `SEPARATE_PIECES`; còn lại → `INCOMPLETE`.
  - `resolveCanvasOutfitItems`: fullbody ⇒ loại top/bottom; dedupe mỗi vai trò chính giữ 1 (trừ accessory/other); accessory thứ 2+ dùng bảng so le; `scale` hiệu dụng = `placement.scale × scaleMultiplier`.
  - `restoreCanvasOutfitItem` (legacy): vai trò thân trên (top/headwear/outerwear/fullbody) mà `y > 0` ⇒ đảo dấu; `x == ±1` mà default.x == 0 ⇒ x = 0; outerwear `x == 25` ⇒ -25; footwear `y == 305` ⇒ 295; gần gốc (|x|<2, |y|<2) mà default khác gốc ⇒ dùng default.
- **Rationale**: Spec FR-005..FR-011 yêu cầu "tương thích chuẩn Web"; sao chép số liệu loại bỏ sai lệch thị giác giữa 2 nền tảng.
- **Alternatives considered**: Giữ `roleSlot` cũ + chỉnh số thủ công — loại (không khớp FE, vẫn vuông 200×200).

## R2 — Chiến lược canvas mobile (thay thế slot cũ)

- **Decision**:
  1. Mở rộng `CanvasItem` (`outfit_models.dart`): thêm `baseScale` (placement.scale FE, vd 100), `boxRatioW/boxRatioH` (tỉ lệ FE). Render (`outfit_studio_screen.dart:1051-1072`, hiện `itemSize = 200 × scale` vuông) đổi sang `width = baseScale × boxRatioW × scale × fitK`, `height = baseScale × boxRatioH × scale × fitK` (`scale` giữ nguyên là zoom người dùng; `fitK` là hệ số vừa-khung).
  2. Thay `roleSlot` bằng bảng FE (R1) cho cả 2 luồng nạp: `loadFromAIRecommendation` (`outfit_studio_provider.dart:227-260`) và `loadIntoStudio` (`outfits_list_provider.dart:248-311`); port `restoreCanvasOutfitItem` cho nhánh legacy (thay logic "mọi món ở gốc tọa độ" hiện tại).
  3. Giữ `layoutCanvasItems` (clamp lề 8px + tách chồng lấn <80px + 1 món ra giữa) làm hậu-kỳ; **bổ sung** bước vừa-khung: tính bbox toàn set → `fitK = min(w/bboxW, h/bboxH, 1)` + tịnh tiến về tâm (đáp SC-004, edge màn hình nhỏ; FE dùng `scaleMultiplier`, mobile dùng `fitK` tương đương).
  4. `INCOMPLETE` → dựng như `SEPARATE_PIECES` với vai trò hiện có (đã chốt clarify Q3).
  5. Giữ `normalizeRole` hiện tại (đã tương đương FE: cùng thứ tự outerwear→headwear→footwear→fullbody→bottom→top→accessory, cùng fragment VI) — chỉ bổ sung từ khóa còn thiếu khi đối chiếu (`beanie/bucket/sandal/boot/dep/lien/hoodie/len/phukien/that-lung/khan/trang-suc`, slug `vay-lien/chan-vay/giay-*/phu-kien-*/ao-*`).
- **Rationale**: Tái dùng tối đa code đã kiểm thử (`normalizeRole`, clamp/de-overlap); thay đúng phần sai (tọa độ + khung vuông).
- **Alternatives considered**: Viết module canvas mới — loại (trùng lặp provider/render hiện có).

## R3 — Hợp đồng BE 023 (mobile chỉ đọc, không sửa BE)

- **Decision**: Áp dụng nguyên văn `frontend-guide.md`:
  - `POST /api/v1/wardrobe-items/{id}/retry-analysis`, body `{ "categoryId": "<uuid>" }` (**bắt buộc** khi `needsReview`, tùy chọn khi `failed` lỗi tạm thời); trả `data.status = 3` + `taskId` mới → subscribe SSE như luồng upload.
  - Cấm gọi `confirm-review` (đã gỡ, 404) — mobile hiện không gọi API này (grep 0 kết quả) nên không cần xóa.
  - Reason codes: `uncertain_category` (needs_review, retry bắt buộc kèm categoryId) | `multiple_items_detected` / `full_body_outfit_detected` (failed, **cấm retry**, hướng dẫn chụp ảnh khác) | `analysis_temporary_error` / `auto_retry_exceeded` (failed, cho retry). Reason chỉ nằm ở `fashionItem.reviewReason` / `fashionItem.processingErrorReason` (camelCase; BE đã chuyển từ snake_case).
  - SSE payload `{ itemId, status, total, index, data, error }`; `error` là **mã** khi failed; reconnect thì subscribe lại + khử trùng theo `itemId`; realtime best-effort → refetch khi mở lại/kéo làm mới sau ~10s không sự kiện.
  - Mobile `WardrobeItem.status` số nguyên (3/0/4/5) giữ nguyên; hiển thị theo tên trạng thái, không hardcode số ở UI mới (khớp lưu ý BE).
- **Rationale**: Spec FR-012..FR-017 + Assumptions đã chốt BE triển khai đủ; mobile tuân thủ checklist frontend BE (§6).
- **Alternatives considered**: Tự suy diễn API — loại (hiến pháp II: không bịa endpoint).

## R4 — Mở rộng model/provider wardrobe mobile

- **Decision**:
  - `FashionItemModel.fromJson` + `copyWith`: thêm `reviewReason`, `processingErrorReason` (đọc camelCase trước, snake_case dự phòng — BE đã camelCase nhưng giữ fallback an toàn).
  - `WardrobeRepository.retryAnalysis({required id, String? categoryId})` → trả `taskId` (parse `data.taskId`, fallback `data.id`); lỗi 400 hiển thị message BE (thiếu category / sai trạng thái / ảnh không hợp lệ).
  - `WardrobeNotifier`: `submitNeedsReview({id, categoryId})` + `retryFailedAnalysis({id})`; khóa bấm lặp theo từng item (`_retryingIds: Set<String>`, theo edge-case double-tap + mẫu `isUploading` của spec 012); sau khi có `taskId` thì `_subscribeToTask` lại (tái dùng SSE hiện có) — SSE handler đã map `needs_review`→5 (dòng 363), chỉ cần bổ sung thông báo theo mã lý do.
  - UI: badge trạng thái trên card tủ đồ (tái dùng màu hiện có `needsReview` ở `wardrobe_screen.dart:1047-1058`); màn chi tiết `item_detail_screen.dart` thêm khối theo mã lý do (chọn category + gửi lại / ẩn retry + hướng dẫn chụp ảnh khác / nút Thử lại); ngăn kéo Studio: món processing hiển thị mờ + huy hiệu, không cho chọn (đã chốt clarify Q4).
- **Rationale**: Tận dụng SSE + safety-poll hiện có; thay đổi cô lập trong feature wardrobe.
- **Alternatives considered**: Dựng provider riêng cho review — loại (trùng SSE/subscription hiện có).

## R5 — Điều hướng mặc định về Wardrobe (US1)

- **Decision**: `kPostLoginRoute = '/wardrobe'` + nhánh redirect sau-auth (dòng ~131) `return '/wardrobe'`; áp dụng đồng nhất Web + Android, kể cả khôi phục phiên (đã chốt clarify Q2), thay thế default Community của spec 012. Giữ `pendingRedirect`, guard `isPublicCommunityPage`, redirect `/home → /community`.
- **Rationale**: Thay đổi 2 dòng, rủi ro thấp, có test router bao phủ.
- **Alternatives considered**: Chỉ đổi trên Web — loại (theo clarify Q2).

## R6 — Gỡ SnackBar thành công khi lưu outfit (US4)

- **Decision**: Xóa SnackBar thành công tại `outfit_studio_screen.dart:176-182` (dialog lưu) và `:955-965` (lưu gợi ý AI); giữ SnackBar **lỗi** + điều hướng `context.push('/outfits')` ngay sau lưu (đã chốt clarify Q1). Khi implement, grep toàn bộ `showSnackBar` trong `features/outfit_studio` + `features/stylist` để không sót nhánh lưu từ AI Stylist.
- **Rationale**: Đúng FR-003/FR-004 + Quiet Luxury non-intrusive.
- **Alternatives considered**: Thay bằng banner nhẹ — loại (spec yêu cầu gỡ hoàn toàn).

## R7 — Kiểm thử & DoD

- **Decision**: Unit test thuần-Dart cho `canvas_layout.dart` (bảng tọa độ, normalize, dedupe/fullbody-exclusion, restore legacy, fit-khung); provider test `retryAnalysis` bằng repository fake (thành công/cấm retry/thiếu category); widget test badge + nút retry + khóa double-tap; cập nhật test router (`/wardrobe` mặc định). `flutter analyze` 0 issues + QS trên Chrome và Android thật.
- **Rationale**: Theo hiến pháp I (verify-first) và mẫu spec 009/012.

---

**Output**: Mọi `NEEDS CLARIFICATION` đã giải quyết (FR + BE guide + FE source đều cụ thể); sẵn sàng Phase 1.
