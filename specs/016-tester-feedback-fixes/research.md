# Phase 0 — Research: Sửa lỗi theo phản hồi tester (đợt 1)

**Feature**: `016-tester-feedback-fixes` · **Date**: 2026-10-13

Mọi mục dưới đây đã đối chiếu **mã nguồn thật** trong repo (không suy đoán). Nguồn được
ghi rõ theo `file:line`.

---

## R1 — Xử lý món tràn biên khi thêm thủ công vào canvas

**Decision**: Sửa ở tầng layout + provider, dùng **kích thước canvas thật** đã được màn
hình báo về (`OutfitStudioState.canvasWidth/canvasHeight`, fallback `360×520`):

1. Thêm helper `clampCanvasItem(CanvasItem, canvasW, canvasH)` trong `canvas_layout.dart`,
   tổng quát hoá `_clamp` hiện có (đang là private, margin 8px). Nếu món **tự lớn hơn**
   vùng khả dụng, trước tiên giảm `scale` để `itemW/H ≤ avail` rồi mới kẹp vị trí.
   Kích thước dùng đúng công thức render: `baseScale * boxRatio * scale * 1.25`.
2. `OutfitStudioNotifier.addItemToCanvas` gọi `clampCanvasItem(newItem, ...)` trước khi
   ghi state. **Chỉ kẹp món mới**, không dịch các món đã có → thao tác dàn đồ không bị xáo.
3. Nạp nhiều món (set AI / khôi phục outfit) đã đi qua `layoutCanvasItems` (fit-to-canvas)
   — giữ nguyên.

Đây đúng phương án **kết hợp** đã ghi ở `spec.md` FR-003 (và Clarifications 2026-10-13 của đợt
specify trước): kẹp khi thêm lẻ, fit-to-canvas khi nạp cụm.

**Rationale**:
- Gốc lỗi: `addItemToCanvas` (`outfit_studio_provider.dart:280-320`) lấy thẳng
  `coordinateMap[role]` — bảng `roleCoordinatesSeparate/Fullbody` (`canvas_layout.dart:52-75`)
  thiết kế cho canvas ~360×520. Phụ kiện `x=-240` (⌀ ~136px → trái ≈ -308px), giày `y=295`
  (cao ~117px → đáy ≈ +354px), "other" `x=250,y=180`. Trên canvas hẹp thấp hơn, các món này
  vượt biên. Không có bước kẹp nào trong luồng thêm.
- `_clamp` (`canvas_layout.dart:432-443`) đã có sẵn đúng công thức kích thước nhưng chỉ
  được gọi trong `layoutCanvasItems`; đưa ra thành helper công khai + thêm nhánh thu nhỏ
  cho món quá khổ là mở rộng tối thiểu.
- Canvas thật đã được đo và lưu (`setCanvasSize`, `outfit_studio_provider.dart:253-278`;
  gọi post-frame ở `outfit_studio_screen.dart:1432-1437`) nên không cần thêm cơ chế đo.

**Alternatives considered**:
- *Kẹp toàn cụm mỗi lần thêm (phương án B)*: làm mọi món dịch chuyển khi thêm món mới →
  phá thao tác dàn thủ công của người dùng. Loại.
- *Đổi thẳng toạ độ trong bảng `roleCoordinates*`*: là toạ độ tuyệt đối, không co giãn
  theo kích thước canvas → vẫn tràn ở kích thước khác. Loại.
- *Luôn gọi `layoutCanvasItems` khi thêm*: re-center cả cụm mỗi lần thêm → nhảy bố cục; và
  `layoutCanvasItems` xử lý cụm chứ không phải "đặt 1 món vào chỗ hợp lý". Loại.

---

## R2 — Danh mục lọc "Áo khoác" và phạm vi chip "Áo"

**Decision**: Thêm chip `Áo khoác` vào danh sách chip khay (`outfit_studio_screen.dart:2005`)
và mở rộng `OutfitStudioState.filteredWardrobeItems` (`outfit_studio_provider.dart:56-96`):

- `Áo khoác` → `normalizeRole(null, categorySlug: slug, categoryName: name) == CanvasRole.outerwear`.
- `Áo` → giữ điều kiện chuỗi hiện có **VÀ** `role != CanvasRole.outerwear` (loại trừ khoác).

Nhãn chip lấy từ `outfitRoleLabelVi('outerwear')` = `"Áo khoác"` để nhất quán với Stylist.

**Rationale**:
- `normalizeRole` (`canvas_layout.dart:117-276`) đã nhận diện đầy đủ outerwear
  (`khoác/jacket/blazer/coat/cardigan`, slug `ao-khoac`) và đã có test
  (`canvas_layout_test.dart:11`). Tái dùng thay vì viết bộ khớp chuỗi mới.
- Clarification 2026-10-13 đã chốt `Áo` **loại trừ** áo khoác (mỗi món thuộc đúng 1 chip).
- Chỉ đổi hành vi của `Áo` và thêm `Áo khoác`; các chip `Quần/Váy/Giày/Phụ kiện` giữ nguyên
  để tránh hồi quy (đặc biệt `Váy` hiện khớp cả `váy` (bottom) lẫn `đầm` (fullbody), nếu
  chuyển sang `normalizeRole` sẽ hụt `đầm`).

**Alternatives considered**:
- *Dùng `normalizeRole` cho mọi chip*: hồi quy phân loại `Váy`/`Quần` (skirt vs dress).
  Loại để giữ tối thiểu thay đổi.
- *Thêm chip nhưng giữ `Áo` bao gồm khoác (phương án B)*: trùng lặp kết quả lọc, đã bị loại
  ở Clarifications.

---

## R3 — Làm mượt khay tủ đồ + đóng bằng icon mũi tên

**Decision**:
1. Bỏ `setState` trong `_onSheetScrolled` (`outfit_studio_screen.dart:83-94`). Thay bằng một
   `ValueNotifier<bool>` cục bộ (trạng thái mở/đóng khay) được cập nhật khi vượt ngưỡng.
2. Bọc **chỉ** phần phụ thuộc trạng thái — thanh tiêu đề khay (`_buildStickyDrawerHeader`)
   và phép dịch nút "Lưu" (`Positioned.fill` + `ListenableBuilder`, dòng 1867-1890) — trong
   `ValueListenableBuilder`, để cây canvas **không** rebuild khi vượt ngưỡng.
3. Đổi `Icon(Icons.keyboard_arrow_down_rounded)` ở header mở (`outfit_studio_screen.dart:1989-1993`)
   thành `IconButton` (`onPressed: _toggleDrawer`, tooltip "Thu gọn") đạt vùng chạm ≥44px.

**Rationale**:
- `_onSheetScrolled` gọi `setState` trên `_OutfitStudioScreenState`; `build` dựng cả
  `_buildManualStudioTab` (canvas + `Stack` các món + khay + nút lưu). Mỗi lần vượt ngưỡng
  0.15 → rebuild toàn cây canvas → "khựng" đúng như tester mô tả.
- Thanh handle + tiêu đề ở trạng thái mở đã có `GestureDetector` đóng (dòng 1954-1968),
  nhưng **icon mũi tên** không tách riêng nên người dùng không biết bấm vào đó.
- Giữ `snap: true` + 3 `snapSizes` (1479-1657) — hành vi snap đúng ý đồ, không phải gốc lỗi.

**Alternatives considered**:
- *Giữ `setState` nhưng bọc canvas trong `RepaintBoundary` riêng*: giảm vẽ lại nhưng vẫn
  rebuild cây widget. Không giải quyết gốc. Loại.
- *Cố định chiều cao header một giá trị*: trạng thái thu gọn chỉ cao ~45px (0.065 × viewport),
  không đủ cho header mở 108px. Loại.

---

## R4 — Thư viện render Markdown cho chat Stylist

**Decision**: Thêm **`flutter_markdown_plus`** (bản kế thừa chính thức, được bảo trì, của
`flutter_markdown` đã ngừng) và render bằng `MarkdownBody` với `MarkdownStyleSheet` tuỳ biến
Quiet Luxury (Be Vietnam Pro, palette dự án), giữ nguyên `GoogleFonts` hiện dùng.

**Rationale**:
- `flutter_markdown` gốc do Google **đã ngừng phát triển** (công bố 02/2025, đánh dấu
  discontinued 30/05/2025). `flutter_markdown_plus` là bản kế thừa, cùng API
  (`Markdown`/`MarkdownBody`/`MarkdownStyleSheet`), BSD-3 — thay đổi import gần như 1-1.
- Hỗ trợ đủ nhu cầu FR-009: đậm/nghiêng/tiêu đề/danh sách/liên kết/mã; `selectable`, `onTapLink`.
- Style sheet cho phép khớp typography (Playfair cho heading, Be Vietnam Pro cho body) và
  màu Quiet Luxury → không lệch design system.
- Tin nhắn Stylist thường ngắn; render lại theo từng chunk chấp nhận được (đã kiểm chứng
  bởi test render).

**Alternatives considered**:
- *`gpt_markdown`*: tối ưu cho output AI (cache phần tĩnh, chỉ rebuild đuôi) — tốt cho
  streaming nhưng API/khái niệm styling khác, ít quen thuộc hơn trong repo. Cân nhắc lại nếu
  thấy nháy rõ khi stream.
- *`streamdown` / `flutter_markdown_stream`*: chuyên streaming, xử lý cú pháp chưa đóng — nhưng
  phiên bản 0.x, thêm phức tạp không cần cho tin nhắn ngắn. Loại ở v1.
- *Renderer Markdown tự viết bằng `RichText`*: không thêm dependency nhưng phải tự parse
  list/heading/code/link và dễ sai; nhiều code hơn phương án dùng gói được bảo trì. Loại.
- *`markdown_widget`*: ổn nhưng hướng "cả trang"; không cần. Loại.

**Ghi chú streaming**: `_updateAiMessage` cập nhật nội dung mỗi chunk
(`stylist_provider.dart:285-293`). Nếu thấy nháy, bước tối ưu (không thuộc v1 bắt buộc) là
sanitize cú pháp chưa đóng trước khi render. FR-009 chỉ yêu cầu "không nhấp nháy lỗi" — render
trực tiếp là đủ.

---

## R5 — Nút "Xóa tất cả" trên thanh công cụ phải

**Decision**: Nối nút vào `OutfitStudioNotifier.clearCanvas()` **đã có sẵn**
(`outfit_studio_provider.dart:457-459`). Thêm `IconButton` (icon `delete_sweep_rounded`) vào
thanh công cụ phải trong `_buildManualStudioTab`; hiển thị khi `canvasItems.isNotEmpty`,
bấm → dialog xác nhận (mẫu `AlertDialog` Quiet Luxury) → gọi `clearCanvas()`.

**Rationale**:
- Method đã tồn tại nhưng **không có caller** (grep toàn repo chỉ thấy định nghĩa) → không
  cần thêm logic provider, chỉ thêm UI. `clearCanvas` đặt `canvasItems: []` + `clearSelection`.
- FR-008 yêu cầu chỉ hiện/khả dụng khi có món và xác nhận trước khi xoá.
- Hiện thanh công cụ chỉ hiện khi `selectedIndex != null`
  (`outfit_studio_screen.dart:1546`); cần đổi điều kiện hiển thị sang `canvasItems.isNotEmpty`
  và vô hiệu hoá/ẩn các nút thao tác món khi chưa chọn, để nút "Xóa tất cả" luôn tiếp cận được.

**Alternatives considered**:
- *Thêm `clearCanvasItems()` mới*: trùng với `clearCanvas()`. Loại.
- *Nút không cần xác nhận*: mất toàn bộ bố cục dàn dở chỉ bằng 1 chạm — rủi ro UX. Loại.

---

## R6 — Gỡ hàng lọc loại bài trong tìm kiếm Community

**Decision**: Trong `community_search_screen.dart` bỏ hàng 2 (`Tất cả bài/Bộ phối/Ảnh-Video`,
dòng 190-218), bỏ `_buildPostTypeChip` (dòng 239-267), cố định `preferredSize` chỉ còn hàng 1.
Không truyền `postTypeFilter` (luôn `null`) khi tìm kiếm/`loadMore`.

**Rationale**:
- Yêu cầu tester: bỏ hàng option này. Hàng segmented `Tất cả/Tác giả/Bài viết` (hàng 1, dòng
  177-188) **giữ lại** — phản hồi chỉ nói hàng loại bài.
- `changePostTypeFilter` (`community_search_provider.dart:200-210`) và field `postTypeFilter`
  sẽ không còn caller từ UI; giữ field để tránh thay đổi model rộng, nhưng luôn để `null`.
  Repository đã nhận `postType?` và bỏ khi null (`community_search_repository.dart`).

**Alternatives considered**:
- *Xoá luôn `postTypeFilter` khỏi state/repository*: lan rộng sang model + test không cần
  thiết; giữ tối thiểu thay đổi. Loại cho v1.
- *Giữ hàng nhưng mặc định chọn "Tất cả bài"*: vẫn còn hàng option như tester muốn bỏ. Loại.

---

## R7 — Gỡ ô "Demo" ở màn Đăng ký

**Decision**: Gỡ `ActionChip` "Điền mẫu tự động (Demo)" (`register_screen.dart:285-295`) và
method `_fillSampleRegister` (dòng 84-97). Không đụng API đăng ký.

**Rationale**: `_fillSampleRegister` chỉ được tham chiếu bởi chip đó (grep xác nhận) → gỡ cả
hai an toàn. FR-010 yêu cầu không còn khả năng tự điền dữ liệu mẫu.

**Alternatives considered**: Giữ method nhưng ẩn chip — để lại code chết. Loại.

---

## R8 — Gỡ nút "Phối đồ Studio" ở chi tiết món đồ

**Decision**: Gỡ `ElevatedButton.icon` "Phối đồ Studio" (`item_detail_screen.dart:499-513`),
cho `OutlinedButton` "Chỉnh sửa" giãn toàn bộ hàng, gỡ `context.push('/studio')` và import
`go_router` nếu không còn dùng. Cập nhật `wardrobe_status_widget_test.dart`.

**Rationale**: FR-011 yêu cầu bỏ lối vào Studio ở màn này; các hành động còn lại (chỉnh sửa,
xoá ở appbar, gửi phân tích lại/thử lại) giữ nguyên. Route `/studio` vẫn tồn tại và dùng ở
lối khác (tab Phối đồ AI: `outfit_studio_screen.dart`, list outfit `/outfits`).

**Alternatives considered**: Giữ nút nhưng disable — màn chi tiết không cần lối vào này nữa
theo tester. Loại.

---

## Tổng hợp

| # | Ảnh hưởng chính | File lõi |
|---|---|---|
| R1 | `canvas_layout.dart` (helper) + `outfit_studio_provider.dart` (`addItemToCanvas`) | M |
| R2 | `outfit_studio_provider.dart` (`filteredWardrobeItems`) + `outfit_studio_screen.dart` (chip) | M |
| R3 | `outfit_studio_screen.dart` (`_onSheetScrolled`, header, nút lưu) | M |
| R4 | `pubspec.yaml` + `stylist_screen.dart` | M + dep |
| R5 | `outfit_studio_screen.dart` (thanh công cụ) — method đã có | M |
| R6 | `community_search_screen.dart` + `community_search_provider.dart` | M |
| R7 | `register_screen.dart` | M |
| R8 | `item_detail_screen.dart` | M |

Không có mục nào cần endpoint/BE mới. Không có NEEDS CLARIFICATION còn lại.
