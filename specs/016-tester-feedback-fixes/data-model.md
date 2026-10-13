# Phase 1 — Data Model: Sửa lỗi theo phản hồi tester (đợt 1)

**Feature**: `016-tester-feedback-fixes` · **Date**: 2026-10-13

Đặc tả này chủ yếu sửa **hành vi hiển thị/bố cục**; chỉ có một thay đổi dữ liệu có ý nghĩa:
**bất biến (invariant) vị trí món trên canvas phải nằm trong biên**. Không thêm entity, không
đổi hợp đồng máy chủ.

---

## Entity: CanvasItem

Đại diện một món đồ đang nằm trên canvas Studio. Nguồn:
`lib/features/outfit_studio/models/outfit_models.dart:323-381`.

| Trường | Kiểu | Ghi chú |
|---|---|---|
| `id` | String | Mã tạm client |
| `fashionItemId` | String | Khoá tới món thật (lưu outfit) |
| `imageUrl` | String | Ảnh hiển thị |
| `name` | String | Nhãn hiển thị khi chọn |
| `role` | String | Tên `CanvasRole` (top/bottom/fullbody/outerwear/footwear/headwear/accessory/other/unknown) |
| `positionX` / `positionY` | double | **Lệch so với tâm canvas** (logical px) |
| `scale` | double | Hệ số phóng (clamp `0.15..3.0`) |
| `layerOrder` | int | Thứ tự lớp (nhỏ vẽ trước) |
| `baseScale` | double | Kích thước cơ sở theo vai trò (mặc định 100) |
| `boxRatioW` / `boxRatioH` | double | Tỉ lệ khung bao theo vai trò |

**Công thức kích thước hiệu dụng** (dùng ở cả render và kẹp):
```
itemScaleMultiplier = 1.25
itemW = baseScale * boxRatioW * scale * itemScaleMultiplier
itemH = baseScale * boxRatioH * scale * itemScaleMultiplier
```

### Bất biến mới (từ FR-001/FR-002/FR-003)

- **INV-1**: Với mọi món được thêm thủ công, hộp giới hạn của món (`positionX ± itemW/2`,
  `positionY ± itemH/2`) phải nằm trong vùng khả dụng: `|positionX| ≤ (canvasW - itemW)/2 - margin`
  và tương ứng cho Y (margin = 8px), **hoặc** `scale` đã được giảm để thoả điều kiện.
- **INV-2**: Giá trị `canvasW/canvasH` dùng để kẹp là kích thước đo được
  (`OutfitStudioState.canvasWidth/Height`); khi chưa đo, dùng fallback `360×520`.
- **INV-3**: Khi thêm **một** món, chỉ món mới được điều chỉnh; các món đã có giữ nguyên
  `positionX/positionY/scale`.
- **INV-4**: Khi nạp cụm (set AI / khôi phục outfit), toàn cụm đi qua `layoutCanvasItems`
  để vừa khung (hành vi hiện có, không đổi).

### Thay đổi

| Hàm | Trước | Sau |
|---|---|---|
| `addItemToCanvas` (`outfit_studio_provider.dart:280`) | Đặt theo `coordinateMap[role]`, không kẹp | Đặt theo `coordinateMap[role]`, rồi `clampCanvasItem(item, canvasW, canvasH)` (INV-1..3) |
| `clampCanvasItem` (`canvas_layout.dart`) | — (chỉ có `_clamp` private dùng trong `layoutCanvasItems`) | **Mới**: kẹp + thu nhỏ nếu món quá khổ (helper công khai) |

---

## Entity: Category (danh mục phân loại)

Nguồn: `WardrobeItemModel.category` / `fashionItem.category` (id, name, slug).

### Phân loại vai trò (đã có — tái dùng)

`normalizeRole(rawRole, {categorySlug, categoryName})` → `CanvasRole`
(`canvas_layout.dart:117-276`). Nhóm `outerwear` khi khớp `khoác/jacket/blazer/coat/cardigan`
hoặc slug `ao-khoac`.

### Quy tắc lọc khay (FR-004, Clarifications 2026-10-13)

| Chip | Điều kiện |
|---|---|
| `All` | tất cả |
| `Áo khoác` | `normalizeRole(...) == CanvasRole.outerwear` |
| `Áo` | điều kiện chuỗi hiện có **AND NOT** outerwear |
| `Quần` / `Váy` / `Giày` / `Phụ kiện` | giữ nguyên điều kiện chuỗi hiện có (không đổi) |

**Nhãn**: `Áo khoác` = `outfitRoleLabelVi('outerwear')` (đã có, `outfit_models.dart:166`).

---

## Entity: Chat message (Stylist)

Nguồn: `ChatMessageModel` (`stylist_models.dart:187-259`). Trường `content` là **Markdown**
do máy chủ trả; `cleanContent` bỏ marker `[ACTION:REDIRECT_OUTFIT]`.

### Quy tắc hiển thị mới (FR-009)

- `content` (đã `cleanContent`) MUST render qua Markdown renderer, không hiển thị ký tự cú
  pháp thô.
- Áp dụng cho cả tin đang stream (`isStreaming == true`) và tin đã xong.
- Cú pháp không hợp lệ / văn bản thuần MUST vẫn hiển thị an toàn (không crash).

---

## Entity: Community post / Search state

Nguồn: `Post` (`post_models.dart`), `CommunitySearchState`
(`community_search_provider.dart:8-80`).

### Thay đổi (FR-012)

- `CommunitySearchState.postTypeFilter` **giữ trường nhưng luôn `null`** — UI không còn điều
  khiển đổi giá trị này (gỡ hàng chip).
- Request tìm kiếm (`searchCommunity`) MUST NOT gửi bộ lọc loại bài; kết quả gồm mọi loại.
- `searchType` (`all`/`users`/`posts`) **không đổi** (hàng segmented còn giữ).

---

## Không thay đổi

- `WardrobeItemModel`, `FashionItemModel`, `Post`, `ChatSessionModel`, `OutfitRecommendationModel`.
- Hợp đồng API máy chủ (không thêm/bớt endpoint; chỉ ngừng gửi một query param tuỳ chọn).
- `SaveOutfitItemReq` / `SaveOutfitReq` (lưu outfit vẫn dùng `positionX/Y`, `scale`, `layerOrder`).

## State transitions (khay Studio)

```
collapsed (≈0.065) ──tap header/icon──▶ expanded (≈0.42) ──tap icon/header──▶ collapsed
        ▲                                        │
        └──────────── kéo tay / snap ────────────┘
```
Trạng thái mở/đóng là **UI state cục bộ** của màn, không thuộc `OutfitStudioState`
(không lưu vào provider, không gửi BE).
