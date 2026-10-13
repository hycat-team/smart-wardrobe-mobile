# Implementation Plan: Canvas một món mỗi loại + sửa áo khoác đè lớp nền

**Branch**: `017-canvas-single-item` | **Date**: 2026-10-13 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/017-canvas-single-item/spec.md`

## Summary

Hai hành vi cho Studio Thủ Công:

1. **Một món mỗi loại** — canvas giữ tối đa một món cho mỗi loại thuộc **nhóm quần áo cơ
   bản** (áo trên, quần, đầm liền thân, áo khoác, giày). Thêm món trùng loại → **thay thế**
   món cũ. Mũ/phụ kiện vẫn nhiều món. Đầm chỉ thay **áo** (giữ quần). Món mới đặt theo **vị
   trí chuẩn của loại** rồi kẹp trong khung (Clarifications 2026-10-13).
2. **Áo khoác không đè lớp nền** — hiện outerwear (`zIndex 7`) và top (`zIndex 5`) gần như
   cùng vị trí (`x -25` vs `0`, `y -145` vs `-140`) nên outerwear che lớp nền. Sửa: khi
   outerwear cùng canvas với lớp nền (áo trên **hoặc** đầm), xếp **hai cột** (lớp nền nửa
   trái, outerwear nửa phải), thu tỉ lệ để cả hai vừa nửa khung → **không chồng lấn**.

Hướng kỹ thuật: thêm bước "chống trùng theo vai trò" vào `OutfitStudioNotifier.addItemToCanvas`
(tái dùng bảng vai trò `normalizeRole`/`CanvasRole` đã có), và một helper bố cục mới trong
`canvas_layout.dart` cho cặp outerwear + lớp nền. Không đổi BE, không thêm route.

## Technical Context

**Language/Version**: Dart 3.x · Flutter 3.x (stable)

**Primary Dependencies**: `flutter_riverpod ^2.5.1` (StateNotifierProvider) · `go_router ^14.2.0` ·
`google_fonts` · `cached_network_image`. Không thêm dependency mới.

**Storage**: không đổi. Thay thế chỉ tác động state trong RAM + bản lưu outfit (vẫn dùng
`positionX/Y`, `scale`, `layerOrder`).

**Testing**: `flutter test` (unit/widget). Thêm test pure-unit cho provider (thay thế theo
vai trò, bố cục outerwear) và test cho helper layout.

**Target Platform**: Android (phát hành) + Web (dev/QA) — mã dùng chung.

**Project Type**: mobile-app + web, feature-first layered
(`lib/core/` → `lib/features/outfit_studio/` → `lib/shared/`).

**Performance Goals**: thêm món vẫn mượt (một lượt tính danh sách, không vòng rebuild).

**Constraints**: Quiet Luxury — palette/typography dự án; ảnh qua `ClosyNetworkImage`; tiếng
Việt không mojibake. Không dùng `setState` cho business logic; thao tác qua notifier.

**Scale/Scope**: 2 nhóm FR chính (FR-001..004, FR-005), ~3 file sửa lõi (layout, provider, screen) + 2 file test; nhóm
nhỏ, một phase.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Nguyên tắc | Áp dụng | Kết quả |
|---|---|---|
| **I. Spec-Driven & Verify-First** | Đi qua specify → clarify → plan → tasks → implement. > 1 file | ✅ |
| **II. Kiến trúc & kỷ luật Riverpod** | Logic thay thế/bố cục đặt trong `OutfitStudioNotifier` + helper thuần (không `setState`) | ✅ |
| **III. Không mock khi đã có API** | Không sửa BE; tái dùng `CanvasRole`/`normalizeRole` | ✅ |
| **IV. Quiet Luxury & media** | Không đổi UI kit; ảnh vẫn `ClosyNetworkImage` | ✅ |
| **V. Gotcha Windows & build** | Chỉ sửa file bằng `edit`/`write`; không codegen | ✅ |
| **VI. An toàn phát hành** | Không commit secret; không sửa BE; không thêm route/deep-link | ✅ |

**Kết luận gate**: PASS, không có vi phạm cần biện minh.

## Các quyết định kỹ thuật đã chốt (tóm tắt)

Chi tiết và phương án bị loại ở [research.md](./research.md).

| # | Quyết định | Nguồn |
|---|---|---|
| R1 | Tập vai trò **độc quyền** = `{top, bottom, fullbody, outerwear, footwear}`. `{headwear, accessory, other, unknown}` cho phép nhiều món | R1 |
| R2 | `addItemToCanvas`: sau khi dựng món mới, **gỡ mọi món xung đột** trong danh sách rồi mới thêm: cùng vai trò (nếu độc quyền) + quy tắc **đầm↔áo** (thêm `fullbody` gỡ `top`; thêm `top` gỡ `fullbody`; `bottom` độc lập) | R2 |
| R3 | Món mới đặt theo **toạ độ chuẩn của vai trò** (`roleCoordinates*`) rồi `clampCanvasItem` — **không** kế thừa vị trí món cũ; `scale` giữ theo mức chung của canvas (FR-003) | R3 |
| R4 | Bố cục **outerwear + lớp nền**: chia đôi khung — lớp nền ở nửa trái, outerwear nửa phải; thu tỉ lệ từng món để vừa nửa khung (sàn 0.15) → **không chồng ngang**; giữ `layerOrder` outerwear trên | R4 |
| R5 | Hồi tiếp thay thế: `addItemToCanvas` trả về `bool` (true khi có gỡ) → screen `ClosyToast.success` (không Dialog, không `successMessage`) | R5 |

### Phát hiện quan trọng ảnh hưởng thiết kế

- `addItemToCanvas` đã đặt món theo `roleCoordinates*` + `clampCanvasItem` (spec 016) → chỉ
  cần chèn bước gỡ xung đột **trước** khi chọn `coordinateMap` (vì `hasFullbody` đổi khi gỡ
  đầm/áo).
- Outerwear và `accessory` đều dùng `x` âm/lệch — bố cục hai cột ở R4 phải chạy **sau** khi
  danh sách chốt, và kẹp lại (helper `clampCanvasItem`).
- Bán kính món khá lớn: top ~`100*2.1*1.25 = 262px`, outerwear ~`105*2.3*1.25 ≈ 302px`
  (outerwear `baseScale 105`). Trên khung ~390px, hai món cạnh nhau phải thu tỉ lệ (~0.6) mới
  hết chồng → R4 có thu tỉ lệ.

## Project Structure

### Documentation (this feature)

```text
specs/017-canvas-single-item/
├── spec.md
├── plan.md                 # File này
├── research.md             # Phase 0 — R1..R5
├── data-model.md           # Phase 1 — CanvasItem, tập vai trò, bất biến
├── quickstart.md           # Phase 1 — kịch bản kiểm chứng
├── contracts/
│   └── canvas-rules.md     # Hợp đồng hành vi canvas
├── checklists/requirements.md
└── tasks.md                # Đã tạo — T001–T014
```

### Source Code (repository root)

```text
lib/features/outfit_studio/
├── layout/canvas_layout.dart              # M: + tập vai trò độc quyền + helper bố cục outerwear
├── providers/outfit_studio_provider.dart  # M: addItemToCanvas gỡ xung đột + bố cục outerwear
└── presentation/outfit_studio_screen.dart # M: toast khi món bị thay thế (drawer onTap)

test/
├── studio_single_item_per_role_test.dart  # A: thay thế theo vai trò + quy tắc đầm↔áo
└── canvas_outerwear_layout_test.dart      # A: outerwear không chồng lớp nền
```

**Structure decision**: giữ nguyên feature-first; mọi thay đổi nằm trong `outfit_studio`
(layout + provider + screen). UI đổi: thêm toast thông báo khi món bị thay thế.

## Test Impact

| File | Loại | Hành vi |
|---|---|---|
| `studio_single_item_per_role_test.dart` | Mới | Thêm 2 áo → còn 1; thêm đầm khi có áo+quần → gỡ áo giữ quần; thêm áo khi có đầm → gỡ đầm; phụ kiện/mũ nhiều món vẫn giữ |
| `canvas_outerwear_layout_test.dart` | Mới | Thêm áo rồi áo khoác → hai món không chồng ngang, đều trong khung; lặp với đầm |
| `studio_canvas_placement_test.dart` | Regression | Chạy lại để chắc bước gỡ xung đột không phá kẹp-biên (spec 016) |
| `canvas_layout_test.dart` | (không đổi trừ khi helper đặt trong file này) | — |

## Thứ tự triển khai

Một phase gọn: **R1+R2+R3** (thay thế theo vai trò) → **R4** (bố cục outerwear) → gate + commit.
Cả hai đụng cùng 2 file nên làm tuần tự trong một phase.

## Rà lại Constitution Check sau Phase 1

| Nguyên tắc | Kết quả sau thiết kế |
|---|---|
| II — Riverpod | Logic thuần trong notifier + helper `canvas_layout.dart`; không `setState` |
| III — không mock | Không chạm BE; dùng enum vai trò sẵn có |
| IV — media/UI | Không thêm ảnh mới; toast dùng `ClosyToast` |
| VI — không sửa BE/route | Đã xác minh phạm vi chỉ trong `outfit_studio` |

**Kết luận**: PASS. Sẵn sàng sang `/speckit.tasks`.

## Complexity Tracking

> Không có vi phạm hiến pháp. Để trống có chủ đích.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| *(không có)* | — | — |

## Rủi ro còn lại

| Rủi ro | Giảm thiểu |
|---|---|
| Bố cục hai cột làm món nhỏ hơn kỳ vọng | Chỉ áp dụng khi outerwear + lớp nền cùng tồn tại; thu tỉ lệ có sàn 0.15; kẹp trong khung |
| Người dùng đã kéo outerwear rồi thêm món khác | Bố cục chỉ chạy khi món vừa thêm là outerwear hoặc lớp nền; không reset khi thêm giày/phụ kiện |
| Thay thế có thể gỡ nhầm khi vai trò món `unknown` | `unknown/other` không độc quyền → không gỡ |
| Lưu outfit cũ có nhiều món cùng vai trò | Chỉ chuẩn hoá khi **thêm tay**; luồng khôi phục giữ nguyên (ngoài phạm vi) |
