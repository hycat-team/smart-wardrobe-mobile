# Research: Studio Canvas Positions

**Feature**: specs/005-studio-canvas-positions
**Date**: 2026-09-14
**Scope**: mobile-only (`smart-wardrobe-mobile`); BE/FE read-only for contract verification.

## R1 — Root causes (verified in code)

**AI path** (`outfit_studio_provider.dart:198 loadFromAIRecommendation`):
- Role→position map covers only 5 roles (top/bottom/fullbody/footwear/accessory). BE AI returns 7 roles (`synthesis/prompt.go:67`: top, bottom, fullbody, outerwear, footwear, headwear, accessory) → `outerwear`/`headwear` fall to `(0,0)` = stacked at canvas center, fully overlapping ("chồng lên nhau").
- No normalization: AI may return raw slugs (BE test shows `"role":"ao"`); mobile only `toLowerCase()`s → unmatched → `(0,0)`.
- Duplicate roles (2 accessories) share one slot → overlap.

**Saved-outfit path** (`outfits_list_provider.dart:163 loadIntoStudio` + `OutfitItemModel` posX/posY):
- Trusts stored pixel offsets blindly: legacy outfits saved with all `(0,0)` open as one stack; offsets saved on a big screen overflow small canvases ("nằm ngoài vị trí hiển thị").
- Render (`outfit_studio_screen.dart:1004`): `left = centerX + posX - size/2`, base size 200px — offsets like ±220 already near/beyond edges on small canvases. No clamping anywhere.

**Decision**: Fix purely client-side in the two load functions + one shared layout helper; no BE change (all needed fields already exist).

## R2 — Canonical role set + normalization (mobile-side)

**Decision**: Normalize every incoming role string: lowercase → trim → fragment map (covers EN roles + VI slugs):
`ao/top/shirt/jacket` → top; `quan/pant/jean/bottom` → bottom; `dam/vay/dress` → fullbody; `khoac/outerwear/coat` → outerwear; `giay/shoe/sneaker` → footwear; `mu/non/headwear/cap/hat` → headwear; `phu-kien/accessory/tui/kinh` → accessory; else → unknown.
Category slug of the fashion item is the tiebreaker when role is empty/unknown (same fragment map; pattern already used in `addItemFromWardrobe` + drawer filter).

**Rationale**: Defensive against raw AI slugs and future roles; single function reused by both load paths.

## R3 — Default layout table (logical px, base item 200)

**Decision**: One shared `role → (x, y, layerHint)` table, extending current numbers (existing 5 slots unchanged to avoid regressing familiar layouts):

| Role | x | y | Layer hint |
|---|---|---|---|
| top | 0 | -120 | 2 |
| bottom | 0 | 80 | 1 |
| fullbody | 0 | -20 | 2 |
| footwear | 0 | 220 | 1 |
| outerwear | 120 | -110 | 3 (jacket over shirt, shifted right to stay visible) |
| headwear | -110 | -170 | 4 |
| accessory | -130 | -90 | 4 |
| unknown/fallback | spiral slots: (130,0), (-130,60), (130,160), (-140,-40)… | — | next |

Duplicate role occurrence `n>1`: slot + `(60*(n-1), 40*(n-1))` cascade so twins never coincide.

**Rationale**: Keeps the 5 known-good positions users already recognize; new slots chosen symmetric to them.

## R4 — Clamp + de-overlap post-pass (both load paths)

**Decision**: After initial placement, run one pure function `layoutCanvasItems(items, canvasW, canvasH)`:
1. Clamp each center into `[half+8, W-half-8] × [half+8, H-half-8]` where `half = 100*scale` (scale-aware, 8px margin).
2. Legacy detection: if ALL items are `(0,0)` → treat as "no data", auto-layout by role (R3).
3. De-overlap: pairwise center distance < 80px → shift the later item by (+40,+30) steps (max 5 tries), re-clamping each step.
Single-item result is additionally centered at `(0,0)` offset (canvas middle) — covers the "còn 1 outfit" case even if stored position was odd.

**Rationale**: Clamp fixes cross-device overflow without coordinate conversion (offsets are center-relative, so they transfer; only overflow needs fixing). Pure function = unit-testable without widgets.

## R5 — Overwrite confirmation (screen-level)

**Decision**: `loadFromAIRecommendation` / `loadIntoStudio` call sites check `canvasItems.isNotEmpty` first → confirm dialog ("Canvas đang có đồ dở — Ghi đè / Giữ lại"). Provider stays dumb (single responsibility); dialog lives in `outfit_studio_screen.dart` near existing confirm patterns.

## R6 — No contract changes

BE already returns everything: saved items `positionX/positionY/scale/layerOrder` (`wardrobe dto/outfit.go`), AI groups `role` (`fashion dto/recommendation.go`). Save path already sends positions (`SaveOutfitItemReq`). Zero backend work; see `contracts/canvas-positions.md`.
