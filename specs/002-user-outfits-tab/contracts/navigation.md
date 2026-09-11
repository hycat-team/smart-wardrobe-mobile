# Contracts: Navigation cho User Outfits Tab

## Tab bar (5 tabs, theo index)

| Index | Label    | Icon (off / on)                  | Branch path |
|-------|----------|----------------------------------|-------------|
| 0     | Home     | `home_outlined / home_rounded`   | `/wardrobe` |
| 1     | Wardrobe | `checkroom_outlined / checkroom_rounded` | `/studio` |
| 2     | Stylist  | `auto_awesome_outlined / auto_awesome` | `/stylist` |
| 3     | Outfits  | `style_outlined / style_rounded` | `/my-outfits` |
| 4     | Profile  | `person_outline_rounded / person_rounded` | `/profile` |

## Routes

- Mới: `/my-outfits` (shell branch, giữa stylist và profile) → `OutfitsListScreen(showBackButton: false)`.
- Giữ nguyên: `/outfits` (top-level, có back) cho `context.push('/outfits')` từ Studio/Stylist.
- Hành vi shell giữ nguyên: `goBranch(index, initialLocation: tái bấm tab đang chọn)`, giữ state các tab.

## Widget contract

- `OutfitsListScreen({showBackButton = true})`: `false` ẩn nút leading trên AppBar; mọi hành vi khác (grid, detail sheet, xóa, mở Studio, refresh, empty state) không đổi.
