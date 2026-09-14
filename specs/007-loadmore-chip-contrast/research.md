# Research: Loadmore Chip Contrast (fix of 006)

**Feature**: specs/007-loadmore-chip-contrast
**Date**: 2026-09-14
**Scope**: mobile-only; no BE change.

## R1 — Why 006 load-more stands still (diagnosis)

**Verified**: 006 structure is correct (400px trigger, single-flight, dedupe, reset). Remaining suspects are all runtime/data-side:

| # | Suspect | Symptom | Mobile hardening |
|---|---|---|---|
| A | BE ignores `page` (every page returns same 20) | `hasMore` stays true, spinner each scroll, count never grows | Empty-progress probe: 2 consecutive 0-fresh loads → exhausted, stop |
| B | `total` smaller than reality (e.g. 20/35) | `items.length < total` false → never loads p2 | Full-page heuristic: last raw page size == limit → allow next load |
| C | Late/duplicate page (all fresh filtered) | same as A | same probe as A |
| D | Horizontal chips `ListView` fires our `NotificationListener` | premature/spurious `loadMore` calls | filter `metrics.axis == Axis.vertical` |

**Decision**: Implement B + C + D mobile-side (no BE dependency, no extra endpoint). A root-caused on BE remains possible — but with the probe the app degrades sanely (stops, no infinite spinner) instead of hanging.

## R2 — `hasMore` v2 formula

**Decision**: Per-list state += `lastPageWasFull` (default false), `emptyStreak` (0), `loadMoreExhausted` (false); page size const per list (wardrobe 20, outfits 50 — frozen, matching repo defaults):

```text
hasMore = !loadMoreExhausted
          && (items.length < total
              || (lastPageWasFull && emptyStreak < 2))
```

- refresh/fetch page 1: reset all three; `lastPageWasFull = rawPage.length >= limit`.
- loadMore success, fresh > 0: `emptyStreak = 0`; `lastPageWasFull = rawPage.length >= limit`.
- loadMore success, fresh == 0: `emptyStreak++`; if `items.length >= total` OR `emptyStreak >= 2` → `loadMoreExhausted = true`.
- failure: flags untouched (retry allowed), error surfaced as today.

Walkthrough: normal 35/20 → p2 fresh 15 (< limit) → 35 !< 35, lastFull false → done, zero extra calls. Exact-multiple 40/20 → p2 full → probe p3 → empty + 40>=40 → exhausted (1 extra call, per 006 assumption). BE-ignores-page → p2/p3 dupes → streak 2 → exhausted, spinner stops. Total-wrong-small (20/35, page honored) → p1 full sets flag → p2 loads 15 fresh → done. Initial empty state: `lastPageWasFull=false` → never skips page 1.

**Alternatives considered**: blind retry loops (infinite-spinner risk; rejected); fixing BE paging first (can't verify server here; mobile hardening covers all cases anyway).

## R3 — Chip selected icon white

**Decision**: On all filter `ChoiceChip`s (Wardrobe ×2, catalog `_CategoryChip`): `checkmarkColor: selected ? Colors.white : AppColors.primary` (+ keep `selectedColor: primary`, label white — already correct). Unselected keeps primary icon on light chip. No layout change; verify light/dark readability.

**Alternatives considered**: custom leading icon widget (heavier, same result; rejected).
