# Phase 0 — Research: Canvas một món mỗi loại + sửa áo khoác đè lớp nền

**Feature**: `017-canvas-single-item` · **Date**: 2026-10-13

Đối chiếu mã thật trong repo. Nguồn ghi theo `file:line`.

---

## R1 — Tập vai trò "độc quyền" (mỗi loại một món)

**Decision**: Tập độc quyền = `{top, bottom, fullbody, outerwear, footwear}` (nhóm quần áo cơ
bản). `{headwear, accessory, other, unknown}` **không** độc quyền — cho phép nhiều món.

**Rationale**:
- Enum `CanvasRole` (`canvas_layout.dart:5-15`) đã có đủ 9 vai trò; `normalizeRole` đã phân
  loại món → vai trò (`canvas_layout.dart:117-276`). Không cần khái niệm mới.
- Clarifications 2026-10-13 (spec): mũ/phụ kiện nhiều món; nhóm cơ bản một món.
- `other`/`unknown` là món không xác định — không gỡ để tránh mất dữ liệu người dùng.

**Alternatives considered**:
- *Mọi vai trò độc quyền kể cả phụ kiện/mũ*: bị loại ở Clarifications.
- *Chỉ 1 món toàn canvas*: bị loại (không còn là bàn phối).

---

## R2 — Gỡ xung đột khi thêm món

**Decision**: Trong `OutfitStudioNotifier.addItemToCanvas`, sau khi xác định `role` của món
mới, **gỡ mọi món xung đột** khỏi danh sách trước khi chọn toạ độ và thêm món mới:

1. Nếu `role` ∈ tập độc quyền → gỡ món có **cùng vai trò**.
2. Quy tắc **đầm ↔ áo**: nếu thêm `fullbody` → gỡ `top`; nếu thêm `top` → gỡ `fullbody`.
   `bottom` **độc lập** (không gỡ theo đầm/áo; đầm + quần cùng tồn tại).
3. Không gỡ gì với `headwear/accessory/other/unknown`.

**Rationale**:
- `addItemToCanvas` hiện chỉ `items.add(newItem)` (`outfit_studio_provider.dart:280-324`),
  không khử trùng → nguồn lỗi "nhiều áo".
- `loadFromAIRecommendation` đã có logic tương tự (loại top/bottom khi có fullbody, dedupe
  vai trò chính — `outfit_studio_provider.dart:326-397`) → ta **nhất quán** với luồng AI:
  đầm loại áo, nhưng **quần vẫn giữ** (khác điểm: AI cũ loại cả bottom khi có fullbody; spec
  017 chốt đầm **giữ** quần, nên chỉ áp dụng trong luồng thêm tay).
- `hasFullbody` (dùng chọn `coordinateMap`) phải tính **sau** khi gỡ → chèn bước gỡ trước.

**Alternatives considered**:
- *Đặt ở tầng UI (screen)*: trái kỷ luật — logic phải ở notifier (constitution II).
- *Chặn không cho thêm (thông báo "đã có áo")*: tester muốn **tự thay thế**, không phải chặn.

---

## R3 — Vị trí món mới khi thay thế

**Decision**: Món mới dùng **toạ độ chuẩn của vai trò** (`roleCoordinatesSeparate/Fullbody`),
`baseScale`/`boxRatio` theo vai trò, **không** copy `positionX/Y` của món cũ; `scale` giữ theo
**mức chung hiện có của canvas** (trung bình các món, `1.0` khi trống — hành vi sẵn có); rồi
`clampCanvasItem` để nằm trọn trong khung.

**Rationale**:
- Clarifications 2026-10-13: đặt theo vị trí chuẩn (không kế thừa) — bố cục nhất quán.
- `addItemToCanvas` hiện **đã** đặt theo toạ độ chuẩn → chỉ cần giữ nguyên hành vi này; FR-003
  thoả tự nhiên sau khi thêm bước gỡ xung đột.
- `clampCanvasItem` (spec 016, `canvas_layout.dart:437`) đảm bảo nằm trong khung.

**Alternatives considered**: kế thừa vị trí món cũ / đặt giữa canvas — bị loại ở Clarifications.

---

## R4 — Bố cục outerwear + lớp nền (không chồng lấn)

**Decision**: Thêm helper thuần trong `canvas_layout.dart`, ví dụ
`List<CanvasItem> layoutOuterwearBesideBase(List<CanvasItem> items, {canvasWidth, canvasHeight})`:

- Kích hoạt khi trong danh sách có **outerwear** và có **lớp nền** (`top` hoặc `fullbody`).
- Chia đôi bề ngang khả dụng (`availW = canvasWidth - 2*margin`): lớp nền canh **nửa trái**,
  outerwear **nửa phải**.
- Thu `scale` của từng món sao cho bề rộng món ≤ nửa khả dụng (sàn `0.15`), rồi `clampCanvasItem`.
- Giữ `layerOrder` outerwear **trên** lớp nền (như hiện tại).
- Chỉ gọi khi món vừa thêm là outerwear hoặc lớp nền (tránh reset vị trí khi thêm món khác).

**Rationale**:
- Số liệu thật: top ~`100*2.1*1.25 = 262px`, outerwear ~`105*2.3*1.25 ≈ 302px`
  (`canvas_layout.dart:104-114`, outerwear `baseScale 105`); khung điện thoại ~`360-430px` → để **không chồng ngang**,
  mỗi món phải vừa ~nửa khung ⇒ cần thu tỉ lệ (~0.6). Đặt lệch nhỏ (như `x -25`) **không đủ**
  để lộ lớp nền (đã tính: vẫn phủ phần lớn).
- Chia đôi + thu tỉ lệ cho **bất biến kiểm thử được**: mép phải lớp nền ≤ mép trái outerwear.
- Dùng `clampCanvasItem` sẵn có để không tràn biên.

**Alternatives considered**:
- *Hạ outerwear xuống lớp dưới (áo trên)*: bị loại ở Clarifications (Q3 chọn B).
- *Chỉ dịch ngang một lượng cố định, không thu tỉ lệ*: không đủ để hết chồng trên khung hẹp →
  không thoả SC-002.
- *Xếp dọc (trên/dưới)*: ngoài ý "dịch sang bên".

---

## R5 — Hồi tiếp khi thay thế

**Decision**: `addItemToCanvas` trả về `bool` (true nếu có món bị gỡ do thay thế); screen
(drawer `onTap`) hiển thị `ClosyToast.success` "Đã thay thế món cùng loại trên canvas." khi
true. **Không** dùng `successMessage` — screen hiện chỉ consume `aiOutfitProvider.errorMessage`,
không đọc `outfitStudioProvider.successMessage`.

**Rationale**:
- FR-007 yêu cầu phản hồi rõ ràng. `ClosyToast` đã dùng rộng khắp app.
- Tránh Dialog chặn luồng dàn đồ (thao tác liên tục).

**Alternatives considered**: Dialog xác nhận trước khi thay — phiền cho thao tác lặp; bị loại.

---

## Tổng hợp

| # | Ảnh hưởng | File |
|---|---|---|
| R1 | Tập vai trò độc quyền | `canvas_layout.dart` |
| R2 | Gỡ xung đột khi thêm | `outfit_studio_provider.dart` |
| R3 | Vị trí chuẩn + kẹp | `outfit_studio_provider.dart` (đã có) |
| R4 | Bố cục outerwear hai cột | `canvas_layout.dart` + gọi trong provider |
| R5 | Toast thay thế | `outfit_studio_provider.dart` + screen |

Không có NEEDS CLARIFICATION còn lại. Không thêm dependency/endpoint.
