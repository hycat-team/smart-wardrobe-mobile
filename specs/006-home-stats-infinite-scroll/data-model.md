# Data Model: Home Stats Infinite Scroll

**Feature**: specs/006-home-stats-infinite-scroll
**Note**: Không entity persisted mới; chỉ mở rộng state + 1 model stats.

## Existing (reused)

| Entity | Location | Dùng cho |
|---|---|---|
| `WardrobeInsightsModel` | `wardrobe/models/wardrobe_models.dart:417` | Home: `totalItems`, `totalWardrobeValueVnd` (+ `formattedTotalValue`) |
| `WardrobeCategoryDistributionResult` | same file `:473` | Home section danh mục (đã dùng) |
| `WardrobePaginationResult` | `wardrobe/data/wardrobe_repository.dart:6` | Đã có `page/limit/total` — Wardrobe load-more dùng trực tiếp |
| `UserOutfitModel` | `outfit_studio/models/outfit_models.dart` | Outfit append + dedupe theo `id` |

## New — WardrobeStats (client model)

- `activeItemsCount: int` (required) — tổng món đang có.
- `outfitsCount: int` (required) — tổng outfit đã lưu (chuẩn cho Home, thay `outfits.length`).
- Parse từ `GET /me/wardrobe-items/stats` (`{data: {activeItemsCount, outfitsCount}}`), fallback `{}` → 0.

## New — OutfitPaginationResult (client model)

- `items: List<UserOutfitModel>`, `page: int`, `total: int` — mirror `WardrobePaginationResult`.

## State extensions

- `WardrobeState` += `isLoadingMore: bool` (default false); derived `hasMore = items.length < total`; `page` hiện có được dùng thật (tăng sau mỗi loadMore thành công, reset về 1 khi refresh/đổi filter).
- `OutfitsListState` += `page = 1`, `total = 0`, `isLoadingMore = false`; derived `hasMore = outfits.length < total`.
- `LoadMoreStatus` (derived, không lưu): `idle | loading | done | error` — suy từ `isLoadingMore/hasMore/errorMessage`.

## Invariants

- `items.length <= total` sau mỗi load (dedupe id trước khi cộng).
- Refresh/filter-change: `items = [] (hoặc thay mới), page = 1`, request cũ trễ về bị bỏ.
- Không có 2 `loadMore` song song cùng danh sách.
- `selectedIds` (004) bất biến qua append.
