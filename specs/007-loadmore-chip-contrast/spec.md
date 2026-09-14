# Feature Specification: Loadmore Chip Contrast

**Feature Branch**: `007-loadmore-chip-contrast`

**Created**: 2026-09-14

**Status**: Draft

**Input**: User description: "tạo plan fix những mô tả lỗi hiện tại, 1. chưa fix được khi scroll hết 20 item thì load tiếp các item mới ở trang tiếp theo ở trang wardrobe item và outfits list, 2. ở phần search chọn các buttom tất cả, áo,... trang wardrobe icon click đổi thành màu trắng cho chung với màu chữ"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Kéo hết danh sách thực sự tải tiếp trang sau (Priority: P1)

Người dùng có hơn 20 món trong tủ (hoặc hơn 50 outfit) kéo xuống cuối danh sách thì các món/outfit của trang tiếp theo thực sự hiện ra nối tiếp. Lần sửa trước (006) đã thêm cơ chế tải thêm nhưng khi test vẫn đứng yên ở 20 món — lần này phải chẩn đoán đúng nguyên nhân (tham số trang không được tôn trọng, tổng số sai, hay dữ liệu trùng) và sửa tận gốc cả hai danh sách Wardrobe và Outfit.

**Why this priority**: Đây là bug tái phát sau 1 lần fix — người dùng tủ đông vẫn không xem được đồ cũ, tưởng mất đồ. Ưu tiên cao nhất.

**Independent Test**: Có thể kiểm thử độc lập bằng tài khoản 35 món + 60 outfit: kéo tới cuối trang đầu → món/outfit mới hiện ra thật (đếm số lượng tăng), kéo tiếp tới hết thì dừng.

**Acceptance Scenarios**:

1. **Given** người dùng có 35 món đang xem 20 món đầu, **When** kéo tới gần cuối, **Then** 15 món còn lại hiện ra nối tiếp trong vòng 5 giây (mạng ổn định), tổng đếm thành 35.
2. **Given** trang tiếp theo trả về trùng toàn bộ món đã có, **When** hoàn tất tải, **Then** app tự thử trang kế tiếp 1 lần hoặc kết luận đã hết — không đứng yên ở 20 món, không quay spinner mãi.
3. **Given** tổng số hệ thống báo sai (nhỏ hơn thực tế), **When** kéo tới cuối mà vẫn còn món mới, **Then** app tiếp tục tải theo dữ liệu thực tế thay vì dừng theo tổng số sai.
4. **Given** danh sách Outfit có 60 bộ, **When** kéo tới cuối trang đầu (50 bộ), **Then** 10 bộ còn lại hiện ra nối tiếp.

---

### User Story 2 - Chip lọc đang chọn hiện icon trắng cùng màu chữ (Priority: P2)

Người dùng nhấn chọn chip lọc danh mục ở trang Wardrobe (Tất cả, Áo, Quần...) thì cả chữ và icon (dấu tick/biểu tượng của chip) đều hiện màu trắng trên nền đậm, dễ nhìn và đồng nhất. Chip chưa chọn giữ chữ + icon màu chủ đạo trên nền nhạt như cũ.

**Why this priority**: Lỗi tương phản nhỏ nhưng đập vào mắt mỗi lần lọc; sửa nhanh, độc lập với US1.

**Independent Test**: Có thể kiểm thử độc lập bằng cách nhấn từng chip lọc và quan sát màu chữ + icon ở cả 2 trạng thái chọn/chưa chọn.

**Acceptance Scenarios**:

1. **Given** người dùng đang ở trang Wardrobe, **When** nhấn chọn chip "Áo", **Then** chip nền đậm, chữ trắng và icon trắng.
2. **Given** chip đang được chọn, **When** nhìn ở chế độ sáng/tối của máy, **Then** chữ và icon vẫn đọc rõ, không bị chìm vào nền.
3. **Given** người dùng bỏ chọn (chọn chip khác), **When** chip cũ về trạng thái chưa chọn, **Then** chữ và icon về màu chủ đạo trên nền nhạt.

---

### Edge Cases

- Trang tiếp theo rỗng nhưng tổng số vẫn còn — app kết luận đã hết sau tối đa 1 lần thử thêm, không lặp vô hạn.
- Tham số trang bị hệ thống bỏ qua (mọi trang trả về cùng 20 món) — app phát hiện toàn trùng, dừng lại và báo đã hiển thị hết món có thể, không quay spinner.
- Mất mạng đúng lúc tải thêm — giữ list + vị trí cuộn, báo nhẹ, kéo tiếp thử lại được (giữ nguyên từ 006).
- Chip danh mục tên dài — chữ/icon không tràn, chip không vỡ layout khi đổi màu.
- Danh mục chỉ có đúng 1 trang — không hiện chỉ báo tải thêm, chip lọc vẫn đổi màu đúng.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Khi kéo tới gần cuối danh sách Wardrobe/Outfit mà còn món chưa hiện, hệ thống MUST tải và hiển thị tiếp món của trang sau (số lượng trên màn hình tăng thật).
- **FR-002**: Trước khi sửa, hệ thống MUST được chẩn đoán đúng nguyên nhân (tham số trang, tổng số, hay dữ liệu trùng) bằng log mạng và sửa đúng chỗ — không sửa mò.
- **FR-003**: Nếu trang sau trả về toàn món trùng, hệ thống MUST tự thử tối đa 1 trang kế tiếp; vẫn trùng thì kết luận đã hết và dừng, không quay chỉ báo tải mãi.
- **FR-004**: Nếu tổng số hệ thống báo nhỏ hơn số món thực tế tải được, hệ thống MUST tiếp tục tải theo dữ liệu thực tế thay vì dừng sớm.
- **FR-005**: Sau lần sửa này, tài khoản 35 món MUST xem đủ 35 món và tài khoản 60 outfit MUST xem đủ 60 outfit chỉ bằng thao tác kéo.
- **FR-006**: Chip lọc danh mục đang chọn MUST hiển thị chữ trắng và icon trắng trên nền đậm; chip chưa chọn MUST hiển thị chữ và icon màu chủ đạo trên nền nhạt.
- **FR-007**: Màu icon/chữ của chip MUST đọc rõ ở cả chế độ sáng và tối của thiết bị.
- **FR-008**: Các bảo vệ đã có từ lần trước (1 request tại 1 thời điểm, dedupe id, reset khi đổi filter, giữ tick chọn) MUST tiếp tục đúng sau lần sửa này.

### Key Entities

- **Trang danh sách (List Page)**: Một đợt món/outfit tải về theo tham số trang — đúng trang thì món mới, sai trang thì trùng/rỗng; là trọng tâm chẩn đoán.
- **Chip lọc (Filter Chip)**: Nút chọn danh mục — gồm nhãn chữ và icon, có 2 trạng thái chọn (nền đậm/chữ-icon trắng) và chưa chọn (nền nhạt/màu chủ đạo).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 10/10 lượt kéo trên tài khoản 35 món đều hiển thị đủ 35 món (đếm số card trên màn hình), thời gian mỗi lần tải thêm dưới 5 giây.
- **SC-002**: 10/10 lượt kéo trên tài khoản 60 outfit đều hiển thị đủ 60 bộ.
- **SC-003**: 0 lần quay spinner vô hạn trong 20 lượt test (kể cả khi dữ liệu trang sau trùng/rỗng).
- **SC-004**: 5/5 chip lọc kiểm tra đều có chữ + icon trắng khi chọn, màu chủ đạo khi chưa chọn, đọc rõ ở cả sáng/tối.
- **SC-005**: Không hồi quy: các tiêu chí SC-002→SC-006 của spec 006 vẫn đạt sau lần sửa này.

## Assumptions

- Lần sửa 006 đã đúng cấu trúc (trigger ngưỡng 400px, guard song song, dedupe, reset filter) — còn lại là lỗi runtime (tham số/tổng/dữ liệu), nên trọng tâm là chẩn đoán bằng log mạng trên thiết bị test.
- Tham số phân trang và tổng số do cùng hệ thống với web FE cung cấp; nếu hệ thống sai thì sửa phía dùng (mobile) trước, ghi nhận yêu cầu hệ thống nếu cần.
- Icon của chip là dấu tick/biểu tượng mặc định của chip lọc; nếu thiết kế chip không có icon thì "icon" hiểu là mọi ký hiệu đi kèm nhãn và yêu cầu trắng khi chọn vẫn giữ.
- Tài khoản test có trên 20 món và trên 50 outfit như lần trước.
