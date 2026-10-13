# Phase 1 — Data Model: Canvas một món mỗi loại

**Feature**: `017-canvas-single-item` · **Date**: 2026-10-13

Không thêm entity. Thay đổi là **bất biến** trên danh sách `CanvasItem` của canvas.

---

## Entity: CanvasItem (không đổi trường)

Nguồn: `lib/features/outfit_studio/models/outfit_models.dart:323-381`. Các trường liên quan:
`role` (tên `CanvasRole`), `positionX/Y`, `scale`, `layerOrder`, `baseScale`, `boxRatioW/H`.

Bất biến kích thước (dùng ở render + layout):
```
itemScaleMultiplier = 1.25
itemW = baseScale * boxRatioW * scale * itemScaleMultiplier
itemH = baseScale * boxRatioH * scale * itemScaleMultiplier
```

---

## Vai trò & phân nhóm

Nguồn `CanvasRole` (`canvas_layout.dart:5-15`), `normalizeRole` (`:117-276`).

| Nhóm | Vai trò | Số món tối đa |
|---|---|---|
| **Độc quyền** | `top`, `bottom`, `fullbody`, `outerwear`, `footwear`, `headwear` | 1 mỗi loại |
| **Nhiều món** | `accessory` (mỗi **loại**/danh mục tối đa 1), `other`, `unknown` | accessory: ≤1 mỗi loại; other/unknown: không giới hạn |

Quan hệ chéo: `fullbody` ⇄ `top` **loại trừ nhau** khi thêm tay; `bottom` **độc lập**.

---

## Bất biến (từ FR-001..FR-006)

- **INV-1 (một món mỗi loại)**: Với mọi `r` ∈ tập độc quyền, `count(items, role==r) ≤ 1`.
- **INV-2 (thay thế)**: Khi thêm món vai trò `r` đã có → món cũ cùng vai trò **bị gỡ** trước khi
  thêm món mới; không tồn tại 2 món cùng vai trò độc quyền sau thao tác.
- **INV-3 (đầm↔áo)**: Sau khi thêm `fullbody`, không còn `top`; sau khi thêm `top`, không còn
  `fullbody`. `bottom` giữ nguyên trong cả hai.
- **INV-4 (bố trí lại theo vai trò)**: Thêm/thay món ⟹ toàn bộ món được đặt lại theo toạ độ chuẩn
  của vai trò (phụ kiện so le; `scale` reset `1.0`), rồi fit-to-canvas. Vị trí/khoảng cách nhất quán
  bất kể thứ tự thêm. Món đơn được kẹp vào khung. (Bản chỉnh 2026-10-13 lần 10.)
- **INV-5 (trong khung)**: Mọi món luôn qua `clampCanvasItem` → hộp giới hạn nằm trong khung.
- **INV-6 (áo khoác bằng áo, ngang hàng, chồng ≤40%)**: Nếu có `outerwear` và lớp nền
  (`top`/`fullbody`): áo khoác có **cùng bề rộng** và **cùng mức `positionY`** với lớp nền, ở **phía
  đối diện phụ kiện**, chồng lên lớp nền **≤ 40%**; **vị trí và kích thước lớp nền KHÔNG đổi**;
  outerwear giữ `layerOrder` trên. (Bản chỉnh 2026-10-13.)
- **INV-9 (fit-to-canvas)**: Khi có ≥2 món, toàn bộ khối được thu **đồng tỉ lệ** để vừa khung (không
  tràn/đè) và căn giữa bề ngang. Món đơn giữ nguyên. (Bản chỉnh 2026-10-13 lần 8.)
- **INV-7 (phụ kiện nép sát cột)**: Mỗi `accessory` nằm ở **phía đối diện `outerwear`** (không có
  outerwear → bên trái), nép sát mép cột giữa (`top/bottom/fullbody/headwear/footwear`) một khoảng
  `gap` nhỏ và **không chồng** lên cột; kẹp trong khung. (Bản chỉnh 2026-10-13.)
- **INV-8 (phụ kiện không trùng loại)**: Hai `accessory` có cùng `categoryKey` (danh mục) KHÔNG cùng
  tồn tại; thêm phụ kiện cùng loại → thay tại chỗ món cũ. `categoryKey` rỗng = không xét.
  (Bản chỉnh 2026-10-13 lần 7.)

---

## Thay đổi hàm

| Hàm | Trước | Sau |
|---|---|---|
| `CanvasRole` helpers (`canvas_layout.dart`) | — | **+** hằng tập độc quyền (vd `const exclusiveRoles = {top,bottom,fullbody,outerwear,footwear}`) |
| `canvas_layout.dart` | `clampCanvasItem` (016) | **+** `layoutOuterwearBesideBase(items, canvasWidth, canvasHeight)` (R4) |
| `addItemToCanvas` (`outfit_studio_provider.dart:280`) | đặt chuẩn + kẹp, `items.add` | **+** gỡ món xung đột (INV-2/3) → chọn `coordinateMap` theo `hasFullbody` mới → kẹp → **+** `layoutOuterwearBesideBase` khi món thêm là outerwear/lớp nền → **trả về `bool`** (true khi có gỡ; screen hiển thị toast) |

Không đổi: `replaceItemOnCanvas`, `removeItem`, `clearCanvas`, `loadFromAIRecommendation`,
`saveOutfit` và hợp đồng lưu outfit.

## State transitions (thêm món)

```
[canvas] --add(role=r)--> [remove conflicts: r nếu độc quyền; fullbody<->top] --place standard--> --clamp--> --layout outerwear--> [canvas']
```

`addItemToCanvas` trả về `true` khi có gỡ ít nhất 1 món (screen hiển thị toast).
