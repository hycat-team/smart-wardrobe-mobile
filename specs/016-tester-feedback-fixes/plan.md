# Implementation Plan: Sửa lỗi theo phản hồi tester (đợt 1)

**Branch**: `016-tester-feedback-fixes` | **Date**: 2026-10-13 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/016-tester-feedback-fixes/spec.md`

## Summary

Mười phản hồi tester gom thành 7 nhóm việc độc lập, ưu tiên P1→P3:

1. **Tràn viền khi thêm món (Studio Thủ Công)** — `addItemToCanvas` đặt món theo bảng
   toạ độ chuẩn hoá cố định (thiết kế cho canvas ~360×520) và **không kẹp** theo kích
   thước canvas thật, nên phụ kiện (`x=-240`), giày (`y=295`) và món "khác"
   (`x=250,y=180`) rơi ra ngoài màn hình.
2. **Thiếu danh mục "Áo khoác" + khay khựng + không đóng bằng icon** — khay tủ đồ chỉ có
   `All/Áo/Quần/Váy/Giày/Phụ kiện`; `_onSheetScrolled` gọi `setState` cả màn khi vượt
   ngưỡng 0.15 gây rebuild nặng; mũi tên hạ xuống là `Icon` tĩnh, không bấm được.
3. **Chưa có nút "Xóa tất cả"** — provider **đã có** `clearCanvas()` nhưng chưa có nút UI.
4. **Chat AI không render Markdown** — `_buildMessageBubble` dùng `Text(msg.cleanContent)` thô.
5. **Dư ô "Demo"** ở màn Đăng ký — ActionChip "Điền mẫu tự động (Demo)" + `_fillSampleRegister`.
6. **Nút "Phối đồ Studio"** ở chi tiết món đồ — cần gỡ khỏi thanh hành động đáy.
7. **Hàng lọc loại bài trong tìm kiếm Community** — gỡ hàng "Tất cả bài / Bộ phối / Ảnh/Video".

Hướng kỹ thuật: sửa gốc ở tầng layout canvas (kẹp/đo theo kích thước thật); tái dùng
`normalizeRole` + `outfitRoleLabelVi` đã có để phân loại "Áo khoác"; gỡ `setState` nặng
ở khay bằng giá trị theo dõi cục bộ; thêm **một** thư viện render Markdown đã được bảo trì
(`flutter_markdown_plus`) và bọc trong design system Quiet Luxury; các nhóm còn lại là gỡ
thành phần UI theo yêu cầu tester.

## Technical Context

**Language/Version**: Dart 3.x · Flutter 3.x (stable)

**Primary Dependencies**: `flutter_riverpod ^2.5.1` (StateNotifierProvider) ·
`go_router ^14.2.0` · `dio ^5.4.3` · `google_fonts` (Playfair Display + Be Vietnam Pro) ·
`cached_network_image` · **MỚI**: `flutter_markdown_plus` (bản kế thừa được bảo trì của
`flutter_markdown` đã ngừng phát triển)

**Storage**: không đổi (`flutter_secure_storage` cho token). Markdown render thuần client.

**Testing**: `flutter test` (unit + widget). Cập nhật test bị ảnh hưởng bởi việc gỡ UI
(`community_search_filter_test.dart`, `wardrobe_status_widget_test.dart`) và thêm test mới
cho clamp canvas + phân loại "Áo khoác" + render Markdown.

**Target Platform**: Android (phát hành) + Web (dev/QA) — mã dùng chung.

**Project Type**: mobile-app + web, feature-first layered
(`lib/core/` → `lib/features/<domain>/{data,models,presentation,providers}/` → `lib/shared/`).

**Performance Goals**: kéo khay tủ đồ không giật thấy rõ (SC-002, QS thủ công — repo chưa có
harness đo FPS); thêm/nạp món không
rebuild toàn màn canvas; render Markdown không nhấp nháy lỗi khi stream (FR-009).

**Constraints**: Quiet Luxury — nền `#FAF8F5`, surface `#FFFFFF`, chữ `#1A1A1A`, viền
`#E8E3DC`, cấm `Colors.red`/`Colors.blue` thuần (ngoại lệ hiện hữu `Colors.redAccent` cho
nút xoá đã có sẵn); tiêu đề Playfair Display, body/label Be Vietnam Pro; ảnh mạng bắt buộc
`ClosyNetworkImage`; vùng chạm ≥44px; tiếng Việt không mojibake.

**Scale/Scope**: 7 nhóm FR, ~8 file sửa + 1 dependency + ~4 file test mới/sửa. Các nhóm
độc lập về kỹ thuật, triển khai theo thứ tự WS-A→G.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Nguyên tắc | Áp dụng cho thay đổi này | Kết quả |
|---|---|---|
| **I. Spec-Driven & Verify-First** | Đi qua specify → clarify → plan → tasks → implement. > 1 file nên bắt buộc có spec | ✅ Đang ở `/speckit-plan` |
| **II. Kiến trúc & kỷ luật Riverpod** | Sửa business logic qua `OutfitStudioNotifier` (không `setState` nặng); state/UI mới nullable-safe | ✅ Ghi vào WSB/T010 |
| **III. Không mock khi đã có API** | Không sửa BE. Markdown render thuần client. Search Community **ngừng gửi** `postType` (không thêm mock) | ✅ |
| **IV. Quiet Luxury & hiệu năng media** | Markdown style dùng Be Vietnam Pro + palette Quiet Luxury; ảnh vẫn qua `ClosyNetworkImage`; vùng chạm nút ≥44px | ✅ |
| **V. Gotcha Windows & build** | Chỉ sửa file bằng `edit`/`write`; giữ `kotlin.incremental=false`; thêm dependency qua `flutter pub get` | ✅ |
| **VI. An toàn phát hành** | Không commit secret; không sửa BE; không đụng `ENABLE_PAID_FEATURES`/deep-link (không thêm route) | ✅ |

**Kết luận gate**: PASS. Không có vi phạm cần biện minh. Rà lại sau Phase 1 (mục cuối file).

## Các quyết định kỹ thuật đã chốt (tóm tắt)

Chi tiết và phương án bị loại nằm ở [research.md](./research.md).

| # | Quyết định | Nguồn |
|---|---|---|
| R1 | Sửa tràn biên ở luồng **thêm món thủ công**: đo canvas thật (`state.canvasWidth/Height`, fallback 360×520), kẹp vị trí món mới theo công thức kích thước hiện có (`baseScale*boxRatio*scale*1.25` + margin); nếu món tự lớn hơn canvas thì thu nhỏ `scale` vừa khung. Nạp set/khôi phục dùng `layoutCanvasItems` (fit-to-canvas) sẵn có | R1 |
| R2 | Thêm chip **"Áo khoác"** = `normalizeRole(...) == CanvasRole.outerwear`; chip **"Áo"** trừ áo khoác. Giữ nguyên hành vi chuỗi của các chip còn lại để tránh hồi quy | R2 |
| R3 | Bỏ `setState` theo ngưỡng trong `_onSheetScrolled`; theo dõi trạng thái mở/đóng bằng notifier cục bộ để chỉ header + nút lưu rebuild, canvas không rebuild. Mũi tên hạ xuống thành `IconButton` gọi `_toggleDrawer` | R3 |
| R4 | Render Markdown bằng **`flutter_markdown_plus`** với `MarkdownBody` + `MarkdownStyleSheet` Quiet Luxury; render cả khi streaming | R4 |
| R5 | Tái dùng `OutfitStudioNotifier.clearCanvas()` (đã có, chưa dùng) cho nút **"Xóa tất cả"**; thêm nút vào thanh công cụ phải, có dialog xác nhận | R5 |
| R6 | Gỡ hàng lọc loại bài ở `community_search_screen.dart`; ngừng truyền `postTypeFilter` (luôn `null`). Giữ nguyên hàng segmented `Tất cả/Tác giả/Bài viết` | R6 |
| R7 | Gỡ ActionChip "Demo" + `_fillSampleRegister` ở `register_screen.dart` | R7 |
| R8 | Gỡ `ElevatedButton.icon` "Phối đồ Studio" ở `item_detail_screen.dart`; cho "Chỉnh sửa" giãn full width; gỡ import/push `/studio` không còn dùng | R8 |

### Phát hiện quan trọng ảnh hưởng thiết kế

- **`clearCanvas()` đã tồn tại** trong provider (`outfit_studio_provider.dart:457`) nhưng
  **không có caller nào** — nút "Xóa tất cả" chỉ cần nối vào, không thêm method mới.
- **`outfitRoleLabelVi('outerwear')` đã trả "Áo khoác"** — dùng làm nhãn chip để nhất quán
  với nhãn vai trò ở Stylist (đã có test `stylist_recommendation_contract_test.dart`).
- **Hai test sẽ hỏng nếu không cập nhật**: `community_search_filter_test.dart` (assert 3
  chip "Tất cả bài/Bộ phối/Ảnh-Video" và "hàng 2 chỉ hiện khi tab Bài viết") và
  `wardrobe_status_widget_test.dart` (3 chỗ assert nút "Phối đồ Studio"). Đây là test của
  hành vi **bị thay đổi có chủ đích** — phải sửa cùng, không tính là hồi quy.
- `_onSheetScrolled` hiện `setState` cả `_OutfitStudioScreenState`; vì `_buildManualStudioTab`
  chứa cả canvas + khay, mỗi lần vượt ngưỡng sẽ rebuild toàn bộ cây canvas → nguồn "khựng"
  chính khi kéo khay.

## Project Structure

### Documentation (this feature)

```text
specs/016-tester-feedback-fixes/
├── spec.md                          # Đặc tả (7 user story, 12 FR, 8 SC)
├── plan.md                          # File này
├── research.md                      # Phase 0 — 8 quyết định (R1–R8)
├── data-model.md                    # Phase 1 — CanvasItem/Category/Post/Message
├── quickstart.md                    # Phase 1 — kịch bản kiểm chứng
├── contracts/
│   ├── community-search.md          # Hợp đồng request tìm kiếm (bỏ postType)
│   └── stylist-markdown.md          # Hợp đồng hiển thị nội dung chat
├── checklists/
│   └── requirements.md              # 12/12
└── tasks.md                         # Đã tạo — T001–T032
```

### Source Code (repository root)

```text
lib/
├── features/
│   ├── outfit_studio/
│   │   ├── layout/canvas_layout.dart              # M: + helper clamp/fit cho thêm lẻ
│   │   ├── providers/outfit_studio_provider.dart  # M: addItemToCanvas kẹp theo canvas;
│   │   │                                          #    filteredWardrobeItems + "Áo khoác"
│   │   └── presentation/outfit_studio_screen.dart # M: nút "Xóa tất cả"; bỏ setState ngưỡng;
│   │                                              #    icon mũi tên bấm đóng; chip "Áo khoác"
│   ├── auth/presentation/register_screen.dart     # M: gỡ ActionChip Demo + _fillSampleRegister
│   ├── stylist/presentation/stylist_screen.dart   # M: MarkdownBody thay Text thô
│   ├── wardrobe/presentation/item_detail_screen.dart # M: gỡ nút "Phối đồ Studio"
│   └── community/
│       ├── providers/community_search_provider.dart  # M: bỏ/ngưng dùng postTypeFilter
│       └── presentation/community_search_screen.dart # M: gỡ hàng lọc loại bài
└── pubspec.yaml                                   # M: + flutter_markdown_plus

test/
├── canvas_layout_test.dart                    # M: + test clamp kẹp 1 món vào biên
├── studio_canvas_placement_test.dart          # A: addItemToCanvas không tràn (accessory/footwear/other)
├── studio_drawer_category_test.dart           # A: "Áo khoác" lọc đúng; "Áo" trừ khoác
├── studio_clear_all_test.dart                 # A: clearCanvas() xoá sạch + bỏ chọn
├── stylist_markdown_render_test.dart          # A: cú pháp Markdown render, không lộ ký tự thô
├── community_search_filter_test.dart          # M: bỏ assert hàng 2 lọc loại bài
└── wardrobe_status_widget_test.dart           # M: bỏ assert nút "Phối đồ Studio"
```

**Structure decision**: giữ nguyên cấu trúc feature-first. 7 nhóm sửa nằm ở 5 feature
(`outfit_studio`, `auth`, `stylist`, `wardrobe`, `community`) nhưng **tái dùng** tiện ích
đã có (`normalizeRole`, `outfitRoleLabelVi`, `clearCanvas`, `layoutCanvasItems`) thay vì
nhân bản. Không tạo route mới, không tạo layer mới.

## Thứ tự triển khai

Các nhóm độc lập; thứ tự ưu tiên theo spec:

```
WS-A (US1, P1)  Canvas placement không tràn   → canvas_layout + provider + screen
WS-B (US2, P1)  Khay: "Áo khoác" + mượt + icon → provider + screen
WS-C (US3, P2)  Nút "Xóa tất cả"               → screen (dùng clearCanvas)
WS-D (US4, P2)  Chat AI Markdown               → pubspec + stylist_screen
WS-E (US5, P3)  Gỡ ô Demo đăng ký              → register_screen
WS-F (US6, P3)  Gỡ nút Studio ở chi tiết món   → item_detail_screen
WS-G (US7, P3)  Gỡ hàng lọc loại bài search    → community_search_screen + provider
```

Mỗi nhóm tự kiểm thử được và có thể dừng giữa chừng mà vẫn bàn giao phần đã xong. WS-A và
WS-B cùng đụng `outfit_studio_screen.dart` nên làm tuần tự (A trước, B sau). WS-D cần
`flutter pub get` trước khi code.

## Test Impact

| File | Loại | Hành vi |
|---|---|---|
| `community_search_filter_test.dart` | Sửa | Các assert hàng 2 (`Tất cả bài/Bộ phối/Ảnh-Video`, "hàng 2 chỉ hiện khi tab Bài viết") phải đổi thành assert **không tồn tại** |
| `wardrobe_status_widget_test.dart` | Sửa | 3 chỗ `find.widgetWithText(ElevatedButton, 'Phối đồ Studio')` phải gỡ (nút đã bỏ) |
| `studio_canvas_placement_test.dart` | Mới | Thêm accessory/footwear/other vào canvas nhỏ → mọi món nằm trong biên |
| `studio_drawer_category_test.dart` | Mới | Chip "Áo khoác" chỉ ra outerwear; "Áo" không chứa outerwear |
| `studio_clear_all_test.dart` | Mới | `clearCanvas()` → `canvasItems` rỗng, không còn selection |
| `stylist_markdown_render_test.dart` | Mới | `**đậm**`/danh sách render thành widget Markdown, không còn `**` thô |

## Rà lại Constitution Check sau Phase 1

| Nguyên tắc | Kết quả sau thiết kế |
|---|---|
| II — không `setState` cho business logic | Trạng thái mở/đóng khay là **UI state cục bộ** (không phải business) — dùng notifier cục bộ vẫn đúng; dữ liệu canvas đi qua `OutfitStudioNotifier` |
| III — không mock | Search Community **ngừng gửi** `postType` thay vì lọc giả ở client; không thêm dữ liệu giả |
| IV — Quiet Luxury & media | Markdown style sheet dùng Be Vietnam Pro + palette dự án; không thêm `Image.network` |
| V — build ổn định | Thêm 1 dependency; chạy `flutter pub get` rồi `flutter analyze` 0 issues |
| VI — không sửa BE / secret | Chỉ đọc API; không thêm route/deep-link; không đụng cờ phát hành |

**Kết luận**: PASS. Sẵn sàng sang `/speckit-tasks`.

## Complexity Tracking

> Không có vi phạm hiến pháp nào. Mục này để trống có chủ đích.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| *(không có)* | — | — |

## Rủi ro còn lại

| Rủi ro | Giảm thiểu |
|---|---|
| Thêm dependency `flutter_markdown_plus` (bên thứ ba) | Là bản kế thừa chính thức của gói Flutter đã ngừng; kiểm `flutter analyze` 0 issues + test render; nếu rủi ro supply-chain, phương án B là renderer tối giản nội bộ (ghi ở research R4) |
| Markdown stream có thể nhấp nháy khi cú pháp chưa đóng | Tin nhắn Stylist thường ngắn; render trực tiếp; nếu nháy rõ thì thêm sanitizer cân dấu fence (ghi ở research R4) |
| Kẹp 1 món có thể chồng lên món khác khi canvas nhỏ | Chấp nhận (FR-003(a)/(b); edge case spec cho phép chồng một phần); người dùng kéo lại được; nạp set vẫn dàn chuẩn |
| "Áo" trừ khoác làm vài món cũ đổi chỗ lọc | Đã chốt ở Clarifications; test `studio_drawer_category_test.dart` khoá hành vi |
| Sửa test đang xanh (`community_search_filter_test`, `wardrobe_status_widget_test`) | Là thay đổi hành vi có chủ đích theo spec; ghi rõ trong work-log, không tính pre-existing |
