# Feature Specification: Payment Rebuild

**Feature Branch**: `001-payment-rebuild`

**Created**: 2026-09-12

**Status**: Draft

**Input**: User description: "tạo plan để làm lại phần payment"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Nạp tiền vào ví (Priority: P1)

Người dùng đang ở màn hình ví, chọn mệnh giá có sẵn hoặc nhập số tiền tùy ý, xác nhận và được chuyển sang cổng thanh toán để quét mã VietQR / chuyển khoản. Sau khi thanh toán xong, số dư ví tăng lên và giao dịch xuất hiện trong lịch sử.

**Why this priority**: Đây là nguồn tiền cho mọi giao dịch sau này (mua gói bằng ví). Không có nạp ví ổn định thì toàn bộ luồng payment sập.

**Independent Test**: Chỉ triển khai luồng nạp ví cũng đã có giá trị độc lập — có thể kiểm thử bằng cách nạp 50.000đ, thanh toán thành công trên cổng thanh toán, quay lại app thấy số dư tăng đúng 50.000đ.

**Acceptance Scenarios**:

1. **Given** người dùng ở màn hình ví với số dư 0đ, **When** chọn mệnh giá 100.000đ và xác nhận nạp, **Then** hệ thống tạo một mã thanh toán duy nhất và mở trang thanh toán cho người dùng.
2. **Given** người dùng đã quét QR và chuyển khoản thành công, **When** quay lại app / chờ tự động kiểm tra, **Then** số dư ví tăng đúng số tiền nạp trong vòng 2 phút và lịch sử ghi nhận 1 giao dịch thu.
3. **Given** người dùng nhập 5.000đ, **When** bấm xác nhận, **Then** hệ thống từ chối với thông báo số tiền tối thiểu 10.000đ và không tạo mã thanh toán.
4. **Given** người dùng hủy thanh toán trên cổng thanh toán, **When** quay lại app, **Then** app hiển thị trạng thái đã hủy, số dư không đổi.

---

### User Story 2 - Mua gói hội viên bằng số dư ví (Priority: P1)

Người dùng đã có đủ số dư ví, vào màn hình gói hội viên, xác nhận dùng ví để mua gói Premium. Tài khoản được nâng cấp ngay mà không cần qua cổng thanh toán ngoài.

**Why this priority**: Mang lại trải nghiệm mua 1 chạm nhanh nhất, tận dụng số dư đã nạp, giảm phụ thuộc cổng thanh toán ngoài.

**Independent Test**: Có thể kiểm thử độc lập bằng cách chuẩn bị ví 100.000đ, mua gói 59.000đ, xác nhận số dư còn lại và trạng thái Premium được kích hoạt.

**Acceptance Scenarios**:

1. **Given** ví có 100.000đ và gói Premium giá 59.000đ, **When** người dùng xác nhận mua bằng ví, **Then** hệ thống trừ 59.000đ, kích hoạt Premium 30 ngày và hiển thị xác nhận thành công.
2. **Given** ví có 10.000đ và gói giá 59.000đ, **When** người dùng bấm mua bằng ví, **Then** hệ thống không trừ tiền mà gợi ý nạp thêm và mở sẵn màn hình nạp tiền.
3. **Given** người dùng đã là Premium, **When** mở màn hình nâng cấp, **Then** hệ thống hiển thị trạng thái đang dùng Premium thay vì nút mua.

---

### User Story 3 - Mua gói trực tiếp qua cổng thanh toán (Priority: P2)

Người dùng không muốn nạp ví trước, chọn thanh toán trực tiếp gói Premium bằng VietQR / chuyển khoản ngân hàng. Sau thanh toán, tài khoản lên Premium ngay.

**Why this priority**: Phục vụ người dùng mới chưa có ví, giảm 1 bước nạp tiền. Quan trọng nhưng ưu tiên sau 2 luồng ví vì ví là nền tảng dùng lại.

**Independent Test**: Kiểm thử độc lập bằng cách mua gói trực tiếp từ ví 0đ, thanh toán ngoài thành công, quay lại thấy trạng thái Premium.

**Acceptance Scenarios**:

1. **Given** người dùng chọn gói Premium, **When** bấm quét VietQR trực tiếp, **Then** hệ thống tạo mã thanh toán gói và mở trang thanh toán.
2. **Given** thanh toán trực tiếp thành công, **When** hệ thống nhận xác nhận từ ngân hàng, **Then** tài khoản được nâng Premium trong vòng 2 phút mà không cần nạp ví trung gian.
3. **Given** người dùng thoát màn hình chờ giữa chừng, **When** mở lại màn hình hội viên, **Then** vẫn thấy trạng thái giao dịch đang chờ / thành công chính xác.

---

### User Story 4 - Theo dõi trạng thái và lịch sử giao dịch (Priority: P2)

Người dùng xem được màn hình chờ thanh toán (mã đơn, số tiền, thời gian đã chờ, nút mở lại trang thanh toán), xem lịch sử biến động số dư ví và làm mới để cập nhật.

**Why this priority**: Niềm tin thanh toán đến từ minh bạch trạng thái. Giảm khiếu nại "trừ tiền mà không lên gói".

**Independent Test**: Kiểm thử bằng cách tạo 1 giao dịch, kiểm tra màn hình chờ hiển thị đúng số tiền / mã đơn (không hardcode), lịch sử hiển thị đúng chiều thu-chi.

**Acceptance Scenarios**:

1. **Given** đang chờ thanh toán 100.000đ nạp ví, **When** mở màn hình chờ, **Then** thấy đúng mã đơn, đúng 100.000đ, nhãn "Nạp ví" (không hiện nhầm thông tin gói khác).
2. **Given** đang chờ thanh toán, **When** hệ thống tự kiểm tra định kỳ, **Then** khi có xác nhận sẽ tự chuyển sang màn hình thành công mà không cần người dùng thao tác.
3. **Given** ở màn hình ví, **When** kéo để làm mới, **Then** số dư và lịch sử được tải lại, khi trống hiển thị trạng thái trống thân thiện.

### Edge Cases

- Thanh toán thành công nhưng app đang tắt / mất mạng khi quay lại — trạng thái phải đúng khi mở app lần sau.
- Người dùng bấm tạo mã thanh toán 2 lần liên tiếp — chỉ 1 mã có hiệu lực, không bị trừ tiền 2 lần.
- Mã thanh toán hết hạn (quá 15 phút chưa trả) — hiển thị hết hạn và cho tạo mã mới.
- Số tiền chuyển khoản sai lệch với mã đã tạo — không cộng tiền nhầm, giao dịch giữ trạng thái chờ / thất bại với thông báo rõ.
- Mất kết nối khi đang chờ — hiển thị lỗi mạng, cho thử lại, không kẹt vòng xoay vô hạn.
- Thanh toán ví cho gói nhưng số dư vừa bị dùng ở thiết bị khác — từ chối với thông báo số dư không đủ.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Người dùng PHẢI chọn được mệnh giá nạp nhanh và nhập số tiền tùy ý với mức tối thiểu 10.000đ.
- **FR-002**: Hệ thống PHẢI tạo mã thanh toán duy nhất cho mỗi yêu cầu nạp ví và mỗi yêu cầu mua gói trực tiếp.
- **FR-003**: Hệ thống PHẢI mở trang thanh toán ngoài (VietQR / chuyển khoản ngân hàng) cho người dùng hoàn tất thanh toán.
- **FR-004**: Hệ thống PHẢI tự động kiểm tra kết quả giao dịch định kỳ và cập nhật trạng thái mà không yêu cầu người dùng nhập liệu thêm.
- **FR-005**: Người dùng PHẢI xem được màn hình chờ với đúng mã đơn, đúng số tiền, đúng loại giao dịch (nạp ví hay mua gói) và thời gian đã chờ.
- **FR-006**: Người dùng PHẢI mở lại được trang thanh toán từ màn hình chờ khi lỡ tắt trình duyệt / ứng dụng ngân hàng.
- **FR-007**: Người dùng PHẢI mua được gói hội viên trực tiếp bằng số dư ví khi số dư đủ, với bước xác nhận rõ số tiền và số dư hiện tại.
- **FR-008**: Hệ thống PHẢI từ chối mua bằng ví khi số dư không đủ và gợi ý nạp thêm thay vì trừ âm.
- **FR-009**: Người dùng PHẢI xem được số dư ví hiện tại và lịch sử biến động (thu khi nạp, chi khi mua gói) kèm thời gian.
- **FR-010**: Hệ thống PHẢI cho phép làm mới số dư và lịch sử thủ công (kéo làm mới / nút làm mới).
- **FR-011**: Hệ thống PHẢI hiển thị trạng thái hủy / hết hạn khi người dùng hủy trên cổng thanh toán hoặc quá thời gian cho phép.
- **FR-012**: Hệ thống PHẢI ngăn tạo trùng giao dịch khi người dùng bấm liên tục (chặn bấm đôi trong lúc đang tạo mã).
- **FR-013**: Hệ thống PHẢI đồng bộ lại trạng thái hội viên và ví ngay sau khi giao dịch thành công để các màn hình khác hiển thị đúng.
- **FR-014**: Màn hình chờ PHẢI cho phép rời đi an toàn với cảnh báo giao dịch vẫn đang xử lý, và trạng thái vẫn tra cứu được khi quay lại.

### Key Entities

- **Ví (Wallet)**: Số dư khả dụng của người dùng, đơn vị VNĐ, tăng khi nạp thành công, giảm khi mua gói bằng ví.
- **Giao dịch thanh toán (Payment Order)**: Gồm mã đơn duy nhất, số tiền, loại (nạp ví / mua gói trực tiếp), trạng thái (chờ, thành công, hủy, hết hạn), thời gian tạo.
- **Gói hội viên (Subscription Plan)**: Gồm tên gói, giá, thời hạn (30 ngày), các hạn mức đi kèm (sức chứa tủ đồ, lượt AI mỗi ngày).
- **Biến động số dư (Wallet Statement)**: Gồm chiều thu/chi, số tiền, mô tả, thời gian phát sinh.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Người dùng hoàn tất nạp ví (từ lúc bấm nạp đến khi số dư cập nhật) trong vòng 3 phút khi thanh toán ngoài thành công.
- **SC-002**: 95% giao dịch thanh toán ngoài thành công được phản ánh đúng số dư / trạng thái gói trong vòng 2 phút mà không cần liên hệ hỗ trợ.
- **SC-003**: 100% màn hình chờ hiển thị đúng số tiền và loại giao dịch tương ứng (không còn hiện sai thông tin cố định).
- **SC-004**: Không có trường hợp trừ tiền ví 2 lần cho 1 lần bấm mua khi kiểm thử bấm liên tục.
- **SC-005**: 90% người dùng thử lần đầu hoàn tất được ít nhất 1 trong 2 luồng (nạp ví hoặc mua gói) mà không gặp lỗi chặn.

## Assumptions

- Cổng thanh toán VietQR / chuyển khoản ngân hàng và cơ chế webhook xác nhận do backend cung cấp; mobile chỉ tạo yêu cầu và tra cứu trạng thái.
- Mỗi mệnh giá nạp tối thiểu 10.000đ theo giới hạn cổng thanh toán; mệnh giá gợi ý gồm 50.000đ, 100.000đ, 200.000đ, 500.000đ.
- Mã thanh toán hết hiệu lực sau 15 phút nếu chưa thanh toán.
- Một người dùng tại một thời điểm chỉ cần theo dõi 1 giao dịch đang chờ trên 1 thiết bị; tra cứu lại qua lịch sử khi cần.
- Gói Premium chuẩn có thời hạn 30 ngày; quyền lợi chi tiết lấy từ danh mục gói hiện có, mobile không hardcode giá trong logic.
