# Contract — Pagination & Stats (006)

**Status**: 3/4 endpoints đã dùng; 1 endpoint additive đã có sẵn (BE + FE-proven).

## 1. Wardrobe paging — existing, reused as-is

```text
GET /api/v1/me/wardrobe-items?page=<n>&limit=20&categorySlug=<slug?>
→ { data: { data|items: [...], page, limit, total } }
```
Mobile `getMyWardrobeItems` đã parse đủ. Không đổi.

## 2. Outfit paging — existing, mobile parse thêm metadata

```text
GET /api/v1/me/outfits?page=<n>&limit=50
→ { data: { items: [...], page, limit, total } }   // PaginationResult[OutfitBriefRes]
```
BE đã trả đủ (`outfit_handler.go:122`); mobile hiện bỏ `page/total` → bổ sung parse (không đổi BE).

## 3. Wardrobe stats — existing, mobile gọi mới

```text
GET /api/v1/me/wardrobe-items/stats
→ { data: { activeItemsCount: <int>, outfitsCount: <int> } }
```
BE `wardrobe_item_handler.go:386`; FE `wardrobeApi.getWardrobeStats` đang dùng. Mobile thêm 1 repo method + model `WardrobeStats`.

## 4. Insights + distribution — existing, Home dùng thêm

```text
GET /api/v1/me/dashboard/wardrobe-insights        (wardrobeInsightsProvider)
GET /api/v1/me/dashboard/wardrobe/category-distribution  (categoryDistributionProvider)
```
Không đổi; Home watch thêm insights provider.
