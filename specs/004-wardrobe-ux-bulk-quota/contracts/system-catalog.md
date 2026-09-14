# Contract — System Catalog (EXISTS, FE/BE-verified 2026-09-14)

**Status**: ✅ Implemented on backend and proven by web FE. Mobile mirrors 1:1.
**FE reference**: `smart-wardrobe-fe/src/features/wardrobe/api/wardrobe.api.ts` (`getSystemCatalogItems`, `initClosetFromCatalog`), UX: `src/app/(user)/wardrobe/explore/components/SystemCatalogClient.tsx`.
**BE reference**: `wardrobe/presentation/router/router.go:32,48`, `wardrobe_item_handler.go:183` (`InitClosetFromCatalog` → 201).

## 1. List system catalog items — existing endpoint

```text
GET /api/v1/system-catalog/wardrobe-items?page=1&limit=20&categorySlug=<slug>&q=<text>
(public route on BE; mobile still sends auth via existing Dio interceptor)

Query (BE dto.GetSystemCatalogItemsQueryReq):
  page: int (default 1) | limit: int (default 20, mobile uses 20 like FE)
  q: string? (search text) | categorySlug: string? (omit for all)

Response 200 (existing envelope; items are WardrobeItemRes — SAME shape as /me/wardrobe-items):
{
  "data": {
    "items": [ { "id": "<catalogItemId>", "imageUrl": "...", "category": {...},
                 "color": "...", "style": "...", ... } ],
    "page": 1, "limit": 20, "total": 128
  }
}
```

- Mobile parses items with EXISTING `WardrobeItemModel.fromJson` (`lib/features/wardrobe/models/wardrobe_models.dart`) — no new model needed.
- Category filter values reuse existing `GET /categories` (`CategoryModel.slug`).
- Mobile base URL note: same `AppConstants.baseUrl` + `/api/v1` prefix as all other calls.

## 2. Add catalog items to my wardrobe — existing endpoint

```text
POST /api/v1/wardrobe-items/catalog-init
Authorization: Bearer <token> (private route)
Content-Type: application/json

Request (BE dto.InitClosetFromCatalogReq, FE InitClosetFromCatalogReq):
  { "catalogItemIds": ["<catalogItemId>", ...] }   // non-empty

Response 201: { "data": [ { "<WardrobeItemBriefRes/WardrobeItemRes JSON>" } ] }
BE behavior: copies system samples into the user's personal closet, no AI quota consumed.
```

- Mobile on success: `loadItems(refresh: true)` on `wardrobeProvider` (same post-change refresh path as upload/delete), clear catalog selection, pop back to Wardrobe with snackbar `Đã thêm n món từ tủ hệ thống`.
- Client dedupe (extra safety): ids already present in `wardrobeProvider` are shown as "Đã có trong tủ" and are non-selectable; never sent.
- Double-submit guard: disable add button while request in flight (same as FR pattern for top-up anti-double-submit).
