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
| **Độc quyền** (nhóm cơ bản) | `top`, `bottom`, `fullbody`, `outerwear`, `footwear` | 1 mỗi loại |
| **Không độc quyền** | `headwear`, `accessory`, `other`, `unknown` | không giới hạn |

Quan hệ chéo: `fullbody` ⇄ `top` **loại trừ nhau** khi thêm tay; `bottom` **độc lập**.

---

## Bất biến (từ FR-001..FR-006)

- **INV-1 (một món mỗi loại)**: Với mọi `r` ∈ tập độc quyền, `count(items, role==r) ≤ 1`.
- **INV-2 (thay thế)**: Khi thêm món vai trò `r` đã có → món cũ cùng vai trò **bị gỡ** trước khi
  thêm món mới; không tồn tại 2 món cùng vai trò độc quyền sau thao tác.
- **INV-3 (đầm↔áo)**: Sau khi thêm `fullbody`, không còn `top`; sau khi thêm `top`, không còn
  `fullbody`. `bottom` giữ nguyên trong cả hai.
- **INV-4 (thay tại chỗ)**: Khi thay món **cùng vai trò**, món mới giữ **đúng** `positionX/Y` và
  `scale` của món cũ. Khi **thêm mới** (không có món cùng vai trò), `positionX/Y` lấy từ toạ độ
  chuẩn của vai trò và `scale` = mức tỉ lệ chung của canvas (trung bình, `1.0` khi trống). Luôn kẹp
  trong khung.
- **INV-5 (trong khung)**: Mọi món luôn qua `clampCanvasItem` → hộp giới hạn nằm trong khung.
- **INV-6 (áo khoác chồng ~20%, nền không dời)**: Nếu có `outerwear` và lớp nền (`top`/`fullbody`):
  áo khoác đặt **sát bên** sao cho **phần chồng ngang ≈ 20% bề rộng nền**; nếu không đủ chỗ, **thu
  `scale` áo khoác** (sàn `0.15`) cho vừa khung; **vị trí/tỉ lệ lớp nền KHÔNG đổi**; outerwear giữ
  `layerOrder` trên; cả hai trong khung. (Bản chỉnh 2026-10-13.)

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
