# Feature Specification: Wardrobe UX Bulk Quota Fixes

**Feature Branch**: `004-wardrobe-ux-bulk-quota`

**Created**: 2026-09-14

**Status**: Draft

**Input**: User description: "tạo plan update qua những mô tả lỗi khi testing thủ công của tui, 1. ở trang wardrobe khi tui click vào xem detail sau đó kéo bên trái để về lại trang list thì bị giật màng hình detail 1 lần rồi mới về trang ảnh hưởng UX, nếu tui nhấn icon mũi tên về thì không bị sao đang hoạt động đúng, 2. Chưa có trang upload từ tủ đồ hệ thống có sẵn hãy bổ sung thêm, 3.chưa có xóa hàng loạt item cũng như outfit, 4. hạn mức sử dụng AI bạn hãy đồng bộ thông tin hiển thị ở trang hồ sơ các nhân với trang gói hội viên và hạn mức tui muốn đồng bộ hiển thị sử dụng 0/5 lượt như ở trang hồ sơ cá nhân."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Quay lại danh sách tủ đồ mượt mà, không giật hình (Priority: P1)

Người dùng mở trang Wardrobe, nhấn vào một món đồ để xem chi tiết, sau đó quay lại danh sách bằng thao tác vuốt từ cạnh trái sang phải (cử chỉ quay lại của hệ thống). Màn hình chi tiết biến mất mượt mà và danh sách hiện ra ngay, không bị nháy/giật lại khung hình chi tiết một lần trước khi về danh sách. Nhấn nút mũi tên quay lại vẫn hoạt động đúng như hiện tại.

**Why this priority**: Đây là lỗi UX trực tiếp trên luồng xem đồ dùng nhiều nhất. Cảm giác giật hình làm app kém cao cấp, người dùng lặp lại thao tác này hàng chục lần mỗi ngày.

**Independent Test**: Có thể kiểm thử độc lập chỉ với 1 món đồ: mở chi tiết → vuốt từ cạnh trái để quay lại → quan sát không còn nháy hình; nút mũi tên vẫn quay lại đúng.

**Acceptance Scenarios**:

1. **Given** người dùng đang ở màn hình chi tiết món đồ, **When** vuốt từ cạnh trái sang phải để quay lại, **Then** app quay về danh sách tủ đồ trong một chuyển động mượt, không hiển thị lại khung hình chi tiết (không nháy/giật).
2. **Given** người dùng đang ở màn hình chi tiết món đồ, **When** nhấn nút mũi tên quay lại, **Then** app quay về danh sách tủ đồ như hiện tại (không thay đổi hành vi).
3. **Given** người dùng mở chi tiết từ danh sách, **When** quay lại bằng vuốt hoặc nút back, **Then** vị trí cuộn của danh sách được giữ nguyên, ảnh thumbnail không bị đen/trống.

---

### User Story 2 - Xóa hàng loạt món đồ và outfit (Priority: P1)

Người dùng có nhiều món đồ / outfit không còn dùng, muốn chọn nhiều mục cùng lúc trong danh sách Wardrobe và danh sách Outfit để xóa một lần, có bước xác nhận rõ ràng và thông báo kết quả.

**Why this priority**: Xóa từng món một tốn nhiều thao tác, đặc biệt sau khi test/upload nhiều. Đây là nhu cầu dọn tủ đồ thường xuyên, giá trị cao và độc lập với các story khác.

**Independent Test**: Có thể kiểm thử độc lập bằng cách vào danh sách Wardrobe chọn 3 món → xóa → danh sách cập nhật; vào danh sách Outfit chọn 2 outfit → xóa → danh sách cập nhật.

**Acceptance Scenarios**:

1. **Given** người dùng đang ở danh sách Wardrobe, **When** bật chế độ chọn nhiều, tick chọn 2 món trở lên và xác nhận xóa, **Then** các món đã chọn biến mất khỏi danh sách và app hiển thị thông báo số lượng đã xóa.
2. **Given** người dùng đang ở danh sách Outfit, **When** bật chế độ chọn nhiều, tick chọn nhiều outfit và xác nhận xóa, **Then** các outfit đã chọn biến mất khỏi danh sách và app hiển thị thông báo số lượng đã xóa.
3. **Given** người dùng đã chọn nhiều mục để xóa, **When** hủy ở bước xác nhận, **Then** không mục nào bị xóa và chế độ chọn được thoát hoặc giữ nguyên lựa chọn mà không mất dữ liệu.
4. **Given** người dùng xóa hàng loạt nhưng một phần thất bại (mất mạng / lỗi máy chủ), **When** thao tác hoàn tất, **Then** app báo rõ mục nào xóa được / mục nào thất bại và danh sách hiển thị đúng trạng thái thực tế sau khi tải lại.

---

### User Story 3 - Thêm đồ từ tủ đồ hệ thống có sẵn (Priority: P2)

Người dùng chưa có ảnh chụp muốn bổ sung đồ nhanh bằng cách duyệt tủ đồ mẫu của hệ thống (catalog có sẵn), xem trước chi tiết mẫu, chọn một hoặc nhiều mẫu để thêm vào tủ đồ cá nhân mà không cần chụp/upload ảnh.

**Why this priority**: Giúp người dùng mới có tủ đồ ngay để trải nghiệm phối đồ AI, giảm phụ thuộc vào chụp ảnh. Độc lập với sửa lỗi điều hướng và xóa hàng loạt.

**Independent Test**: Có thể kiểm thử độc lập bằng cách mở lối vào "từ tủ đồ hệ thống" → duyệt danh sách mẫu → chọn 1 mẫu → xác nhận thêm → tủ cá nhân xuất hiện món mới.

**Acceptance Scenarios**:

1. **Given** người dùng đang ở trang Wardrobe, **When** chọn lối thêm đồ "Từ tủ đồ hệ thống", **Then** app mở trang danh sách mẫu của hệ thống với ảnh, tên, danh mục để duyệt.
2. **Given** người dùng đang duyệt danh sách mẫu hệ thống, **When** nhấn vào một mẫu, **Then** app hiển thị xem trước chi tiết mẫu (ảnh lớn, thuộc tính cơ bản) kèm nút thêm vào tủ.
3. **Given** người dùng đã chọn một hoặc nhiều mẫu, **When** xác nhận thêm vào tủ, **Then** các món được thêm vào tủ cá nhân, hiển thị trong danh sách Wardrobe và app báo thêm thành công.
4. **Given** người dùng thêm mẫu đã có sẵn trong tủ cá nhân, **When** xác nhận, **Then** app báo trùng và không tạo bản trùng lặp (hoặc hỏi rõ trước khi tạo thêm).

---

### User Story 4 - Đồng bộ hiển thị hạn mức AI giữa Hồ sơ cá nhân và Gói hội viên (Priority: P2)

Người dùng xem hạn mức AI ở trang Hồ sơ cá nhân thấy định dạng "đã dùng / tổng lượt" (ví dụ "0/5 lượt") cho từng loại (gợi ý phối đồ AI, tư vấn Stylist AI). Khi mở trang Gói Hội Viên & Hạn Mức, người dùng thấy cùng con số, cùng định dạng, cùng thời điểm reset, không lệch nhau.

**Why this priority**: Lệch hiển thị gây hoang mang về quyền lợi gói (tưởng bị trừ lượt sai). Sửa đồng bộ hiển thị giúp tin cậy, độc lập với các story khác.

**Independent Test**: Có thể kiểm thử độc lập bằng cách mở Hồ sơ cá nhân ghi lại 2 con số hạn mức → mở trang Gói Hội Viên & Hạn Mức → so sánh trùng khớp cả số và định dạng.

**Acceptance Scenarios**:

1. **Given** người dùng có hạn mức hôm nay (ví dụ đã dùng 0 trên tổng 5 lượt phối đồ), **When** xem trang Hồ sơ cá nhân và trang Gói Hội Viên & Hạn Mức, **Then** cả hai trang hiển thị cùng "0/5 lượt" cho cùng loại hạn mức.
2. **Given** người dùng vừa dùng 1 lượt AI, **When** quay lại xem cả hai trang (có làm mới), **Then** cả hai trang cùng cập nhật số mới (ví dụ "1/5 lượt"), không trang nào giữ số cũ.
3. **Given** người dùng mở trang Gói Hội Viên & Hạn Mức, **When** xem mỗi loại hạn mức, **Then** mỗi loại hiển thị đủ 3 thông tin: đã dùng, tổng lượt, và gợi ý số lượt còn lại hoặc thanh tiến trình nhất quán với trang Hồ sơ.

---

### Edge Cases

- Vuốt quay lại khi ảnh chi tiết đang phóng to (zoom) hoặc đang tải dở — app ưu tiên thoát zoom trước hoặc vẫn quay lại mượt, không kẹt màn hình.
- Vuốt quay lại nhiều lần liên tiếp hoặc vừa vuốt vừa nhấn nút back — chỉ quay lại một lần, không văng sang tab khác.
- Xóa hàng loạt khi danh sách trống sau khi lọc theo danh mục — nút xóa hàng loạt bị ẩn hoặc báo rõ không có mục nào để chọn.
- Xóa hàng loạt món đang ở trạng thái AI đang xử lý — app cảnh báo rõ và xử lý nhất quán (bỏ qua hoặc cho xóa kèm xác nhận).
- Thêm từ tủ hệ thống khi mất mạng giữa chừng — app giữ lựa chọn đã tick, báo lỗi và cho thử lại, không thêm trùng khi thử lại.
- Thêm từ tủ hệ thống khi tủ cá nhân đã đầy hạn mức gói (ví dụ Free 100 món) — app chặn và hướng dẫn nâng cấp hoặc xóa bớt.
- Hạn mức AI về 0 lượt còn lại — cả hai trang cùng hiển thị hết lượt và hướng dẫn chờ reset 00:00 hoặc nâng cấp gói.
- Hạn mức chưa tải được (lỗi mạng) — cả hai trang hiển thị trạng thái tải lại thay vì con số sai lệch (ví dụ không hiển thị "0/5" giả khi chưa có dữ liệu).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Thao tác quay lại bằng vuốt cạnh từ màn hình chi tiết món đồ MUST đưa người dùng về danh sách Wardrobe trong một chuyển động duy nhất, không hiển thị lại khung hình chi tiết (không nháy/giật).
- **FR-002**: Nút mũi tên quay lại trên màn hình chi tiết MUST giữ nguyên hành vi đúng hiện tại (về danh sách, giữ vị trí cuộn).
- **FR-003**: Danh sách Wardrobe sau khi quay lại từ chi tiết MUST giữ vị trí cuộn và hiển thị ảnh thumbnail đầy đủ (không đen/trống do tái sử dụng ảnh động).
- **FR-004**: Trang Wardrobe MUST có lối vào rõ ràng để thêm đồ từ tủ đồ hệ thống có sẵn, bên cạnh các lối chụp ảnh / chọn từ thư viện hiện có.
- **FR-005**: Trang tủ đồ hệ thống MUST cho phép duyệt, tìm/lọc cơ bản (ít nhất theo danh mục), xem trước chi tiết mẫu và chọn một hoặc nhiều mẫu để thêm.
- **FR-006**: Người dùng MUST xác nhận trước khi thêm mẫu hệ thống vào tủ cá nhân; sau khi thêm thành công hệ thống MUST hiển thị món mới trong tủ cá nhân và thông báo kết quả.
- **FR-007**: Hệ thống MUST ngăn tạo trùng khi thêm lại mẫu đã có trong tủ (báo trùng, không tạo bản sao ngoài ý muốn).
- **FR-008**: Danh sách Wardrobe MUST có chế độ chọn nhiều món đồ để xóa hàng loạt kèm bước xác nhận hiển thị số lượng sẽ xóa.
- **FR-009**: Danh sách Outfit MUST có chế độ chọn nhiều outfit để xóa hàng loạt kèm bước xác nhận hiển thị số lượng sẽ xóa.
- **FR-010**: Sau khi xóa hàng loạt, hệ thống MUST cập nhật danh sách, hiển thị thông báo số lượng đã xóa, và cho cách khôi phục hoặc diễn giải rõ khi xóa một phần thất bại (báo mục thành công / thất bại).
- **FR-011**: Trang Hồ sơ cá nhân và trang Gói Hội Viên & Hạn Mức MUST hiển thị cùng nguồn số liệu hạn mức AI (số đã dùng, tổng lượt cho từng loại: gợi ý phối đồ AI và tư vấn Stylist AI).
- **FR-012**: Trang Gói Hội Viên & Hạn Mức MUST hiển thị định dạng "đã dùng/tổng lượt" (ví dụ "0/5 lượt") giống trang Hồ sơ cá nhân cho mỗi loại hạn mức, kèm thông tin còn lại và thời điểm reset 00:00.
- **FR-013**: Khi hạn mức thay đổi (dùng thêm lượt AI hoặc sang ngày mới), cả hai trang MUST hiển thị cùng số mới sau khi làm mới, không lệch nhau.
- **FR-014**: Khi chưa tải được hạn mức (lỗi mạng), cả hai trang MUST hiển thị trạng thái lỗi/tải lại thay vì con số mặc định gây hiểu nhầm.

### Key Entities

- **Món đồ tủ cá nhân (Wardrobe Item)**: Trang phục trong tủ của người dùng — gồm ảnh, tên, danh mục, trạng thái, thuộc tính phân tích.
- **Mẫu hệ thống (System Catalog Item)**: Món đồ mẫu do hệ thống cung cấp sẵn — gồm ảnh, tên, danh mục, thuộc tính cơ bản; có thể được sao chép vào tủ cá nhân.
- **Outfit**: Bộ trang phục do người dùng tạo/lưu — gồm tên, ảnh bìa, danh sách món đồ thành phần, ngày tạo.
- **Hạn mức AI (AI Quota)**: Số lượt AI người dùng được dùng mỗi ngày — gồm số đã dùng và tổng lượt cho từng loại (gợi ý phối đồ, tư vấn stylist), reset lúc 00:00.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% lần vuốt cạnh để quay lại từ chi tiết về danh sách (20/20 lượt test thủ công) không còn hiện tượng nháy/giật khung hình chi tiết; nút mũi tên vẫn đúng 100%.
- **SC-002**: Người dùng xóa được 5 món đồ và 3 outfit trong vòng 1 phút bằng chế độ xóa hàng loạt, thay vì mất trên 3 phút khi xóa từng mục.
- **SC-003**: 95% lần thêm từ tủ hệ thống (19/20 lượt) hoàn tất và món mới xuất hiện trong tủ cá nhân trong vòng 10 giây sau khi xác nhận (khi mạng ổn định).
- **SC-004**: 100% lần so sánh song song hai trang (Hồ sơ cá nhân và Gói Hội Viên & Hạn Mức) hiển thị trùng khớp số đã dùng/tổng lượt và định dạng "x/y lượt" cho từng loại hạn mức.
- **SC-005**: 0 báo cáo nhầm lẫn hạn mức từ người dùng test sau khi sửa (khảo sát nhanh 5 người dùng test thủ công).
- **SC-006**: Không có hồi quy: tỷ lệ quay lại danh sách thành công (vuốt + nút back) đạt 100% và không phát sinh crash/kẹt màn hình trong 30 lượt test liên tiếp.

## Assumptions

- Cử chỉ vuốt cạnh quay lại là cử chỉ hệ thống chuẩn (iOS vuốt từ cạnh trái; Android back vật lý/cử chỉ); phạm vi sửa chỉ phía hiển thị/điều hướng của app, không đổi hành vi hệ điều hành.
- Nguyên nhân giật hình liên quan đến hiệu ứng ảnh chuyển cảnh giữa danh sách và chi tiết; hướng khắc phục do giai đoạn plan quyết định (giữ hiệu ứng mượt hoặc tắt có chọn lọc).
- Tủ đồ hệ thống có sẵn dùng được từ dữ liệu hệ thống hiện có (danh mục/món mẫu); nếu chưa có danh sách mẫu riêng, giai đoạn plan đề xuất cách tái sử dụng dữ liệu hiện có mà không cần nguồn dữ liệu mới.
- Xóa hàng loạt tái sử dụng cơ chế xóa đơn hiện có; hệ thống hỗ trợ xóa nhiều mục trong một lần thao tác, chi tiết xác nhận ở plan.
- Hạn mức AI lấy từ cùng một nguồn dữ liệu hạn mức ngày hiện tại; trang Hồ sơ hiển thị "đã dùng/tổng lượt" là chuẩn đúng cần nhân rộng sang trang Gói.
- Giới hạn tủ đồ theo gói (Free khoảng 100 món) và thời điểm reset hạn mức 00:00 giữ nguyên như hiển thị hiện tại.
- Người dùng test thủ công trên thiết bị/emulator có cử chỉ vuốt cạnh hoạt động.
