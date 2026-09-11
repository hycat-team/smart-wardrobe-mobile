# Feature Specification: User Outfits Tab

**Feature Branch**: `002-user-outfits-tab`

**Created**: 2026-09-11

**Status**: Draft

**Input**: User description: "tạo thêm 1 trang hiện thị list outfits của user và thêm icon direct ở giữa stylist và profile"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Xem danh sách outfits từ tab giữa (Priority: P1)

Người dùng đã đăng nhập bấm icon Outfits trên thanh điều hướng dưới (nằm giữa Stylist và Profile) và thấy toàn bộ bộ trang phục đã lưu của mình dưới dạng lưới, kèm tổng số lượng.

**Why this priority**: Đây là yêu cầu cốt lõi — đưa danh sách outfits ra mặt tiền điều hướng thay vì chôn trong menu Hồ sơ (menu này vừa bị ẩn).

**Independent Test**: Đăng nhập tài khoản có sẵn outfits, bấm tab Outfits, thấy đúng danh sách + tổng số; tài khoản mới thấy màn hình trống với nút tạo outfit.

**Acceptance Scenarios**:

1. **Given** người dùng đã đăng nhập, **When** nhìn thanh điều hướng dưới, **Then** thấy 5 icon theo thứ tự: Home, Wardrobe, Stylist, Outfits, Profile.
2. **Given** đang ở bất kỳ tab nào, **When** bấm icon Outfits, **Then** mở trang danh sách outfits của chính user đó (không lẫn dữ liệu tài khoản khác).
3. **Given** user có outfits đã lưu, **When** mở tab Outfits, **Then** thấy lưới 2 cột gồm ảnh bìa, tên, ngày tạo và dòng tổng số lượng.
4. **Given** user chưa có outfit nào, **When** mở tab Outfits, **Then** thấy trạng thái trống thân thiện với nút dẫn sang Studio tạo mới.

---

### User Story 2 - Xem chi tiết, mở Studio, xóa outfit (Priority: P2)

Người dùng bấm vào một outfit trong danh sách để xem chi tiết các món đồ, mở lên Studio chỉnh sửa hoặc xóa khi không cần.

**Why this priority**: Tái sử dụng đầy đủ hành vi của màn danh sách hiện có — tab mới không được mất tính năng so với đường vào cũ.

**Independent Test**: Bấm 1 outfit → xem được danh sách món trong set; bấm mở Studio → set được nạp lên canvas; xóa → biến mất khỏi lưới kèm thông báo.

**Acceptance Scenarios**:

1. **Given** đang ở tab Outfits, **When** bấm vào 1 outfit, **Then** thấy bottom sheet chi tiết: ảnh bìa, tên, ngày tạo, mô tả và danh sách món đồ trong set.
2. **Given** đang xem chi tiết, **When** chọn mở trên Studio, **Then** set được nạp lên canvas Studio.
3. **Given** đang xem chi tiết, **When** xác nhận xóa, **Then** outfit biến mất khỏi danh sách và có thông báo kết quả.

---

### Edge Cases

- Chuyển tài khoản A → B: tab Outfits của B không được hiện dữ liệu A (dựa vào cơ chế reset session đã có).
- Mất mạng khi mở tab: hiện lỗi thân thiện kèm nút thử lại, không trang trắng.
- Danh sách rất dài: lưới cuộn mượt, ảnh dùng cache theo kích thước hiển thị.
- Xóa outfit đang mở ở Studio: danh sách radical cập nhật ở lần mở tab kế tiếp.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Hệ thống PHẢI có tab Outfits riêng trên thanh điều hướng dưới, đặt giữa Stylist và Profile.
- **FR-002**: Tab Outfits PHẢI hiển thị danh sách outfits của đúng tài khoản đang đăng nhập, kèm tổng số lượng.
- **FR-003**: Mỗi outfit trong lưới PHẢI hiển thị ảnh bìa (hoặc placeholder khi chưa có), tên và ngày tạo.
- **FR-004**: Bấm vào outfit PHẢI mở chi tiết (các món trong set) với các hành động: mở trên Studio, xóa có xác nhận.
- **FR-005**: Danh sách trống PHẢI có trạng thái trống với nút dẫn sang Studio tạo mới.
- **FR-006**: Tab PHẢI hỗ trợ kéo-để-làm-mới và nút thử lại khi lỗi mạng.
- **FR-007**: Chuyển tab PHẢI giữ trạng thái các tab khác (không mất vị trí cuộn tủ đồ/Stylist) theo hành vi shell hiện tại.

### Key Entities

- **UserOutfit**: Bộ trang phục đã lưu (tên, mô tả, ảnh bìa, ngày tạo, danh sách món đồ trong set).
- **OutfitItem**: Món đồ thuộc set (danh mục, phong cách, màu sắc, ảnh).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Người dùng mở được danh sách outfits của mình trong tối đa 2 thao tác từ bất kỳ màn hình nào (qua tab bar luôn hiển thị).
- **SC-002**: 100% lần mở tab hiển thị đúng dữ liệu của tài khoản đang đăng nhập (không rò rỉ liên tài khoản).
- **SC-003**: 90% người dùng mới (chưa có outfit) bấm nút tạo mới từ trạng thái trống mà không cần hướng dẫn thêm.
- **SC-004**: Thao tác xóa outfit luôn có xác nhận và phản hồi kết quả rõ ràng, không xóa nhầm.

## Assumptions

- Tái sử dụng màn `OutfitsListScreen` và provider/repository outfits hiện có (`GET /me/outfits`, chi tiết, xóa) — không viết màn hình mới từ đầu, chỉ đưa vào nhánh shell + tab bar.
- Icon tab: phong cách outline/rounded đồng bộ tab bar hiện tại, nhãn "Outfits".
- Tab chỉ hiện khi đã đăng nhập (kế thừa redirect auth của shell hiện tại).
- Cơ chế reset session khi đổi tài khoản (đã triển khai) bao phủ luôn tab mới.
