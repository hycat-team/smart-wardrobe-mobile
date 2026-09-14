# Research: Home Stats Infinite Scroll

**Feature**: specs/006-home-stats-infinite-scroll
**Date**: 2026-09-14
**Scope**: mobile-only; BE/FE read-only for contract verification.

## R1 — Home đếm sai vì đếm từ list phân trang (verified)

**Context**: `home_screen.dart:26` đếm tủ từ `wardrobeState.total` (đúng là server total NHƯNG bị scope theo category filter đang chọn) và outfit từ `outfitsState.outfits.length` (capped ở limit 50 của `getMyOutfits`). Trang Thống kê dùng `wardrobeInsightsProvider` (`GET /me/dashboard/wardrobe-insights` → `totalItems`, `totalWardrobeValueVnd`) + `categoryDistributionProvider` — Home không dùng insights và không có giá trị tủ.

**Decision**: Home chuyển sang cùng nguồn stats:
- `wardrobeInsightsProvider` (có sẵn): `totalItems` + `totalWardrobeValueVnd` cho thẻ tổng quan;
- MỚI `wardrobeStatsProvider`: `GET /me/wardrobe-items/stats` → `WardrobeStatsRes{activeItemsCount, outfitsCount}` (BE `wardrobe_item_handler.go:386`, FE `wardrobeApi.getWardrobeStats` đã dùng — endpoint có sẵn, mobile chỉ thêm 1 repo method);
- Giữ `categoryDistributionProvider` cho section danh mục (đã đúng).
- RefreshIndicator của Home invalidate cả 3 nguồn stats (hiện tại thiếu insights/stats).
- Loading/error: skeleton + retry đúng phần số liệu (pattern `AiQuotaDisplay` ở 004), không hiện số thiếu.

**Rationale**: Stats APIs là global (không bị filter), authoritative, FE-proven. Không đụng list providers.

**Alternatives considered**:
- Nâng limit list lên rất lớn để đếm đủ → tốn băng thông, vẫn capped, filter-scope sai; rejected.
- Đếm từ `wardrobeState.total` hiện tại → sai khi đang lọc category; rejected.

## R2 — Wardrobe infinite scroll (client-only)

**Context**: `WardrobeNotifier.loadItems` dùng `state.page` nhưng không bao giờ tăng; không có scroll listener; `getMyWardrobeItems(page, limit=20)` đã hỗ trợ phân trang + trả `total`.

**Decision**: Mở rộng notifier (không đổi repo):
- State += `isLoadingMore`, derived `hasMore = items.length < total`.
- `loadMore()`: guard `isLoadingMore || !hasMore || isLoading`; gọi `page+1`, append + dedupe theo id (giữ optimistic processing items ở đầu như hiện tại), cập nhật page/total.
- `loadItems(refresh)` / `selectCategory` reset về page 1 + xóa list cũ (chống lẫn filter + chống race: request cũ về trễ bị bỏ bằng token phiên).
- Màn hình: `NotificationListener<ScrollNotification>` trên `CustomScrollView`, trigger khi còn ~400px tới cuối; footer sliver hiện spinner khi `isLoadingMore`, ẩn khi hết.
- Giữ limit 20 (hành vi cũ cho user <20 món không đổi).

## R3 — Outfit infinite scroll (repo + notifier + screen)

**Context**: `getMyOutfits(page=1, limit=50)` bỏ metadata phân trang (trả `List`); BE trả `PaginationResult` đầy đủ (`outfit_handler.go:122`).

**Decision**:
- Repo: thêm `getMyOutfitsPaginated({page, limit})` trả `OutfitPaginationResult{items, page, total}` (giữ `getMyOutfits` cũ cho caller khác nếu có — kiểm tra lúc implement).
- Notifier += `page/total/isLoadingMore/hasMore` + `loadMore()` (append + dedupe id, guard song song) — cùng mẫu R2; giữ `selectedIds` khi append (đã là state riêng).
- Màn hình: `GridView.builder` + listener ngưỡng cuối + trailing loader. Giữ limit 50 (ít request hơn; user <50 outfit không đổi hành vi).
- `deleteOutfits` trừ total tương ứng (đã trừ list; cộng trừ total cho `hasMore` đúng).

## R4 — Endpoint mới duy nhất (additive, đã có sẵn)

`GET /me/wardrobe-items/stats` → `{activeItemsCount, outfitsCount}`. Không sửa BE/FE. Mọi thứ còn lại là client-side.

## R5 — Không ảnh hưởng selection/bulk-delete (004)

Append chỉ thêm item mới; `selectedIds` là Set độc lập → giữ tick. Xóa hàng loạt xong refresh lại từ trang 1 như hiện tại.
