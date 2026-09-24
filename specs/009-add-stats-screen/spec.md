# Feature Specification: Statistics Screen

**Feature Branch**: `009-add-stats-screen`

**Created**: 2026-09-19

**Status**: Draft

**Input**: User description: "thêm màn hình thống kê"

## Clarifications

### Session 2026-09-19

- Q: Màn thống kê mới thay thế hay bổ sung cho màn "Thống kê tủ đồ" hiện có? → A: Màn riêng, bổ sung chỉ số mới; giữ nguyên màn insights hiện có.
- Q: Bộ chỉ số bắt buộc cho phiên bản đầu? → A: Đủ 4 nhóm — (a) mức độ sử dụng 30/60/90 ngày, (b) giá trị & cost-per-wear, (c) outfit, (d) xu hướng theo thời gian; loại trừ chi tiêu ví/gói.
- Q: Nguồn dữ liệu cho số lần mặc/lịch sử mặc để tính cost-per-wear và xu hướng? → A: Chưa rõ — bắt buộc xác minh API trước khi code; nếu thiếu dữ liệu thì phối hợp backend.
- Q: Điểm vào màn Thống kê mới đặt ở đâu? → A: Từ trang Hồ sơ, cạnh mục thống kê hiện có.
- Q: Xu hướng theo thời gian hiển thị theo khoảng nào? → A: Theo tháng, 6 tháng gần nhất.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Xem tổng quan & mức độ sử dụng tủ đồ (Priority: P1)

Người dùng mở màn hình Thống kê và thấy ngay bức tranh tổng quan về tủ đồ: tổng số món, số món đang dùng đều, số món lâu chưa mặc (30/60/90 ngày) và tỷ lệ sử dụng. Đây là giá trị cốt lõi giúp người dùng biết mình đang dùng tủ đồ hiệu quả hay lãng phí.

**Why this priority**: Là phần dữ liệu quan trọng nhất và độc lập; nếu chỉ có phần này vẫn tạo ra một màn hình thống kê hữu ích (MVP).

**Independent Test**: Có thể kiểm thử độc lập bằng tài khoản có dữ liệu mặc/không mặc: mở màn, đối chiếu số món ít mặc và tỷ lệ sử dụng với danh sách thực tế.

**Acceptance Scenarios**:

1. **Given** người dùng có dữ liệu tủ đồ, **When** mở màn Thống kê, **Then** hiển thị tổng số món, số món ít mặc theo mốc 30/60/90 ngày và tỷ lệ sử dụng, tải xong trong thời gian hợp lý.
2. **Given** người dùng chưa có món nào, **When** mở màn, **Then** hiển thị trạng thái rỗng thân thiện hướng dẫn thêm món, không lỗi.
3. **Given** tải dữ liệu thất bại, **When** màn hình mở, **Then** hiển thị thông báo lỗi thân thiện và nút thử lại.
4. **Given** người dùng kéo làm mới, **When** hoàn tất, **Then** số liệu cập nhật theo dữ liệu mới nhất.

---

### User Story 2 - Phân tích giá trị & chi phí mỗi lần mặc (Priority: P2)

Người dùng xem tổng giá trị tủ đồ, giá trị theo danh mục, và chỉ số "chi phí mỗi lần mặc" (cost-per-wear) để hiểu món nào đáng tiền, món nào lãng phí. Giúp ra quyết định mua sắm và thanh lý.

**Why this priority**: Giá trị cao cho hành vi nhưng phụ thuộc dữ liệu giá mua và lịch sử mặc; xếp sau phần tổng quan.

**Independent Test**: Có thể kiểm thử độc lập bằng tài khoản có giá mua và số lần mặc: đối chiếu cost-per-wear của vài món với phép tính thủ công.

**Acceptance Scenarios**:

1. **Given** món có giá mua và số lần mặc, **When** xem phần giá trị, **Then** hiển thị chi phí mỗi lần mặc chính xác theo công thức giá mua / số lần mặc.
2. **Given** món chưa từng được mặc, **When** xem, **Then** chỉ số được xử lý an toàn (không chia cho 0, có nhãn rõ nghĩa).
3. **Given** tổng giá trị tủ đồ, **When** xem, **Then** số liệu khớp với dữ liệu giá mua đã nhập.

---

### User Story 3 - Phân tích outfit & xu hướng theo thời gian (Priority: P3)

Người dùng xem thống kê về các bộ outfit đã lưu (và đã dùng nếu có dữ liệu) và xu hướng theo thời gian (theo tháng) để thấy thói quen mặc thay đổi thế nào.

**Why this priority**: Giá trị bổ sung, phụ thuộc dữ liệu lịch sử outfit; có thể làm sau khi P1/P2 ổn.

**Independent Test**: Có thể kiểm thử độc lập bằng tài khoản có nhiều outfit: đối chiếu số lượng và biểu đồ xu hướng với dữ liệu thực tế.

**Acceptance Scenarios**:

1. **Given** người dùng có outfit đã lưu, **When** xem phần outfit, **Then** hiển thị số lượng và thống kê liên quan.
2. **Given** có lịch sử mặc theo thời gian, **When** xem xu hướng, **Then** hiển thị biểu đồ theo tháng phản ánh đúng dữ liệu.
3. **Given** chưa đủ dữ liệu để vẽ xu hướng, **When** xem, **Then** hiển thị trạng thái "chưa đủ dữ liệu" thay vì biểu đồ rỗng gây hiểu nhầm.

---

### Edge Cases

- Tủ đồ rỗng hoặc mới tạo tài khoản — không lỗi, hiển thị trạng thái rỗng.
- Món thiếu giá mua — không tính vào tổng giá trị/cost-per-wear; có chú thích.
- Món chưa từng mặc — tránh chia cho 0.
- Dữ liệu lịch sử mặc rỗng — ẩn phần xu hướng, hiện gợi ý.
- API máy chủ thiếu số lần mặc/lịch sử mặc — ẩn cost-per-wear và xu hướng kèm thông báo rõ ràng, không hiển thị số liệu sai.
- Mất mạng hoặc máy chủ lỗi — thông báo thân thiện, giữ màn hình, thử lại được.
- Dữ liệu lớn (nhiều trăm món) — màn hình vẫn mượt, không treo.
- Máy chủ chỉ có outfit đã lưu (không có outfit đã dùng) — vẫn hiển thị thống kê đã lưu, không lỗi.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Người dùng MUST truy cập được màn hình Thống kê mới (màn riêng, bổ sung cho màn "Thống kê tủ đồ" hiện có, không thay thế) từ trang Hồ sơ, cạnh mục thống kê hiện có.
- **FR-002**: Màn hình MUST hiển thị tổng số món và tỷ lệ sử dụng tủ đồ.
- **FR-003**: Màn hình MUST hiển thị số món ít mặc theo các mốc 30/60/90 ngày.
- **FR-004**: Màn hình MUST hiển thị tổng giá trị tủ đồ dựa trên giá mua đã nhập.
- **FR-005**: Màn hình MUST hiển thị chi phí mỗi lần mặc (cost-per-wear) cho các món đủ dữ liệu, xử lý an toàn món chưa từng mặc.
- **FR-006**: Màn hình MUST hiển thị thống kê outfit đã lưu; nếu máy chủ cung cấp dữ liệu outfit đã dùng thì MUST hiển thị thêm, nếu không thì chỉ hiển thị outfit đã lưu.
- **FR-007**: Màn hình MUST hiển thị xu hướng sử dụng theo tháng trong 6 tháng gần nhất khi có đủ dữ liệu.
- **FR-008**: Màn hình MUST có trạng thái rỗng, trạng thái lỗi và khả năng làm mới dữ liệu.
- **FR-009**: Số liệu thống kê MUST nhất quán với nguồn hiển thị khác trong app: tổng số món khớp với Home quick stats, tổng giá trị khớp với màn "Thống kê tủ đồ" (`/wardrobe/insights`) trên cùng tài khoản và cùng thời điểm.
- **FR-010**: Màn hình MUST hiển thị số liệu cuối cùng trong thời gian hợp lý với tài khoản hàng trăm món (mục tiêu dưới 3 giây trong điều kiện mạng ổn định).
- **FR-011**: Màn hình MUST tuân theo hệ thống thiết kế hiện có (Quiet Luxury) và đọc rõ ở chế độ sáng/tối.
- **FR-012**: Màn hình MUST không phơi bày hoặc yêu cầu dữ liệu nhạy cảm ngoài phạm vi tủ đồ/outfit của chính người dùng.
- **FR-013**: Phiên bản đầu MUST bao gồm 4 nhóm chỉ số (mức độ sử dụng, giá trị & cost-per-wear, outfit, xu hướng thời gian) khi dữ liệu tương ứng có sẵn; nhóm nào thiếu dữ liệu MUST tuân theo quy tắc fallback của FR-014. Chi tiêu ví/gói hội viên MUST nằm ngoài phạm vi.
- **FR-014**: Trước khi triển khai cost-per-wear và xu hướng thời gian, đội MUST xác minh API máy chủ có cung cấp số lần mặc/lịch sử mặc hay không; nếu thiếu, MUST thống nhất bổ sung với backend hoặc ẩn chỉ số kèm thông báo rõ ràng.

### Key Entities

- **Chỉ số sử dụng (Utilization Metric)**: Tổng món, số món ít mặc theo mốc ngày, tỷ lệ sử dụng.
- **Giá trị & chi phí (Value Metric)**: Tổng giá trị, giá trị theo danh mục, chi phí mỗi lần mặc.
- **Thống kê outfit (Outfit Stat)**: Số outfit đã lưu, và số đã dùng nếu máy chủ cung cấp.
- **Xu hướng thời gian (Time Trend)**: Số liệu mặc theo tháng.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Người dùng mở được màn Thống kê và thấy số liệu tổng quan trong dưới 3 giây với tài khoản hàng trăm món (mạng ổn định).
- **SC-002**: 100% chỉ số hiển thị khớp với dữ liệu thực tế khi đối chiếu thủ công (tổng món, món ít mặc, tổng giá trị).
- **SC-003**: 5/5 tài khoản test (rỗng, ít món, nhiều món, thiếu giá, nhiều outfit) đều không gặp lỗi và có trạng thái phù hợp.
- **SC-004**: Cost-per-wear tính đúng 100% trên mẫu kiểm thử (bao gồm món chưa từng mặc, không chia cho 0).
- **SC-005**: 0 màn hình trắng/lỗi khi mất mạng — luôn có thông báo và nút thử lại.
- **SC-006**: Người dùng thấy màn hình đọc rõ ở cả chế độ sáng và tối.

## Assumptions

- Màn hình mới là màn riêng, bổ sung chỉ số mới; màn "Thống kê tủ đồ" hiện có (`/wardrobe/insights`) giữ nguyên và tiếp tục hoạt động.
- Dữ liệu giá mua và danh mục đã có trong hệ thống; dữ liệu số lần mặc/lịch sử mặc chưa xác minh và có thể phải bổ sung từ máy chủ (xem FR-014).
- Hiện mobile chỉ nhận `lastWornDaysAgo` từ máy chủ; số lần mặc/lịch sử mặc CHƯA được xác minh — đây là hạng mục phải kiểm tra API trước khi code cost-per-wear và xu hướng (FR-014).
- Người dùng đã đăng nhập; màn hình chỉ hiển thị dữ liệu của chính họ.
- Phần chi tiêu ví/gói hội viên nằm ngoài phạm vi phiên bản đầu (bản phát hành Play đang ẩn luồng trả phí theo spec 008).
- Ngôn ngữ hiển thị tiếng Việt, theo hệ thống thiết kế hiện có.
