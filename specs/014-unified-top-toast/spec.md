# Feature Specification: Thống nhất thông báo toàn app thành Top Pop-up Toast 2 Giây

**Feature Branch**: `014-unified-top-toast`

**Created**: 2026-09-28

**Status**: Draft

**Input**: User description: "mình muốn thống nhất lại các thông báo của dự án vd như thông báo hết lượt này thành 1 dạng duy nhất là pop up phía trên của app 2 giây r ẩn đi" kèm ảnh chụp lỗi hết lượt AI phối đồ tại Outfit Studio.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Thông báo hết lượt AI và lỗi tác vụ xuất hiện ở đỉnh màn hình (Priority: P1)

Khi người dùng thao tác trong app (ví dụ bấm "Tạo Set Đồ Với AI Ngay" trong Outfit Studio hoặc Stylist) mà gặp lỗi hoặc hết lượt tạo AI trong ngày:
Thay vì hiển thị một khối thông báo lỗi đỏ chèn bên dưới nút bấm làm đẩy layout hoặc hiển thị SnackBar ở đáy màn hình bị che khuất bởi Bottom Navigation Bar:
Hệ thống sẽ hiển thị một Pop-up Toast nổi nhẹ nhàng trượt xuống từ mép trên màn hình (dưới Safe Area / Status bar), hiển thị rõ ràng nội dung thông báo (ví dụ: "Bạn đã dùng hết lượt tạo trang phục bằng AI trong hôm nay."), duy trì chính xác trong **2 giây**, sau đó tự động trượt lên và ẩn đi một cách mượt mà.

**Why this priority**: Giải quyết trực tiếp vấn đề người dùng phản ánh trong hình ảnh đính kèm (hộp thông báo hết lượt đỏ to bên dưới nút bấm gây xấu layout) và ngăn tình trạng thông báo đáy bị che khuất bởi thanh điều hướng BottomNav.

**Independent Test**:
Vào Outfit Studio khi hết lượt tạo AI hoặc giả lập lỗi, bấm "Tạo Set Đồ Với AI Ngay". Quan sát thấy pop-up xuất hiện ở đỉnh màn hình, giao diện bên dưới nút bấm không bị nhảy layout hay sinh khung đỏ cố định, sau 2 giây pop-up tự động biến mất.

**Acceptance Scenarios**:
1. **Given** Người dùng ở màn Outfit Studio và tài khoản đã hết quota AI ngày, **When** Người dùng nhấn nút "Tạo Set Đồ Với AI Ngay", **Then** Một thông báo dạng toast dạng pop-up nổi xuất hiện ở phía trên cùng của app với nội dung "Bạn đã dùng hết lượt tạo trang phục bằng AI trong hôm nay.", tồn tại trong 2 giây rồi tự động ẩn đi, không còn khối khung đỏ nằm bên dưới nút bấm.
2. **Given** Pop-up đang hiển thị ở đỉnh màn hình, **When** Người dùng vuốt nhẹ lên trên (swipe up) hoặc chạm vào pop-up trước khi hết 2 giây, **Then** Pop-up lập tức ẩn đi ngay lập tức không cần đợi hết 2 giây.

---

### User Story 2 - Thống nhất chuẩn thông báo (Toast Provider / Utility) toàn dự án (Priority: P2)

Cung cấp một thành phần thông báo thống nhất (`ClosyToast` / `ClosyNotification`) trong `lib/shared/widgets/` hoặc `lib/core/` có thể được kích hoạt nhanh từ bất kỳ màn hình nào (BuildContext hoặc Global Overlay Key) để thay thế dần các lệnh gọi `ScaffoldMessenger.of(context).showSnackBar` rải rác.
Hỗ trợ 4 trạng thái thiết kế Quiet Luxury:
- **Error / Warning (Cảnh báo / Hết lượt / Thất bại):** Nền sáng kem `#FFF8F7` hoặc `#FFFFFF`, viền đỏ trầm mờ `#F0D5D3`, icon cảnh báo thanh lịch, chữ `#842029`.
- **Success (Thành công):** Nền `#F6FAF7`, viền xanh sage `#D4E7D9`, icon tick, chữ `#1B4D2E`.
- **Info / Neutral (Thông tin chung):** Nền `#FAF8F5`, viền champagne `#E8E3DC`, icon info, chữ `#1A1A1A`.

**Why this priority**: Đảm bảo toàn bộ dự án tuân theo một hệ thống thông báo duy nhất, đồng bộ về thời gian hiển thị (2 giây), vị trí (top pop-up), và phong cách Quiet Luxury chuẩn mực.

**Independent Test**:
Kích hoạt `ClosyToast.show(context, message: 'Đã lưu trang phục', type: ToastType.success)` trên màn hình bất kỳ. Kiểm tra pop-up xuất hiện ở trên đỉnh, đúng màu sắc Quiet Luxury, biến mất sau 2 giây.

**Acceptance Scenarios**:
1. **Given** Người dùng thực hiện một hành động thành công hoặc cảnh báo ở màn hình bất kỳ (như sao chép, lưu đồ, thêm đồ), **When** Hành động hoàn tất, **Then** Pop-up đỉnh màn hình xuất hiện với kiểu dáng Quiet Luxury tương ứng, biến mất sau 2 giây.
2. **Given** Người dùng kích hoạt liên tiếp 2 thông báo, **When** Thông báo thứ 2 xuất hiện, **Then** Hệ thống hủy thông báo cũ một cách mượt mà và hiển thị thông báo mới mà không bị xếp chồng hay đè lỗi giao diện.

---

### User Story 3 - Thay thế các SnackBar dưới đáy màn hình bằng Top Pop-up Toast (Priority: P3)

Chuyển đổi các thông báo người dùng quan trọng trên các màn hình chính (Tủ đồ, Chi tiết đồ, Hồ sơ, Cộng đồng) từ `ScaffoldMessenger.of(context).showSnackBar` sang Top Pop-up Toast 2 giây để hoàn toàn giải phóng khu vực đáy màn hình khỏi các thông báo che khuất Navigation Bar.

**Why this priority**: Hoàn thiện tính thống nhất toàn diện của ứng dụng theo đúng nguyện vọng "thống nhất lại các thông báo của dự án".

**Independent Test**:
Thực hiện các thao tác hiển thị phản hồi ở Tủ đồ (xóa đồ, cập nhật), xác nhận thông báo hiển thị ở đỉnh trong 2 giây thay vì đáy màn hình.

**Acceptance Scenarios**:
1. **Given** Người dùng thực hiện thao tác có phản hồi thông báo tại màn hình Wardrobe / ItemDetail, **When** Phản hồi xuất hiện, **Then** Thông báo xuất hiện ở đỉnh màn hình thay vì đáy màn hình.

---

### Edge Cases

- **Màn hình có Notch / Dynamic Island / Status Bar cao:** Pop-up phải tự động cộng thêm `MediaQuery.of(context).padding.top` (hoặc Safe Area) để không bao giờ bị tai thỏ hay thanh trạng thái của hệ điều hành che lấp nội dung.
- **Bàn phím ảo đang mở:** Khi bàn phím xuất hiện ở đáy màn hình, pop-up ở đỉnh màn hình vẫn hiển thị bình thường mà không bị đẩy lệch vị trí.
- **Người dùng chuyển màn hình trước khi hết 2 giây:** Pop-up không bị crash do mất BuildContext; overlay tự huỷ an toàn khi dispose.
- **Thông báo có nội dung văn bản dài (2 - 3 dòng):** Pop-up tự động co giãn chiều cao linh hoạt, chữ bọc vừa vặn (`softWrap: true`), không bao giờ bị overflow pixel vàng-đen.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Hệ thống PHẢI cung cấp một widget/utility thông báo dạng Pop-up ở phía trên cùng của ứng dụng (`ClosyToast`), với thời gian hiển thị mặc định chính xác là **2 giây** (`Duration(seconds: 2)`).
- **FR-002**: Khi hết thời gian 2 giây, Pop-up PHẢI tự động trượt lên / mờ dần và biến mất khỏi màn hình.
- **FR-003**: Pop-up PHẢI cho phép người dùng chạm (tap) hoặc vuốt lên (swipe up) để đóng ngay lập tức mà không cần đợi hết 2 giây.
- **FR-004**: Pop-up PHẢI hiển thị an toàn bên dưới Status Bar / Tai thỏ của thiết bị (Safe Area aware).
- **FR-005**: Màn hình Outfit Studio PHẢI loại bỏ khối container đỏ tĩnh bên dưới nút "Tạo Set Đồ Với AI Ngay", và kích hoạt Top Pop-up Toast khi `state.errorMessage` xuất hiện (đặc biệt là thông báo hết lượt AI).
- **FR-006**: Pop-up PHẢI hỗ trợ các biến thể kiểu dáng chuẩn Quiet Luxury: Error/Hết lượt (nền kem ửng hồng viền đỏ trầm), Success (nền kem nhạt viền sage mờ), Info (nền ngà viền champagne), sử dụng font Be Vietnam Pro.
- **FR-007**: Hệ thống PHẢI đảm bảo không xuất hiện nhiều hơn 1 Pop-up đồng thời; thông báo mới sẽ thay thế êm dịu thông báo cũ.

### Key Entities

- **ClosyToast**: Thành phần điều phối hiển thị Overlay Entry dạng pop-up phía trên màn hình.
- **ClosyToastType**: Enum xác định loại thông báo: `error`, `warning`, `success`, `info`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% các thông báo hết lượt AI và lỗi tạo outfit trong Outfit Studio hiển thị qua Top Pop-up Toast ở đỉnh màn hình thay vì khung đỏ tĩnh hay SnackBar đáy.
- **SC-002**: Thời lượng hiển thị của Pop-up trước khi tự ẩn chính xác là 2 giây (±100ms cho animation mượt mà).
- **SC-003**: 0 lỗi overflow giao diện tại đỉnh màn hình trên mọi tỉ lệ thiết bị (kể cả máy có Dynamic Island / Tai thỏ).
- **SC-004**: `flutter analyze` đạt 0 issues và 100% tests liên quan pass.

## Assumptions

- Khung đỏ hiển thị lỗi trong Outfit Studio hiện tại là nguyên nhân trực tiếp thúc đẩy yêu cầu này (như hình ảnh đính kèm của người dùng).
- Sử dụng cơ chế Flutter `Overlay` hoặc `ScaffoldMessenger` với `SnackBarBehavior.floating` kết hợp `margin` đỉnh, hoặc một `OverlayEntry` chuyên dụng để đảm bảo hiển thị mượt mà không phụ thuộc vào `Scaffold`.
- Thời gian 2 giây được áp dụng mặc định cho tất cả các thông báo toast dạng này theo đúng chỉ định của người dùng.
