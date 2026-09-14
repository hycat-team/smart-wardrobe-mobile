# Data Model: Loadmore Chip Contrast

**Feature**: specs/007-loadmore-chip-contrast
**Note**: State extensions only; no new persisted entities, no API change.

## State extensions

- `WardrobeState` += `lastPageWasFull: bool` (default false), `emptyStreak: int` (0), `loadMoreExhausted: bool` (false); `hasMore` redefined per research R2. Page-size const 20 (matches `getMyWardrobeItems` default limit).
- `OutfitsListState` += same three fields; page-size const 50 (matches `getMyOutfitsPaginated` default limit).

## Invariants (extend 006)

- `hasMore = !loadMoreExhausted && (items.length < total || (lastPageWasFull && emptyStreak < 2))`.
- refresh/fetch-p1 resets all three flags; `lastPageWasFull = rawPage.length >= limit`.
- loadMore success: fresh > 0 → `emptyStreak = 0`, update `lastPageWasFull`; fresh == 0 → `emptyStreak++`, exhaust when `items.length >= total || emptyStreak >= 2`.
- failure: flags untouched (retry allowed).
- `selectedIds` still untouched by appends; delete path refreshes from page 1 (resets flags).

## Chip visual states

- Selected chip: bg primary, label white, checkmark white.
- Unselected chip: bg light, label primary, checkmark primary (or hidden per default).
