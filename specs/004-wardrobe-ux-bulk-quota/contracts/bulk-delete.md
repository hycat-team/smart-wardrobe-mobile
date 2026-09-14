# Contract — Bulk Delete (mobile ↔ backend)

**Status**: wardrobe bulk EXISTS; outfits bulk = sequential single-deletes (no BE change).

## 1. Wardrobe bulk delete — existing endpoint, reused as-is

```text
DELETE /api/v1/wardrobe-items/bulk
Content-Type: application/json
Authorization: Bearer <token>

Request: { "ids": ["<wardrobeItemId>", ...] }   // 1..N ids, non-empty
```

- Mobile already calls this with single-id arrays (`wardrobe_repository.dart`). Change: pass the full selection.
- Success: 2xx → mobile removes all requested ids optimistically confirmed, decrements total, invalidates insights/category providers.
- Failure (network/5xx/partial): mobile treats whole call as failed → keeps list, surfaces error; retry re-sends same id list (idempotent by id).
- Client rule: never send empty `ids` (delete action disabled at 0 selection).

## 2. Outfit bulk delete — sequential existing endpoint

```text
DELETE /api/v1/outfits/{id}
Authorization: Bearer <token>
```

- No bulk route exists on BE (`outfit_handler.go` has only `DELETE /outfits/{id}`) — intentionally NOT added in this iteration.
- Mobile loops ids **sequentially**, building `BulkDeletionResult{deletedIds, failedIds}`:
  - per-item success → remove from `outfitsListProvider` state immediately (progressive update);
  - per-item failure → record id + message, continue with next;
  - end: `deletedIds + failedIds == requestedIds` (invariant, no silent drops).
- UI: all-success → snackbar `Đã xóa n bộ trang phục`; partial → dialog listing failed names + `Thử lại (k)` retrying only `failedIds`.
