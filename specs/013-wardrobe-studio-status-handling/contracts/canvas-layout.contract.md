# Contract: canvas-layout (port từ FE)

Nguồn: `smart-wardrobe-fe/.../outfit-canvas-layout.ts`. Số liệu sao chép nguyên văn; gốc tọa độ tại tâm canvas.

## Bảng tọa độ (x, y, scale, zIndex)

SEPARATE: headwear (0,-330,80,8) · top (0,-140,100,5) · outerwear (-25,-145,105,7) · bottom (0,110,100,4) · footwear (0,295,80,3) · accessory (-240,40,85,9) · other (250,180,75,2) · fullbody-fallback (0,-15,105,5).

FULLBODY: headwear (0,-330,80,8) · fullbody (0,-15,105,5) · outerwear (-25,-130,105,7) · footwear (0,295,80,3) · accessory (-240,20,85,9) · other (250,170,75,2) (+ top/bottom fallback).

Phụ kiện 2+: (240,-100) · (240,80) · (-240,-120), scale 75, z9; món 5+ → `x:240, y:80+(n-1)*60`.

## Tỉ lệ bbox (widthRatio × heightRatio)

headwear 1.8×1.4 · top 2.1×2.1 · outerwear 2.3×2.3 · bottom 1.9×2.3 · fullbody 2.1×3.2 · footwear 1.8×1.3 · accessory 1.6×1.6 · other 2.0×2.0. Kích thước = `scale × ratio`.

## Quy tắc dựng

1. Chuẩn hóa role (thứ tự: headwear → fullbody → outerwear → top → bottom → footwear → accessory → other; fallback `categorySlug`).
2. Có fullbody ⇒ loại top/bottom. Dedupe vai trò chính giữ 1 (trừ accessory/other).
3. `INCOMPLETE` ⇒ dựng như SEPARATE_PIECES với vai trò hiện có.
4. Legacy restore: thân trên mà `y > 0` ⇒ đảo dấu; `x == ±1` (default 0) ⇒ 0; outerwear `x == 25` ⇒ -25; footwear `y == 305` ⇒ 295; gần gốc ⇒ dùng default.
5. Hậu-kỳ mobile (giữ): clamp lề 8px, tách chồng lấn <80px, 1 món ra giữa; **mới**: vừa-khung (`fitK = min(w/bboxW, h/bboxH, 1)` + căn tâm).
