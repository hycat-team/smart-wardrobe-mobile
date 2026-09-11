# Data Model: User Outfits Tab

**Feature**: `002-user-outfits-tab` | **Source**: model hiện có (`lib/features/outfit_studio/models/outfit_models.dart`)

## Entities (tái dùng, không thêm mới)

### UserOutfit
- Thuộc tính: `id`, `name`, `description?`, `coverImageUrl?`, `createdAt` (+ `formattedDate`), `items[]`.
- Nguồn: `GET /me/outfits` (list), `GET /outfits/:id` (chi tiết bottom sheet).
- Hiển thị lưới: ảnh bìa (placeholder `checkroom` khi trống), tên (1 dòng), ngày tạo.

### OutfitItem
- Thuộc tính: `fashionItem` (category, style, colorHex, imageUrl).
- Hiển thị trong bottom sheet chi tiết.

## State (provider hiện có `outfitsListProvider`)

- `outfits[]`, `isLoading`, `errorMessage`.
- Hành động: `fetchOutfits()`, `fetchOutfitDetail(id)`, `deleteOutfit(id)`, `loadIntoStudio(outfit)`.
- Không thêm state mới cho tab; flag UI duy nhất là `showBackButton` của widget.
