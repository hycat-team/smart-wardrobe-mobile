# Data Model: Studio Canvas Positions

**Feature**: specs/005-studio-canvas-positions
**Note**: No new persisted entities. All models exist; this doc pins the layout semantics.

## Existing (reused)

| Entity | Location | Fields used |
|---|---|---|
| `CanvasItem` | `outfit_models.dart:241` | `id`, `fashionItemId`, `imageUrl`, `name`, `role`, `positionX`, `positionY`, `scale`, `layerOrder` |
| `RecommendedItemGroup` | `outfit_models.dart:115` | `role`, `primary: RecommendedItemRes?` |
| `RecommendedItemRes` | `outfit_models.dart:82` | `id`, `fashionItem: RecommendedFashionItemBrief?` (NO coordinates — layout derives from `role`) |
| `OutfitItemModel` | `outfit_models.dart:292` | `positionX`, `positionY` (default 0), `scale`, `layerOrder`, `fashionItem` |
| `SaveOutfitItemReq` | `outfit_models.dart:193` | `fashionItemId`, `positionX`, `positionY`, `scale`, `layerOrder` (save path unchanged) |

## Layout semantics (new, client-side)

- **CanonicalRole**: `top | bottom | fullbody | outerwear | footwear | headwear | accessory | unknown` — output of `normalizeRole(rawRole, categorySlug)`.
- **Coordinate frame**: `positionX/positionY` = logical-px offset from canvas center. Rendered rect center = `(W/2 + x, H/2 + y)`, item box = `200*scale` square.
- **Slot table**: per R3 in `research.md` (existing 5 slots frozen, +outerwear/headwear/unknown).
- **Validity invariants after `layoutCanvasItems`**:
  - every center inside canvas minus `100*scale + 8` margin (clamped);
  - no two centers closer than 80px (de-overlapped, max 5 nudge tries);
  - all-`(0,0)` input → fully re-laid-out by role;
  - single item → `(0,0)`.
- **Manual edits win**: drag/scale/layer changes after auto-layout are never re-laid-out; save sends final values as today.

## Relationships

```text
RecommendedOutfitRes ──role per group──▶ normalizeRole ──▶ slot table ──▶ layoutCanvasItems ──▶ canvasItems
UserOutfitModel.items (stored posX/posY) ──▶ honor stored ──▶ clamp + de-overlap ──▶ canvasItems
canvasItems ──drag/scale/layer (existing)──▶ saveOutfit (existing SaveOutfitItemReq)
```
