# Contract — Load-more hardening (007)

**Status**: ✅ No API change. Same endpoints as 006 (`contracts/pagination.md` in `specs/006-home-stats-infinite-scroll/`).

## Assumption under test

- `GET /me/wardrobe-items?page&limit` and `GET /me/outfits?page&limit` honor `page` and report truthful `total`. If either misbehaves (page ignored / total short), the R2 state machine degrades sanely: at most 2 wasted probe calls, then `loadMoreExhausted`, spinner stops, list keeps what it has.
- Page sizes observed by mobile: wardrobe 20, outfits 50 (repo defaults; server may cap — `lastPageWasFull` compares against requested limit).

## Mobile behavioral contract (new)

- `hasMore = !loadMoreExhausted && (items.length < total || (lastPageWasFull && emptyStreak < 2))`.
- Only vertical scroll notifications trigger `loadMore` (horizontal chip rails ignored).
- Selected filter chip: white label + white checkmark on primary bg.
