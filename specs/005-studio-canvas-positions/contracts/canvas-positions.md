# Contract — Canvas Positions (no change, read-only reference)

**Status**: ✅ All fields exist on backend + mobile parsing. Zero BE/FE work.

## 1. Saved outfit items (literal coordinates)

BE `wardrobe/application/dto/outfit.go` (OutfitItemRes, via mapper `outfit.go:38`):

```text
{ "positionX": <float>, "positionY": <float>, "scale": <float>, "layerOrder": <int>, ... }
```

Mobile `OutfitItemModel.fromJson` (`outfit_models.dart:312`) already parses all four (default 0). Save path `SaveOutfitItemReq` sends them back unchanged.

## 2. AI suggestion groups (role, not coordinates)

BE `fashion/application/dto/recommendation.go:52`:

```text
{ "role": "top|bottom|fullbody|outerwear|footwear|headwear|accessory",
  "primary": { ... }, "alternatives": [ ... ] }
```

Valid role vocabulary enforced BE-side (`synthesis/prompt.go:67`, one group per role max). Mobile MUST handle all 7 + raw/unknown values defensively (normalization table in `research.md` R2).

## 3. Mobile invariant

No new endpoints, no new fields, no schema migration. Feature is a client-side layout fix over these two existing shapes.
