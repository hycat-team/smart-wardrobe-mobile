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

**Decision**: Khi thay món **cùng vai trò**, món mới giữ **đúng** `positionX/Y` và `scale` của
món cũ (**thay tại chỗ**). Khi **thêm mới** (không có món cùng vai trò), đặt theo toạ độ chuẩn
của vai trò với `scale` = mức chung của canvas (trung bình, `1.0` khi trống); rồi `clampCanvasItem`.

**Rationale**:
- Bản chỉnh 2026-10-13 (feedback tester): thay giày/nón/phụ kiện trước đây nhảy về toạ độ chuẩn
  → cách xa vị trí cũ. Người dùng muốn thay **tại chỗ, đúng kích thước cũ**.
- `addItemToCanvas` đã gỡ món cùng vai trò; chỉ cần lấy `positionX/Y/scale` của món bị gỡ để đặt
  món mới (đổi từ `removeWhere` sang lấy phần tử trước khi xoá).
- `clampCanvasItem` đảm bảo vẫn trong khung kể cả khi món cũ bị kéo sát biên.

**Alternatives considered**: đặt theo vị trí chuẩn (bản gốc) — bị bác; đặt giữa canvas — loại.

---

## R4 — Bố cục áo khoác + lớp nền (bằng áo, chồng ≤40%, đối diện phụ kiện)

**Decision**: Helper thuần `layoutOuterwearOverBase(items, {canvasWidth, canvasHeight})` trong
`canvas_layout.dart`:

- **Bản chỉnh 2026-10-13 (lần 3, sau feedback tester)**:
  - Kích hoạt khi có **outerwear** và có **lớp nền** (`top`/`fullbody`).
  - Áo khoác **rộng bằng lớp nền** (`owScale = newBaseW / owCoeff`).
  - Đặt áo khoác ở **phía đối diện phụ kiện** (nếu có phụ kiện); ngược lại chọn phía nhiều chỗ.
  - Chồng ngang **≤ `0.40 * baseWidth`**; khung hẹp thì **thu cùng tỉ lệ** cả hai (giữ bằng nhau,
    sàn `0.15`) để vẫn thoả ≤40%.
  - Lớp nền **không dời vị trí** (cột giữa); outerwear giữ `layerOrder` trên; kẹp toàn bộ vào khung.
  - Gọi ở các luồng đặt món: `addItemToCanvas` (khi thêm outerwear/top/fullbody/**accessory**),
    `loadFromAIRecommendation`, `loadIntoStudio` (+ relayout khi đo được kích thước canvas).

**Rationale**:
- Tester muốn áo khoác **to bằng áo** và **đè ≤40%** (không né hoàn toàn, không che kín); đồng thời
  **phụ kiện ↔ áo khoác đối diện**, quần áo làm cột giữa.
- Không dời nền ⇒ không gây chồng chéo với món khác loại.

**Alternatives considered**:
- *Thu nhỏ riêng áo khoác (bản 20%)*: áo khoác nhỏ hơn áo — trái ý "to bằng áo".
- *Hạ outerwear xuống lớp dưới*: bị loại ở Clarifications Q3.
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
