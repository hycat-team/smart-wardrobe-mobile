# Contract — Quy tắc canvas Studio

**Feature**: `017-canvas-single-item` · **Owner**: mobile client (`outfit_studio`) · **BE**: không sửa

## Phạm vi

Áp dụng cho thao tác **thêm món thủ công** trên canvas Studio Thủ Công
(`OutfitStudioNotifier.addItemToCanvas`).

## Quy tắc

### 1. Một món mỗi loại (nhóm cơ bản)

- Tập vai trò độc quyền: `top`, `bottom`, `fullbody`, `outerwear`, `footwear` — tối đa **1** món
  mỗi vai trò.
- `headwear`, `accessory`, `other`, `unknown` — **không** giới hạn.

### 2. Thay thế khi trùng loại

- Thêm món vai trò `r` (độc quyền) mà canvas đã có `r` → **gỡ** món cũ, thêm món mới.
- `fullbody` ⇄ `top` loại trừ nhau: thêm `fullbody` gỡ `top`; thêm `top` gỡ `fullbody`.
- `bottom` độc lập: được phép cùng `fullbody`.
- Có gỡ ít nhất 1 món → `addItemToCanvas` trả về `true`; screen hiển thị `ClosyToast.success`.

### 3. Vị trí món mới

- Đặt theo **toạ độ chuẩn của vai trò** (`roleCoordinatesSeparate/Fullbody`), không kế thừa vị
  trí món cũ; `scale` giữ theo mức tỉ lệ chung của canvas (trung bình, `1.0` khi trống).
- Luôn `clampCanvasItem` để nằm trọn trong khung.

### 4. Áo khoác không chồng lớp nền

- Khi cùng canvas có `outerwear` và lớp nền (`top` hoặc `fullbody`): **giữ nguyên vị trí/tỉ lệ
  lớp nền**; dịch nhẹ áo khoác sang phải một khoảng tỉ lệ canvas (`0.12 * canvasWidth`) để
  **chồng nhẹ** (vẫn phủ nhau, lộ một phần nền); outerwear ở lớp trên; kẹp trong khung.
- Chỉ áp dụng ở thao tác thêm/đặt món (add, nạp set AI, khôi phục outfit); không đụng món khác loại.

## Bất biến kiểm chứng được

| ID | Điều kiện |
|---|---|
| INV-1 | `count(role==r) ≤ 1` với `r` ∈ tập độc quyền |
| INV-3 | thêm `fullbody` ⟹ không còn `top`; thêm `top` ⟹ không còn `fullbody`; `bottom` không đổi |
| INV-5 | mọi món trong khung |
| INV-6 | có outerwear + lớp nền ⟹ chồng nhẹ (nền lộ một phần, nền KHÔNG dời) |

## Ngoài phạm vi

- Luồng nạp set AI (`loadFromAIRecommendation`) và khôi phục outfit giữ nguyên quy tắc riêng.
- Không đổi hợp đồng lưu outfit (`SaveOutfitReq`).
