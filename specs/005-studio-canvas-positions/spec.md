# Feature Specification: Studio Canvas Positions

**Feature Branch**: `005-studio-canvas-positions`

**Created**: 2026-09-14

**Status**: Draft

**Input**: User description: "tiếp theo đến với phần chỉnh sửa trang outfit studio (nền canvas studio thủ công): mô tả lỗi khi còn 1 bộ outfit hoặc do AI gợi ý ra thì các item xuất hiện trên nền canvas đang nằm ở vị trí lộn xộn hoặc chồng lên nhau, nằm ở ngoài vị trí hiển thị lên phương án điều chỉnh trong respone BE có trả ra 1 trường vị trí của item bạn hãy dựa vào đó để hiện thị vị trí phù hợp cho các item trên nền canvas"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Set đồ AI gợi ý hiện đúng vị trí từng món (Priority: P1)

Người dùng nhờ AI gợi ý set đồ, rồi nạp set đó lên nền canvas thủ công của Outfit Studio để tinh chỉnh. Mỗi món xuất hiện đúng vị trí theo vai trò của nó (áo ở trên, quần ở dưới, giày ở dưới cùng, phụ kiện bên cạnh...), không món nào chồng lên nhau, không món nào nằm ngoài khung nhìn.

**Why this priority**: Đây là luồng AI → Studio dùng nhiều nhất sau khi có gợi ý. Món đồ chồng đống ở giữa canvas khiến người dùng phải kéo tay từng món, triệt tiêu giá trị của gợi ý AI.

**Independent Test**: Có thể kiểm thử độc lập bằng cách xin 1 gợi ý AI (vd top + bottom + footwear) → nạp lên canvas → chụp màn hình xác nhận 3 món tách rời, đúng tầng trên-dưới-giày, nằm gọn trong khung nhìn.

**Acceptance Scenarios**:

1. **Given** AI trả về set đồ có các vai trò quen thuộc (áo, quần, giày), **When** người dùng nạp set lên canvas, **Then** áo nằm nửa trên, quần nằm giữa-dưới, giày nằm dưới cùng, không chồng lấn nhau.
2. **Given** AI trả về set có vai trò ít gặp (áo khoác, mũ, phụ kiện), **When** nạp lên canvas, **Then** mỗi món vẫn có vị trí riêng hợp lý (áo khoác cạnh/trên áo, mũ ở góc trên, phụ kiện bên cạnh), không bị dồn về chính giữa.
3. **Given** AI trả về món không có vai trò rõ ràng, **When** nạp lên canvas, **Then** món đó được xếp vào ô trống không đè lên món khác, vẫn nằm trong khung nhìn.

---

### User Story 2 - Mở outfit đã lưu lên canvas giữ đúng bố cục (Priority: P1)

Người dùng mở một bộ outfit đã lưu ("Mở Trên Studio") để chỉnh sửa tiếp. Các món hiện lên đúng vị trí đã lưu trước đó (kèm theo dữ liệu vị trí từng món do hệ thống lưu), toàn bộ nằm gọn trong khung nhìn, có thể kéo tay tinh chỉnh và lưu lại giữ nguyên bố cục mới.

**Why this priority**: Người dùng lưu outfit kỳ vọng mở lại thấy đúng bản đã dàn. Bố cục vỡ (chồng nhau / văng ngoài khung) làm mất niềm tin vào tính năng lưu, quan trọng ngang luồng AI.

**Independent Test**: Có thể kiểm thử độc lập bằng cách lưu 1 outfit đã dàn tay → thoát → mở lại bằng "Mở Trên Studio" → so sánh bố cục trước/sau trùng khớp.

**Acceptance Scenarios**:

1. **Given** outfit đã lưu có vị trí từng món, **When** mở lên canvas, **Then** mỗi món nằm đúng vị trí đã lưu, thứ tự lớp (món nào trên/dưới) giữ nguyên.
2. **Given** mở outfit chỉ còn 1 món, **When** hiện lên canvas, **Then** món đó nằm ở vị trí dễ thấy giữa khung nhìn, không bị kẹt ở mép hay ngoài khung.
3. **Given** mở outfit trên thiết bị có kích thước màn hình khác lúc lưu, **When** hiện lên canvas, **Then** toàn bộ món vẫn nằm gọn trong khung nhìn, bố cục tương đối giữ nguyên (trên-dưới-trái-phải).
4. **Given** người dùng kéo tay đổi vị trí rồi lưu, **When** mở lại outfit đó, **Then** bố cục mới được giữ nguyên.

---

### Edge Cases

- Set AI có 2 món cùng vai trò (vd 2 phụ kiện) — món thứ hai tự lệch sang ô bên cạnh, không đè lên món đầu.
- Outfit đã lưu từ trước khi có dữ liệu vị trí (mọi món đều ở gốc tọa độ) — app tự dàn lại theo vai trò thay vì chồng đống ở giữa.
- Vị trí đã lưu nằm ngoài khung nhìn hiện tại (do lưu trên màn hình khác) — app kéo món vào trong khung với lề an toàn, giữ nguyên thứ tự tương đối.
- Canvas đang phóng to/thu nhỏ khi nạp set mới — bố cục nạp vào vẫn đúng, mức zoom hiện tại không làm lệch vị trí.
- Nạp set mới khi canvas đang có đồ dở — app hỏi rõ ghi đè hay giữ lại trước khi thay bố cục.
- Ảnh món đồ tải chậm/lỗi — ô giữ chỗ vẫn chiếm đúng vị trí để bố cục không vỡ khi ảnh về.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Khi nạp set AI lên canvas, hệ thống MUST đặt mỗi món theo đúng vai trò do hệ thống trả về (áo, quần, váy liền, áo khoác, giày, mũ, phụ kiện) — mỗi vai trò có một vùng vị trí riêng không trùng nhau.
- **FR-002**: Vai trò lạ hoặc thiếu vai trò MUST NOT dồn món về cùng một điểm; hệ thống MUST xếp món vào ô trống còn lại trong khung nhìn.
- **FR-003**: Khi mở outfit đã lưu, hệ thống MUST đặt mỗi món đúng vị trí đã lưu kèm theo (tọa độ + tỉ lệ + thứ tự lớp của từng món).
- **FR-004**: Mọi món sau khi nạp/mở MUST nằm gọn trong khung nhìn của canvas với lề an toàn; món nào vượt biên MUST được kéo vào trong mà vẫn giữ thứ tự tương đối với các món khác.
- **FR-005**: Hai món chồng lấn nhau sau khi nạp/mở MUST được tách ra với khoảng cách tối thiểu nhìn rõ được, ưu tiên giữ nguyên món đã đúng vị trí và chỉ dịch món bị đè.
- **FR-006**: Người dùng MUST vẫn kéo tay di chuyển, phóng to/thu nhỏ, đổi lớp từng món sau khi tự động dàn; thao tác tay MUST được ưu tiên và không bị tự động dàn lại đè lên.
- **FR-007**: Khi lưu outfit, hệ thống MUST lưu đúng vị trí/tỉ lệ/thứ tự lớp cuối cùng trên canvas để lần mở sau hiển thị trùng khớp.
- **FR-008**: Outfit chỉ có 1 món MUST hiển thị món đó ở vùng trung tâm dễ thấy của khung nhìn.
- **FR-009**: Trước khi thay thế đồ đang dở trên canvas bằng set mới, hệ thống MUST hỏi xác nhận ghi đè của người dùng.

### Key Entities

- **Món trên canvas (Canvas Item)**: Món đồ đang dàn trên nền thủ công — gồm ảnh, vai trò (áo/quần/giày...), tọa độ, tỉ lệ, thứ tự lớp.
- **Gợi ý AI (AI Suggestion)**: Set đồ do hệ thống gợi ý — gồm tiêu đề, giải thích, danh sách nhóm theo vai trò (mỗi nhóm có món chính + món thay thế).
- **Outfit đã lưu (Saved Outfit)**: Bộ đồ người dùng đã lưu — gồm tên, ảnh bìa, danh sách món kèm tọa độ/tỉ lệ/thứ tự lớp đã lưu.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% lần nạp set AI đủ 3 vai trò cơ bản (20/20 lượt test) hiển thị 3 món tách rời, đúng tầng trên-dưới-giày trong khung nhìn, không cần kéo tay sửa.
- **SC-002**: 100% lần nạp set có áo khoác/mũ/phụ kiện (10/10 lượt) không còn món nào bị dồn về chính giữa đè lên nhau.
- **SC-003**: 100% lần mở lại outfit vừa lưu (15/15 lượt, gồm cả outfit 1 món) bố cục trùng khớp lúc lưu, toàn bộ món nằm trong khung nhìn.
- **SC-004**: Mở outfit đã lưu trên thiết bị khác kích thước màn hình: 95% số món (19/20) nằm gọn trong khung nhìn mà không cần kéo tay.
- **SC-005**: Thời gian người dùng phải kéo tay dàn lại sau khi nạp/mở giảm từ trung bình trên 60 giây xuống dưới 10 giây (đo 10 lượt test).
- **SC-006**: Không hồi quy: kéo tay, đổi lớp, lưu outfit và mở "Mở Trên Studio" hiện tại vẫn thành công 100% trong 20 lượt test liên tiếp.

## Assumptions

- Hệ thống trả về vai trò mặc đồ chuẩn cho gợi ý AI gồm: áo, quần, váy liền, áo khoác, giày, mũ, phụ kiện; vai trò ngoài danh sách này được coi là vai trò lạ và dùng ô dự phòng.
- Outfit đã lưu mang theo tọa độ, tỉ lệ và thứ tự lớp từng món; món thiếu dữ liệu được coi như ở gốc tọa độ và sẽ tự dàn lại.
- Tọa độ món là độ lệch tương đối so với tâm canvas; kích thước canvas khác nhau giữa các thiết bị nên cần co giãn/kẹp biên khi hiển thị.
- Nền canvas thủ công và thao tác kéo tay hiện tại giữ nguyên; phạm vi spec chỉ sửa cách đặt vị trí ban đầu khi nạp/mở, không đổi trình chỉnh sửa.
- Người dùng test trên thiết bị/emulator thấy được toàn bộ canvas trong một màn hình.
