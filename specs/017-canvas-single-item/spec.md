# Feature Specification: Canvas một món mỗi loại + sửa áo khoác đè áo

**Feature Branch**: `017-canvas-single-item`

**Created**: 2026-10-13

**Status**: Draft

**Input**: User description: "tôi muốn trong canvas chỉ có 1 loại item tại 1 thời điểm — vd chỉ có 1 áo hoặc 1 quần, nếu chọn áo hoặc quần khác sẽ tự thay thế cho cái hiện tại đang trên canvas. Áo khoác đang đè lên áo lúc thêm vào canvas, kiểm tra và fix"

## Clarifications

### Session 2026-10-13

- Q: Phạm vi "mỗi loại một món" gồm những vai trò nào? → A: Chỉ nhóm quần áo cơ bản độc quyền (áo trên, quần, đầm liền thân, áo khoác, giày dép); mũ và phụ kiện được phép nhiều món.
- Q: Đầm liền thân quan hệ với áo + quần thế nào? → A: Đầm chỉ thay áo (gỡ áo, giữ quần); thêm áo thì gỡ đầm; quần độc lập, được phối cùng đầm.
- Q: Áo khoác và áo cùng trên canvas hiển thị ra sao? → A: Giữ áo khoác ở lớp trên nhưng dịch sang bên để lộ áo.
- Q: Vị trí món mới khi thay thế món cùng loại? → A: **Thay tại chỗ** — món mới giữ đúng vị trí và kích thước món cũ (bản chỉnh 2026-10-13; trước đó đặt theo vị trí chuẩn).
- Q: Áo khoác không được che những lớp nào bên dưới? → A: Mọi lớp nền bên dưới (áo trên **hoặc** đầm liền thân).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Mỗi loại trang phục chỉ có một món trên canvas (Priority: P1)

Người dùng dàn đồ trong **Studio Thủ Công**. Khi canvas đã có một món thuộc một loại (ví dụ một áo), nếu người dùng thêm một món khác cùng loại (một áo khác), món mới **thay thế** món cũ — canvas vẫn chỉ có đúng một áo, không bị nhân đôi.

**Why this priority**: Tránh chồng nhiều áo/quần lên nhau khiến bố cục rối và sai ngữ nghĩa phối đồ. Đây là hành vi cốt lõi của bàn phối.

**Independent Test**: Thêm một áo, rồi thêm một áo khác; kiểm tra canvas chỉ còn đúng một món loại áo và đó là món vừa thêm.

**Acceptance Scenarios**:

1. **Given** canvas đã có một áo, **When** người dùng thêm một áo khác, **Then** áo cũ bị thay bằng áo mới, canvas vẫn chỉ có một áo.
2. **Given** canvas đã có một quần, **When** người dùng thêm một quần khác, **Then** quần cũ bị thay bằng quần mới.
3. **Given** canvas đã có nhiều loại khác nhau (áo + quần + giày), **When** người dùng thêm một áo mới, **Then** chỉ áo bị thay; quần và giày giữ nguyên.
4. **Given** canvas đã có một áo, **When** người dùng thêm một món loại khác (ví dụ giày), **Then** áo được giữ nguyên và giày được thêm vào.

---

### User Story 2 - Áo khoác không đè lên lớp nền khi thêm vào canvas (Priority: P1)

Khi người dùng thêm **áo khoác** lên canvas đang có **lớp nền** (áo trên hoặc đầm liền thân), áo khoác hiện đang **đè lên (che)** lớp nền. Cần sửa để áo khoác và lớp nền cùng hiển thị hợp lý, không che mất nhau.

**Why this priority**: Lỗi hiển thị rõ ràng làm hỏng bố cục phối đồ; tester báo trực tiếp.

**Independent Test**: Thêm một áo rồi thêm một áo khoác; kiểm tra hai món không chồng che nhau. Lặp lại với đầm.

**Acceptance Scenarios**:

1. **Given** canvas có một áo, **When** người dùng thêm một áo khoác, **Then** áo khoác không che khuất áo (cả hai nhìn thấy được).
2. **Given** canvas có áo khoác rồi thêm áo, **When** áo được thêm, **Then** bố cục vẫn không chồng che bất thường.
3. **Given** canvas có một đầm liền thân, **When** người dùng thêm một áo khoác, **Then** áo khoác không che khuất đầm.

---

### User Story 3 - Thay thế giữ nguyên trải nghiệm dàn đồ (Priority: P2)

Khi một món bị thay thế, người dùng vẫn thấy thao tác liền mạch: món mới ở đúng vị trí hợp lý trong khung, được chọn sẵn để chỉnh, và canvas thông báo rõ món đã được thay.

**Why this priority**: Đảm bảo việc thay thế không gây nhảy bố cục khó hiểu hay mất món ngoài ý muốn.

**Independent Test**: Thêm áo A, thêm áo B; xác nhận B ở vị trí hợp lý, đang được chọn, và A đã bị gỡ.

**Acceptance Scenarios**:

1. **Given** canvas có áo A, **When** thêm áo B thay thế, **Then** B nằm trọn trong khung, đang được chọn, A không còn.
2. **Given** việc thay thế xảy ra, **When** hoàn tất, **Then** người dùng nhận phản hồi rõ ràng (ví dụ thông báo) rằng món đã được thay.

---

### Edge Cases

- Thêm món cùng loại khi món cũ đang được chọn → món mới thay thế và trở thành món đang chọn.
- Canvas đang **trống** → thêm món bình thường (không có gì để thay).
- Loại có nhiều món cùng tồn tại hợp lệ (ví dụ phụ kiện) → xử lý theo kết luận phạm vi role (xem FR-001).
- Thêm đầm (liền thân) khi canvas đang có áo + quần → gỡ áo, **giữ quần**; thêm áo khi đang có đầm → gỡ đầm.
- Thêm món có vai trò không xác định → không được gây lỗi hay xóa nhầm món khác.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Trên canvas, tại một thời điểm hệ thống MUST giữ tối đa **một** món cho mỗi loại trong **nhóm quần áo cơ bản**: áo trên (top), quần (bottom), đầm liền thân (fullbody), áo khoác (outerwear), giày dép (footwear). Các vai trò còn lại (**mũ, phụ kiện, khác, không xác định**) ĐƯỢC PHÉP có nhiều món cùng lúc.
- **FR-002**: Khi người dùng thêm một món mà canvas đã có món **cùng loại** (trong nhóm quần áo cơ bản), hệ thống MUST thay thế món cũ bằng món mới (gỡ món cũ), không thêm chồng.
- **FR-003**: Việc thay thế MUST đặt món mới **tại đúng vị trí và kích thước của món cũ** (thay tại chỗ); món mới được kẹp trong khung canvas và ở trạng thái đang được chọn. (Bản chỉnh 2026-10-13: trước đó đặt theo vị trí chuẩn.)
- **FR-004**: Đầm liền thân (fullbody) và áo trên (top) loại trừ nhau: thêm đầm khi canvas có áo → gỡ áo (giữ quần nếu có); thêm áo khi canvas có đầm → gỡ đầm. Quần (bottom) **độc lập**, được phép tồn tại cùng đầm.
- **FR-005**: Khi áo khoác cùng canvas với **lớp nền** (áo trên **hoặc** đầm), hệ thống MUST đặt áo khoác **rộng bằng lớp nền**, **ngang hàng (cùng mức dọc) với lớp nền**, chồng lên lớp nền một phần nhưng **không quá 40%** bề rộng lớp nền, và ở **phía đối diện phụ kiện** (khi có phụ kiện). Lớp nền giữ làm cột giữa (không dời). Trên khung hẹp, cả hai thu cùng tỉ lệ để vẫn thoả ≤ 40%.
- **FR-009**: Cột giữa (áo/quần/đầm/nón/giày) MUST căn giữa và là cột mốc; **phụ kiện** MUST nép **sát** cột giữa (cách một khoảng nhỏ) ở **phía đối diện áo khoác** và **không đè** lên cột hay món khác.
- **FR-010**: Toàn bộ khối trang phục trên canvas MUST được **căn giữa bề ngang** (bbox ngang trùng tâm canvas) để khối không lệch sang một bên khi có áo khoác/phụ kiện.
- **FR-006**: Thêm món khi canvas trống MUST hoạt động như hiện tại (không có gì bị thay).
- **FR-007**: Thao tác thay thế MUST kèm phản hồi rõ ràng cho người dùng rằng món đã bị thay thế.
- **FR-008**: Món bị thay thế MUST không còn trong **dữ liệu lưu**: khi lưu bộ phối, danh sách món gửi đi KHÔNG chứa món đã bị gỡ (không lưu món "mồ côi").

### Key Entities *(include if feature involves data)*

- **Món trên canvas (CanvasItem)**: món đang nằm trên canvas; có **vai trò** (áo trên, quần, đầm liền thân, áo khoác, giày dép, mũ, phụ kiện, khác/không xác định), vị trí, tỉ lệ, và thứ tự lớp. Vai trò quyết định "loại" dùng để thay thế.
- **Danh mục trang phục (Category)**: tên/slug dùng để suy ra vai trò của món khi thêm vào canvas.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% trường hợp thêm món trùng loại vào canvas đều **thay thế** món cũ, canvas không bao giờ có hai món cùng loại (theo phạm vi FR-001).
- **SC-002**: Áo khoác **rộng bằng áo, ngang hàng với áo**, chồng lên áo **≤ 40%**; áo khoác ở **phía đối diện phụ kiện**; lớp nền không bị dời (theo INV-6).
- **SC-003**: Sau khi thay thế, món mới nằm trọn trong khung canvas (100% trường hợp).
- **SC-004**: Thêm món vào canvas trống không bị ảnh hưởng (không có món nào bị gỡ nhầm).
- **SC-005**: Phụ kiện nép **sát** cột giữa (khoảng cách nhỏ) và **không chồng** lên cột (theo INV-7).

## Assumptions

- "Loại" của món được xác định theo **vai trò** đã có sẵn trong hệ thống Studio (top/quần/đầm/áo khoác/giày/mũ/phụ kiện/khác), không tạo khái niệm loại mới.
- Việc thay thế áp dụng cho thao tác **thêm món thủ công**; luồng nạp set AI và khôi phục outfit đã có quy tắc khử trùng lặp riêng và không bị đổi hành vi ngoài phạm vi đã nêu.
- Đã chốt (Clarifications 2026-10-13): nhóm quần áo cơ bản một món mỗi loại; **mũ và phụ kiện được phép nhiều món**; đầm chỉ thay áo (được phối cùng quần); áo khoác giữ lớp trên nhưng dịch sang bên để lộ áo.
- Thay thế gỡ món cũ hoàn toàn; người dùng có thể thêm lại nếu muốn.
- Nhóm đồ chính (áo/quần/đầm/nón/giày) được phóng to khoảng 1.5×; giày/nón/phụ kiện vẫn nhỏ hơn đồ chính để tiết kiệm diện tích. Bản chỉnh 2026-10-13 (lần 5): áo `168`, quần `168`, đầm `177`, nón `114`, giày `120`, phụ kiện `74`, món "khác" `56`; khoảng cách giày–quần tăng ~10px; **toàn bộ khối căn giữa bề ngang canvas**; áo khoác **ngang hàng** áo, chồng ≤40%; phụ kiện nép sát cột ở phía đối diện áo khoác.
