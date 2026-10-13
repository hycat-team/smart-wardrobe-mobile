# Feature Specification: Sửa lỗi theo phản hồi tester (đợt 1)

**Feature Branch**: `016-tester-feedback-fixes`

**Created**: 2026-10-13

**Status**: Draft

**Input**: User description: "sau khi chạy thử một thời gian với tester tôi thu được các feedback sau, lên kế hoạch fix ứng dụng nhé
- Tràn viền khi thêm phụ kiện (trong studio)
- Thiếu slug áo khoác trong studio
- Thêm giày bị tràn viền (trong studio)
- trong studio lúc kéo bảng thêm phụ kiện xuống hơi khựng (làm nó mượt mà hơn), cho bấm vào icon hạ xuống để đóng bảng
- Lúc tạo tài khoản bị dư ô demo (gỡ ô demo)
- Chat với AI bị lỗi markdown (lúc hiện tin nhắn k load đc các định dạng markdown)
- gỡ nút phối đồ bằng studio lúc ấn vào xem chi tiết món đồ
- Trong studio thủ công, ở thanh option bên phải màn hình hãy thêm nút xóa tất cả (để xóa các item trên canvas)
- trong search của community hãy bỏ hàng option Tất cả bài - bộ phối - ảnh/video
- Trong canvas khi thêm mới các item trừ quần áo giày, thì các item khác hiện đang bị tràn ở ngoài màn hình (thảo luận để đưa ra phương án phù hợp)"

## Clarifications

### Session 2026-10-13

- Q: Hành vi chip "Áo" sau khi thêm danh mục "Áo khoác" (mỗi món có được thuộc cả hai không)? → A: "Áo" chỉ áo thân trên (loại trừ áo khoác); áo khoác chỉ hiện ở chip "Áo khoác".

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Thêm món đồ lên canvas không bị tràn viền (Priority: P1)

Người dùng mở **Studio Thủ Công**, kéo khay tủ đồ lên và chạm vào một món (phụ kiện, giày, mũ, hoặc món "khác") để thêm vào canvas. Món đồ phải xuất hiện **trọn vẹn bên trong vùng canvas** ngay lần đặt đầu tiên — không bị cắt mất một phần hay nằm hoàn toàn ngoài màn hình — bất kể loại món, kích thước món, hay kích thước màn hình thiết bị.

**Why this priority**: Đây là lỗi chặn thao tác chính của Studio (không thấy/không kéo được món vừa thêm). Phụ kiện và giày hiện là hai trường hợp tester báo rõ; các món "khác" (unknown/other) cũng vượt biên. Ảnh hưởng mọi phiên phối đồ.

**Independent Test**: Thêm lần lượt một phụ kiện, một đôi giày, một món có vai trò không xác định vào canvas trống trên nhiều tỉ lệ màn hình khác nhau; xác nhận mỗi món nằm trọn trong khung canvas và vẫn kéo/scale được.

**Acceptance Scenarios**:

1. **Given** canvas trống trong Studio Thủ Công, **When** người dùng chạm thêm một món phụ kiện, **Then** món đó hiển thị trọn vẹn trong khung canvas (không tràn ra ngoài).
2. **Given** canvas trống, **When** người dùng chạm thêm một đôi giày, **Then** món giày hiển thị trọn vẹn trong khung canvas.
3. **Given** canvas đã có sẵn vài món, **When** người dùng thêm một món vai trò "khác"/phụ kiện, **Then** món mới không bị đặt ra ngoài vùng nhìn thấy.
4. **Given** cùng một món được thêm trên màn hình nhỏ và màn hình lớn, **When** món xuất hiện, **Then** trong cả hai trường hợp món đều nằm trọn trong canvas.

---

### User Story 2 - Danh mục "Áo khoác" + thao tác đóng/mở khay mượt mà (Priority: P1)

Trong khay tủ đồ của Studio Thủ Công, người dùng thấy một danh mục **"Áo khoác"** riêng để lọc nhanh áo khoác/outerwear. Việc kéo khay lên/xuống diễn ra mượt mà, không giật/khựng, và người dùng có thể **đóng khay bằng cách chạm vào mũi tên hạ xuống** trên thanh tiêu đề khay.

**Why this priority**: "Áo khoác" là danh mục thiếu so với nhu cầu phối đồ (tester báo rõ). Thao tác khay bị khựng và không đóng được bằng icon làm giảm trải nghiệm cốt lõi của Studio.

**Independent Test**: Mở Studio Thủ Công, xác nhận có chip "Áo khoác" và lọc đúng các món outerwear; kéo khay nhiều lần quan sát không giật; chạm mũi tên hạ xuống và xác nhận khay thu về trạng thái gọn.

**Acceptance Scenarios**:

1. **Given** khay tủ đồ đang mở, **When** người dùng chạm chip "Áo khoác", **Then** lưới chỉ hiển thị các món thuộc nhóm áo khoác/outerwear.
2. **Given** khay tủ đồ đang mở, **When** người dùng kéo khay xuống để thu gọn, **Then** thao tác mượt, không giật hay nhảy khung.
3. **Given** khay tủ đồ đang mở, **When** người dùng chạm vào icon mũi tên hạ xuống ở thanh tiêu đề, **Then** khay thu gọn về trạng thái thu gọn.

---

### User Story 3 - Nút "Xóa tất cả" trên thanh công cụ canvas (Priority: P2)

Trong Studio Thủ Công, ở thanh tuỳ chọn bên phải màn hình có nút **"Xóa tất cả"** để xoá toàn bộ các món đang nằm trên canvas trong một lần.

**Why this priority**: Tăng tốc thao tác làm lại bố cục; tester yêu cầu trực tiếp. Không chặn luồng chính nên ưu tiên thấp hơn P1.

**Independent Test**: Thêm vài món lên canvas, chạm "Xóa tất cả", xác nhận canvas trở về trạng thái trống.

**Acceptance Scenarios**:

1. **Given** canvas có nhiều món, **When** người dùng chạm "Xóa tất cả" và xác nhận, **Then** toàn bộ món bị gỡ khỏi canvas và canvas trống.
2. **Given** canvas đang trống, **When** người dùng xem thanh công cụ, **Then** nút "Xóa tất cả" không hiển thị hoặc không khả dụng.

---

### User Story 4 - Chat AI hiển thị đúng định dạng Markdown (Priority: P2)

Khi trò chuyện với Stylist AI, nội dung tin nhắn (đặc biệt là tin nhắn của AI) hiển thị đúng định dạng Markdown — in đậm, in nghiêng, tiêu đề, danh sách gạch đầu dòng/đánh số, liên kết, và mã — thay vì hiện các ký tự Markdown thô.

**Why this priority**: Lỗi hiển thị làm giảm chất lượng cảm nhận của tính năng chat; tester báo rõ. Không chặn luồng nhưng ảnh hưởng trực tiếp trải nghiệm.

**Independent Test**: Gửi một câu hỏi khiến AI trả lời có danh sách/đậm/nghiêng; xác nhận nội dung hiển thị đúng định dạng, không còn ký tự `*`, `#`, `-` thô trong câu trả lời định dạng.

**Acceptance Scenarios**:

1. **Given** AI trả về nội dung chứa cú pháp Markdown, **When** tin nhắn hiển thị, **Then** các định dạng (đậm/nghiêng/tiêu đề/danh sách/liên kết/mã) được render đúng.
2. **Given** AI đang stream câu trả lời từng phần, **When** nội dung dần xuất hiện, **Then** phần đã nhận vẫn hiển thị đúng định dạng và không nhấp nháy lỗi.
3. **Given** nội dung có cú pháp Markdown không hợp lệ hoặc văn bản thuần, **When** hiển thị, **Then** nội dung vẫn đọc được, không crash.

---

### User Story 5 - Gỡ ô "Demo" khi tạo tài khoản (Priority: P3)

Màn hình tạo tài khoản không còn hiển thị ô/ nút điền mẫu tự động "Demo"; người dùng chỉ nhập thông tin thật.

**Why this priority**: Yêu cầu dọn dẹp giao diện phát hành; rủi ro thấp, không ảnh hưởng luồng nên ưu tiên thấp.

**Independent Test**: Mở màn hình đăng ký, xác nhận không còn điều khiển điền mẫu tự động; form vẫn đăng ký bình thường.

**Acceptance Scenarios**:

1. **Given** người dùng mở màn hình "Tạo Tài Khoản", **When** màn hình hiển thị, **Then** không còn nút/ô "Điền mẫu tự động (Demo)".
2. **Given** ô demo đã gỡ, **When** người dùng nhập thông tin hợp lệ và tiếp tục, **Then** luồng đăng ký (gửi OTP) hoạt động như trước.

---

### User Story 6 - Gỡ nút "Phối đồ Studio" ở chi tiết món đồ (Priority: P3)

Khi người dùng mở màn hình xem chi tiết một món đồ trong tủ, không còn nút dẫn sang Studio; các thao tác còn lại (chỉnh sửa, xoá) giữ nguyên.

**Why this priority**: Dọn luồng điều hướng theo yêu cầu tester; ưu tiên thấp.

**Independent Test**: Mở chi tiết một món đồ, xác nhận không có nút "Phối đồ Studio"; nút "Chỉnh sửa" và "Xoá" vẫn hoạt động.

**Acceptance Scenarios**:

1. **Given** người dùng mở chi tiết món đồ, **When** thanh hành động dưới cùng hiển thị, **Then** không còn nút "Phối đồ Studio".
2. **Given** nút đã gỡ, **When** người dùng dùng các hành động còn lại, **Then** chúng hoạt động bình thường.

---

### User Story 7 - Đơn giản hoá tìm kiếm Community (Priority: P3)

Trong màn hình tìm kiếm của Community, hàng lọc phụ **"Tất cả bài / Bộ phối / Ảnh/Video"** được gỡ bỏ. Kết quả tìm kiếm trả về mọi loại bài viết mà không cần lọc theo loại.

**Why this priority**: Giảm rối giao diện theo yêu cầu tester; ưu tiên thấp.

**Independent Test**: Tìm kiếm trong Community, xác nhận không còn hàng chip lọc loại bài; danh sách bài viết vẫn hiển thị đầy đủ.

**Acceptance Scenarios**:

1. **Given** người dùng ở tab "Bài viết" trong tìm kiếm Community, **When** màn hình hiển thị, **Then** không còn hàng chip "Tất cả bài / Bộ phối / Ảnh/Video".
2. **Given** hàng chip đã gỡ, **When** người dùng tìm kiếm, **Then** kết quả gồm mọi loại bài viết (bộ phối, ảnh/video).

---

### Edge Cases

- Thêm món có **vai trò không xác định** hoặc danh mục trống → vẫn phải nằm trọn trong canvas.
- Thêm nhiều món cùng loại liên tiếp (nhiều phụ kiện) → không **chồng lấn hoàn toàn** và không tràn biên (cho phép chồng một phần khi canvas nhỏ — đã chấp nhận ở plan §Rủi ro).
- Canvas có kích thước rất nhỏ (màn hình hẹp) hoặc rất lớn → bố cục vẫn không tràn.
- Kéo khay nhanh qua lại quanh ngưỡng mở/đóng → không nhấp nháy trạng thái, không giật.
- "Xóa tất cả" khi canvas trống → không gây lỗi, không hiện xác nhận vô nghĩa.
- Tin nhắn Markdown đang stream dở (còn cú pháp chưa đóng) → không crash, hiển thị hợp lý.
- Tin nhắn AI rất dài / nhiều danh sách → cuộn và bố cục vẫn ổn.
- Sau khi gỡ nút Studio ở chi tiết món, không còn liên kết/route mồ côi trỏ tới Studio từ màn này.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Khi người dùng thêm một món đồ từ khay vào canvas trong Studio Thủ Công, hệ thống MUST đặt món đó nằm **trọn trong biên canvas** ngay lần đặt đầu tiên, áp dụng cho mọi vai trò (top, bottom, fullbody, outerwear, footwear, headwear, accessory, other, unknown).
- **FR-002**: Vị trí đặt món trên canvas MUST được tính theo **kích thước canvas thực tế đo được**, không dùng toạ độ cố định giả định cho một tỉ lệ màn hình.
- **FR-003**: Khi món vượt biên canvas, hệ thống MUST áp dụng phương án kết hợp: (a) khi **thêm một món đơn lẻ** khiến món vượt biên, kẹp (clamp) vị trí món vào trong biên canvas và giữ nguyên kích thước; nếu bản thân món lớn hơn vùng khả dụng thì giảm `scale` vừa khung trước khi kẹp (khớp INV-1); (b) khi **thêm nhiều món hoặc nạp set** làm cụm vượt khung, tự canh toàn cụm vừa khung (fit-to-canvas) mà không để món nào tràn biên.
- **FR-004**: Danh sách vai trò món đồ trên canvas MUST bao gồm `outerwear` (áo khoác) và được chuẩn hoá từ slug/tên danh mục tương ứng; khay tủ đồ trong Studio Thủ Công MUST có một danh mục lọc riêng **"Áo khoác"** hiển thị đúng các món thuộc nhóm áo khoác/outerwear. Chip **"Áo"** MUST chỉ gồm áo thân trên (loại trừ áo khoác) để mỗi món chỉ thuộc đúng một danh mục lọc.
- **FR-005**: Thao tác kéo/đóng/mở khay tủ đồ MUST mượt mà, không giật khung trong lúc kéo.
- **FR-006**: Người dùng MUST có thể thu gọn khay tủ đồ bằng cách chạm vào **icon mũi tên hạ xuống** trên thanh tiêu đề khay.
- **FR-007**: Thanh tuỳ chọn bên phải canvas trong Studio Thủ Công MUST có nút **"Xóa tất cả"** để xoá toàn bộ các món trên canvas.
- **FR-008**: Nút "Xóa tất cả" chỉ MUST hiển thị/khả dụng khi canvas có ít nhất một món; khi có món, thao tác xoá MUST được xác nhận trước khi thực hiện.
- **FR-009**: Nội dung tin nhắn trong chat Stylist AI MUST render định dạng Markdown (đậm, nghiêng, tiêu đề, danh sách, liên kết, mã) thay vì hiển thị ký tự Markdown thô; áp dụng cả khi đang stream.
- **FR-010**: Màn hình tạo tài khoản MUST KHÔNG hiển thị điều khiển điền mẫu tự động ("Demo") và MUST không còn khả năng tự điền dữ liệu mẫu.
- **FR-011**: Màn hình chi tiết món đồ trong tủ MUST KHÔNG hiển thị nút "Phối đồ Studio"; các hành động còn lại (chỉnh sửa, xoá, phân tích lại) MUST giữ nguyên.
- **FR-012**: Màn hình tìm kiếm Community MUST KHÔNG hiển thị hàng lọc loại bài "Tất cả bài / Bộ phối / Ảnh/Video"; kết quả tìm kiếm bài viết MUST gồm mọi loại bài viết.

### Key Entities

- **Món đồ trên canvas (CanvasItem)**: món đang nằm trên canvas Studio; thuộc tính gồm vai trò, vị trí, tỉ lệ kích thước, thứ tự lớp, và khung bao — dùng để quyết định đặt món trong biên canvas.
- **Danh mục trang phục (Category)**: tên và slug dùng để phân loại món (bao gồm nhóm áo khoác/outerwear) và để lọc trong khay tủ đồ.
- **Tin nhắn chat (Chat message)**: nội dung văn bản Markdown của người dùng/AI trong phiên Stylist.
- **Bài viết cộng đồng (Community post)**: có loại (bộ phối / ảnh-video) — dùng cho kết quả tìm kiếm.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% món đồ (đặc biệt phụ kiện, giày, món "khác") được thêm vào canvas nằm trọn trong biên canvas ngay lần đặt đầu tiên, trên tối thiểu 3 kích thước/ tỉ lệ màn hình khác nhau.
- **SC-002**: Kéo khay tủ đồ lên/xuống không còn hiện tượng khựng/giật thấy rõ; phương pháp kiểm chứng: **QS thủ công trên thiết bị Android tầm trung** — kéo liên tục không nhảy/đứng khung (repo chưa có harness đo FPS tự động).
- **SC-003**: Người dùng đóng được khay bằng **một** thao tác chạm vào icon mũi tên hạ xuống.
- **SC-004**: Xoá toàn bộ món trên canvas hoàn tất bằng một nút "Xóa tất cả" (có xác nhận), canvas trống ngay sau đó.
- **SC-005**: 0 ký tự Markdown thô (`*`, `#`, `-`, `` ` ``) lộ ra trong các câu trả lời AI có định dạng khi kiểm thử mẫu.
- **SC-006**: Màn hình đăng ký không còn bất kỳ điều khiển "Demo" nào.
- **SC-007**: Màn hình chi tiết món đồ không còn lối vào Studio.
- **SC-008**: Màn hình tìm kiếm Community không còn hàng lọc loại bài; tìm kiếm vẫn trả kết quả đầy đủ.

## Assumptions

- **"Áo khoác"** = nhóm `outerwear`; chip **"Áo"** loại trừ áo khoác (đã chốt ở Clarifications 2026-10-13, mỗi món thuộc đúng một danh mục lọc).
- Nguồn lỗi tràn biên ở Studio Thủ Công là do món được đặt theo toạ độ chuẩn hoá cố định (không theo kích thước canvas đo được). Bản sửa tập trung ở luồng **thêm món thủ công**; các luồng nạp set AI/khôi phục outfit đã có canh khung.
- Render Markdown trong chat cần thêm một thành phần/ thư viện render phù hợp (quyết định cụ thể ở bước plan). Không thay đổi nguồn nội dung văn bản từ máy chủ.
- Gỡ ô "Demo" chỉ xoá điều khiển điền mẫu ở màn đăng ký; không ảnh hưởng API đăng ký.
- Gỡ nút "Phối đồ Studio" ở chi tiết món không xoá route `/studio` (vẫn dùng từ các lối vào khác như tab Phối đồ AI).
- Gỡ hàng lọc loại bài ở tìm kiếm Community là thay đổi phía giao diện; máy chủ vẫn có thể hỗ trợ lọc nhưng app không gửi bộ lọc loại bài nữa.
- Tester dùng tài khoản thử (`user / 123456`) và môi trường BE local; nền tảng kiểm thử chính là mobile + web.
