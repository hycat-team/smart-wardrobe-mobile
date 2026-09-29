# Feature Specification: Wardrobe Default Landing, Studio Canvas Presentation & AI Analysis Status Handling

**Feature Branch**: `013-wardrobe-studio-status-handling`

**Created**: 2026-09-28

**Status**: Draft

**Input**: User description: "sau khi đăng nhập (Web và Android), trang đầu tiên người dùng tới là wardrobe; sau khi phối outfit thành công không cần hiện thông báo ở góc dưới màng hình; tham khảo source D:\_HYCAT\smart-wardrobe-fe và xem cách trình bày của quần áo sau khi bấm xem trên studio (canvas) để quần áo không chồng chéo lên nhau và nằm giữa màng hình theo đúng thứ tự và áp dụng cho mobile hiện tại; đọc D:\_HYCAT\smart-wardrobe-be\specs\023-analyze-status-handling và áp dụng luồng này vào mobile (xử lí lỗi ảnh)"

## Clarifications

### Session 2026-09-28

- Q: Lưu outfit thành công thì chuyển hướng về màn hình nào? (US4 mô tả ghi 'danh sách bộ đồ hoặc tủ đồ', còn AC1 ghi 'bộ sưu tập trang phục') → A: Danh sách bộ đồ.
- Q: Điểm đến mặc định Wardrobe sau đăng nhập áp dụng cho nền tảng nào? (Input gốc ghi 'trang web', nhưng story/AC viết chung chung) → A: Mọi nền tảng.
- Q: Outfit dạng INCOMPLETE (thiếu vai trò cốt lõi) hiển thị trên canvas thế nào? (Entities có nhắc nhưng chưa định nghĩa hành vi) → A: Như SEPARATE_PIECES.
- Q: Món đồ đang ở trạng thái processing xuất hiện trong ngăn kéo Studio (chọn đồ phối) thế nào? (AC mới chỉ khóa thao tác ở tủ đồ/chi tiết) → A: Hiện nhưng khóa.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Tủ đồ cá nhân là điểm đến mặc định ngay sau khi đăng nhập (Priority: P1)

Người dùng khởi chạy ứng dụng hoặc hoàn tất quá trình đăng nhập tài khoản (bằng mật khẩu hoặc Google). Thay vì chuyển hướng vào bảng tin cộng đồng hay trang chủ chung, ứng dụng đưa người dùng trực tiếp vào màn hình "Tủ Đồ" (Wardrobe) cá nhân của họ để họ tiếp cận ngay tài sản thời trang số hóa của mình.

**Why this priority**: Tủ đồ cá nhân là giá trị cốt lõi (Core Utility) của ứng dụng ClosY. Đưa người dùng thẳng vào tủ đồ giúp họ kiểm tra trang phục, nạp đồ mới hoặc bắt đầu phối đồ ngay lập tức mà không phải tốn thêm thao tác chuyển tab.

**Independent Test**: Đăng xuất tài khoản → Thực hiện đăng nhập → Xác nhận ứng dụng chuyển thẳng vào tab Tủ Đồ (`/wardrobe`), thanh điều hướng làm nổi bật biểu tượng Tủ Đồ và hiển thị danh sách trang phục của người dùng.

**Acceptance Scenarios**:

1. **Given** Người dùng chưa đăng nhập ở màn hình xác thực, **When** đăng nhập thành công bằng tài khoản và mật khẩu, **Then** hệ thống điều hướng trực tiếp vào màn hình Tủ Đồ cá nhân.
2. **Given** Người dùng đăng nhập qua tài khoản Google, **When** xác thực thành công, **Then** hệ thống chuyển thẳng vào Tủ Đồ cá nhân.
3. **Given** Người dùng có phiên đăng nhập hợp lệ còn lưu trên thiết bị khi mở lại ứng dụng, **When** ứng dụng tải xong dữ liệu xác thực, **Then** đích đến mặc định là màn hình Tủ Đồ.
4. **Given** Người dùng nhấn vào một liên kết sâu (deep-link) cụ thể (ví dụ xem chi tiết một bài viết hoặc sản phẩm) khi chưa đăng nhập, **When** đăng nhập thành công, **Then** hệ thống vẫn ưu tiên chuyển tiếp đến liên kết đích đó; nếu không có liên kết chờ thì mặc định về Tủ Đồ.

---

### User Story 2 - Xử lý thông minh trạng thái phân tích ảnh AI & khắc phục lỗi ảnh (Priority: P1)

Người dùng tải ảnh quần áo lên tủ đồ cá nhân. Quá trình phân tích AI có thể thành công, gặp ảnh chưa rõ danh mục, hoặc gặp ảnh không hợp lệ/lỗi hệ thống. Ứng dụng cung cấp phản hồi trực quan theo đúng chuẩn hệ thống phân tích hình ảnh:
- Trạng thái đang phân tích: hiển thị huy hiệu và tiến trình chờ mà không cho phép thao tác thử lại sớm.
- Trạng thái cần rà soát danh mục (`needs_review` / `uncertain_category`): thông báo rõ ràng AI chưa chắc chắn phân loại; cho phép người dùng chọn danh mục chuẩn và gửi yêu cầu phân tích lại kèm danh mục cố định.
- Trạng thái ảnh không hợp lệ (`multiple_items_detected` / `full_body_outfit_detected`): hiển thị lý do rõ ràng (ảnh có nhiều món hoặc ảnh chụp toàn thân), ẩn nút thử lại vì phân tích lại cùng ảnh sẽ bị từ chối, hướng dẫn người dùng tải ảnh chụp cận cảnh một món đồ khác.
- Trạng thái lỗi kỹ thuật tạm thời (`analysis_temporary_error` / `auto_retry_exceeded`): cung cấp nút "Thử lại" để tái kích hoạt phân tích ngay trên món đồ đó mà không bắt người dùng phải chụp lại ảnh từ đầu.

**Why this priority**: Khâu nạp đồ và nhận diện AI là điểm chạm đầu tiên quyết định chất lượng dữ liệu tủ đồ. Thiếu cơ chế xử lý chi tiết theo mã lỗi sẽ dẫn đến trải nghiệm bế tắc: người dùng không biết vì sao ảnh lỗi, hoặc bấm thử lại vô ích với ảnh chụp toàn thân/đa món.

**Independent Test**: 
- Nạp ảnh có nhiều món đồ: xác nhận xuất hiện thẻ trạng thái lỗi với thông điệp "Ảnh có nhiều món đồ", không có nút thử lại, có nút xóa hoặc gợi ý tải ảnh khác.
- Nạp ảnh đơn món nhưng AI chưa rõ loại: xác nhận thẻ hiển thị "Cần chọn danh mục", người dùng chọn danh mục (ví dụ "Áo") và bấm gửi lại thì món đồ chuyển về trạng thái đang phân tích và cập nhật hoàn tất khi AI xử lý xong.

**Acceptance Scenarios**:

1. **Given** Món đồ đang trong quá trình AI phân tích (`processing`), **When** người dùng xem trong tủ đồ hoặc trang chi tiết, **Then** hệ thống hiển thị trạng thái "Đang phân tích", tạm khóa các thao tác phối đồ và ẩn nút thử lại.
2. **Given** Món đồ nhận kết quả cần rà soát do AI không chắc chắn danh mục (`uncertain_category`), **When** người dùng mở chi tiết món đồ, **Then** hệ thống hiển thị thông báo yêu cầu chọn danh mục, hiển thị danh sách các nhóm danh mục hợp lệ và kích hoạt nút gửi phân tích lại khi danh mục đã được chọn.
3. **Given** Món đồ gặp lỗi do ảnh chụp toàn thân hoặc nhiều món (`full_body_outfit_detected`, `multiple_items_detected`), **When** người dùng xem món đồ, **Then** hệ thống hiển thị nhãn lỗi và câu khuyến nghị "Vui lòng chụp cận cảnh một món đồ duy nhất", tuyệt đối không hiển thị nút "Thử lại".
4. **Given** Món đồ gặp lỗi gián đoạn mạng hoặc dịch vụ AI tạm thời (`analysis_temporary_error`, `auto_retry_exceeded`), **When** người dùng xem món đồ, **Then** hệ thống hiển thị nút "Thử lại", khi người dùng nhấn vào thì hệ thống gửi yêu cầu phân tích lại và theo dõi tiến trình thời gian thực.
5. **Given** Kênh sự kiện thời gian thực bị ngắt kết nối mạng, **When** người dùng quay lại màn hình tủ đồ hoặc kết nối mạng phục hồi, **Then** hệ thống tự động làm mới trạng thái món đồ từ máy chủ mà không bị kẹt ở trạng thái đang xử lý.
6. **Given** Món đồ đang ở trạng thái Đang xử lý (`processing`), **When** người dùng mở ngăn kéo Studio để chọn đồ phối, **Then** món đồ hiển thị mờ kèm huy hiệu "Đang phân tích" và không thể chọn đưa lên canvas.

---

### User Story 3 - Trình bày bộ phối trên Studio Canvas chuẩn giải phẫu, không chồng lấn và nằm gọn giữa màn hình (Priority: P1)

Người dùng mở một bộ outfit trên nền vẽ Studio (từ gợi ý của AI Stylist hoặc bằng nút "Mở Trên Studio" từ danh sách bộ đồ đã lưu). Các món đồ trong set trang phục xuất hiện tự nhiên theo cấu trúc giải phẫu cơ thể người (mũ ở trên đầu, áo khoác phủ ngoài áo trong, áo nằm trên quần/váy, giày ở dưới cùng, phụ kiện dàn sang hai bên). Mỗi món đồ có tỷ lệ khung hình cân xứng thực tế (quần dáng dọc dài, giày dép dáng ngang vừa vặn), không bị co kéo thành hình vuông thô ráp. Toàn bộ set đồ tự động căn giữa khung nhìn canvas của thiết bị di động, không bị đè che khuất nhau và có thứ tự lớp hiển thị (layering/z-index) trực quan.

**Why this priority**: Canvas Studio là không gian trực quan hóa phong cách của ClosY. Trải nghiệm trước đây khiến các item dạng hình vuông 200x200 bị chồng đống lên nhau hoặc lệch ra ngoài khung viền di động, buộc người dùng phải kéo thả chỉnh tay phức tạp. Bố cục tự động giải phẫu chuẩn như trên Web FE đem lại trải nghiệm cao cấp (Quiet Luxury), chỉn chu ngay từ cái nhìn đầu tiên.

**Independent Test**: Chọn một bộ trang phục gồm Áo khoác + Áo thun + Quần dài + Giày dép + Túi xách/Kính mắt → Mở trên Studio Canvas → Xác nhận:
- Áo thun ở phía trên, quần ở phía dưới, giày ở đáy canvas.
- Áo khoác nằm ở vị trí ngực-vai và hiển thị đè lên trên áo thun (đúng lớp thị giác).
- Quần dài có khung hình dọc cân đối, giày dép có khung hình gọn gàng không bị kéo dãn hình vuông.
- Phụ kiện tự động bố trí lệch ra cánh bên cạnh, không chắn giữa ngực áo hay mặt quần.
- Toàn bộ bộ đồ nằm gọn giữa canvas màn hình điện thoại mà không cần kéo thu nhỏ hay dịch chuyển thủ công.

**Acceptance Scenarios**:

1. **Given** Một bộ trang phục có các món đồ rời (Áo, Quần, Giày), **When** nạp lên Studio Canvas, **Then** áo được định vị ở thân trên, quần ở thân dưới, giày ở đáy canvas theo trục dọc cân đối.
2. **Given** Một bộ trang phục có Đầm/Váy liền thân (Fullbody) kết hợp Giày dép và Áo khoác, **When** hiển thị trên Canvas, **Then** đầm liền thân chiếm vị trí trung tâm dọc thân người, áo khoác phủ bên ngoài ở lớp trên, giày ở phía dưới.
3. **Given** Bộ trang phục có Áo khoác ngoài (Outerwear) và Áo trong (Top), **When** hiển thị trên Canvas, **Then** Áo khoác có thứ tự lớp cao hơn Áo trong (nằm đè lên áo trong), tạo cảm giác mặc ngoài thực tế.
4. **Given** Bộ trang phục có nhiều phụ kiện (ví dụ kính mắt, túi xách), **When** hiển thị trên Canvas, **Then** phụ kiện đầu tiên nằm ở một bên hông/vai, các phụ kiện tiếp theo tự động so le ở cánh đối diện, không che khuất trục trang phục chính.
5. **Given** Người dùng mở một bộ outfit đã lưu từ trước trên thiết bị di động có tỷ lệ màn hình khác, **When** Canvas dựng các món đồ, **Then** toàn bộ nhóm item được thu phóng và căn đều vào chính giữa màn hình với lề an toàn tối thiểu, ngăn tràn biên canvas.
6. **Given** Người dùng muốn tùy chỉnh thêm bằng tay, **When** chạm, phóng to/thu nhỏ, đưa lên trên hoặc di chuyển món đồ, **Then** hệ thống hỗ trợ mượt mà và lưu lại đúng tọa độ mới.

---

### User Story 4 - Tối giản trải nghiệm phản hồi sau khi phối đồ và lưu outfit thành công (Priority: P2)

Khi người dùng hoàn tất việc phối trang phục trên Canvas và nhấn "Lưu Trang Phục", hệ thống tiến hành lưu bộ đồ vào tài khoản và tự động chuyển hướng người dùng đến màn hình danh sách bộ đồ một cách êm ái, mượt mà. Ứng dụng không bật thanh thông báo (Snackbar) màu cam/xanh chiếm diện tích ở đáy màn hình như trước.

**Why this priority**: Thiết kế Quiet Luxury đề cao sự tinh tế, điềm tĩnh và tối giản phiền nhiễu (non-intrusive). Hành động chuyển hướng sang danh sách bộ đồ cùng với sự xuất hiện ngay tức thì của bộ đồ mới đã là tín hiệu thành công tự nhiên và rõ ràng nhất, không cần biểu ngữ thông báo đập vào mắt người dùng.

**Independent Test**: Nhấn nút "Lưu" một bộ trang phục trên Canvas → Xác nhận giao diện lưu thành công, chuyển hướng về danh sách bộ đồ ngay lập tức mà không có thanh SnackBar nào hiện lên ở đáy màn hình.

**Acceptance Scenarios**:

1. **Given** Người dùng đang ở màn hình Studio Canvas với các món đồ hợp lệ, **When** nhấn nút xác nhận lưu outfit thành công, **Then** hệ thống lưu dữ liệu, chuyển hướng về màn hình bộ sưu tập trang phục và không kích hoạt bất kỳ SnackBar thông báo thành công nào ở đáy màn hình.
2. **Given** Người dùng đang lưu bộ đồ AI gợi ý trực tiếp từ tab AI Stylist, **When** lưu thành công, **Then** hệ thống chuyển hướng mượt mà và không bật thông báo SnackBar thành công ở góc dưới màn hình.
3. **Given** Thao tác lưu thất bại do lỗi mạng hoặc mất kết nối máy chủ, **When** xảy ra lỗi, **Then** hệ thống vẫn hiển thị thông báo lỗi rõ ràng để người dùng nhận biết và thử lại.

---

### Edge Cases

- **Món đồ có dữ liệu vị trí cũ bị ngược trục Y (lỗi dấu âm/dương legacy)**: Khi nạp outfit cũ từng lưu tọa độ thân trên mang giá trị dương, hệ thống tự động nhận diện vai trò thân trên (mũ, áo, áo khoác) và đảo dấu trục Y để món đồ không bị bay tụt xuống chân.
- **Outfit chỉ có đúng 1 món duy nhất**: Hệ thống tự động đặt món đồ đó vào chính giữa tâm canvas với tỷ lệ tiêu chuẩn, không bị lệch góc hay chơ vơ ngoài biên.
- **Ảnh phân tích AI trả về mã lý do mới chưa có trong danh mục định sẵn**: Hệ thống hiển thị thông điệp dự phòng thân thiện ("Không thể phân tích trang phục, vui lòng thử lại hoặc tải ảnh khác") thay vì để trống giao diện.
- **Người dùng bấm liên tục nút Thử lại (Double-tap)**: Hệ thống khóa nút ngay khi lệnh thử lại đầu tiên được gửi đi để tránh sinh nhiều phiên tác vụ trùng lặp trên máy chủ.
- **Kích thước màn hình điện thoại rất nhỏ (màn hình hẹp/ngắn)**: Hệ thống tự động áp dụng hệ số co giãn tổng thể (Canvas scale multiplier) để toàn bộ bộ đồ co nhỏ lại vừa vặn trong khung nhìn mà các món vẫn giữ nguyên khoảng cách tương đối.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Hệ thống MUST đặt điểm đến mặc định là màn hình Tủ Đồ (`/wardrobe`) ngay sau khi người dùng đăng nhập thành công qua mật khẩu, Google hoặc khi khôi phục phiên đăng nhập từ trạng thái đã xác thực.
- **FR-002**: Nếu người dùng đang có một liên kết điều hướng chờ (pending redirect) hợp lệ trước khi đăng nhập, hệ thống MUST ưu tiên chuyển tới trang đích đó; chỉ khi không có đích chờ mới chuyển về Tủ Đồ.
- **FR-003**: Hệ thống MUST loại bỏ hoàn toàn thông báo thành công dạng biểu ngữ đáy màn hình (Bottom SnackBar) sau khi người dùng lưu bộ trang phục thành công từ Studio Canvas hoặc từ gợi ý AI.
- **FR-004**: Khi lưu bộ trang phục thất bại, hệ thống MUST tiếp tục hiển thị thông báo lỗi cụ thể để người dùng biết nguyên nhân và không tự ý đóng giao diện chỉnh sửa.
- **FR-005**: Khi hiển thị trang phục trên Studio Canvas, hệ thống MUST áp dụng mô hình định vị giải phẫu cơ thể học tương thích với chuẩn giao diện Web (`smart-wardrobe-fe`), gồm 2 chế độ: Đồ rời (`SEPARATE_PIECES`) và Liền thân (`FULLBODY`).
- **FR-006**: Tọa độ giải phẫu chuẩn của các vai trò thời trang MUST tuân theo quy tắc: Mũ/Nón ở đỉnh đầu, Áo ở thân trên, Quần/Váy ở thân dưới, Giày dép ở đáy canvas, Đầm liền thân ở trục trung tâm thân, Áo khoác phủ ngực-vai với độ lệch nhẹ tự nhiên.
- **FR-007**: Hệ thống MUST định dạng kích thước khung bao (Bounding Box) theo tỷ lệ đặc trưng từng vai trò trang phục — Áo 2.1×2.1, Áo khoác 2.3×2.3, Quần/Váy 1.9×2.3, Đầm 2.1×3.2, Giày 1.8×1.3, Mũ 1.8×1.4, Phụ kiện 1.6×1.6, Mục khác 2.0×2.0 (kích thước hiển thị = `placement.scale × tỷ lệ`) — thay vì dùng khung vuông đồng nhất cho mọi món đồ.
- **FR-008**: Các món đồ hiển thị trên Canvas MUST tuân thủ thứ tự lớp hiển thị (Z-Index/Layer): Phụ kiện (z=9) > Mũ (z=8) > Áo khoác (z=7) > Áo/Đầm (z=5) > Quần/Chân váy (z=4) > Giày dép (z=3) > Mục khác (z=2).
- **FR-009**: Khi bộ trang phục có nhiều hơn 1 phụ kiện, hệ thống MUST tự động bố trí phụ kiện thứ hai trở đi so le sang cánh đối diện của canvas để không đè lên phụ kiện thứ nhất hay trang phục chính.
- **FR-010**: Khi bộ trang phục chứa đầm liền thân (`fullbody`), hệ thống MUST tự động loại trừ hoặc ẩn áo rời (`top`) và quần rời (`bottom`) trùng lặp để tránh xung đột bố cục.
- **FR-011**: Toàn bộ các món đồ sau khi áp dụng tọa độ giải phẫu MUST được căn chỉnh tự động vào chính giữa khung nhìn Canvas di động, kẹp biên trong phạm vi an toàn để không bị khuất ra ngoài màn hình.
- **FR-012**: Hệ thống MUST hỗ trợ 4 trạng thái phân tích hình ảnh AI cho món đồ trong tủ đồ: Đang xử lý (`processing` - status 3), Hoàn tất khả dụng (`completed` / `inWardrobe` - status 0), Lỗi phân tích (`failed` - status 4), Cần rà soát danh mục (`needs_review` / `needsReview` - status 5).
- **FR-013**: Khi món đồ ở trạng thái Cần rà soát (`needsReview` với lý do `uncertain_category`), giao diện MUST yêu cầu người dùng chọn một danh mục hợp lệ từ danh sách hệ thống và cung cấp nút gửi phân tích lại kèm mã danh mục đã chọn.
- **FR-014**: Khi người dùng gửi yêu cầu rà soát danh mục cho món `needsReview`, hệ thống MUST gọi API phân tích lại (`POST /wardrobe-items/{id}/retry-analysis`) kèm thông tin danh mục, nhận mã tác vụ mới và chuyển món đồ sang trạng thái Đang xử lý (`processing`). Hệ thống MUST NOT gọi tới API cũ đã bị gỡ bỏ (`confirm-review`).
- **FR-015**: Khi món đồ ở trạng thái Lỗi (`failed`), hệ thống MUST kiểm tra mã lý do lỗi (từ dữ liệu phân tích):
  - Nếu mã lý do là ảnh không hợp lệ (`multiple_items_detected` hoặc `full_body_outfit_detected`), hệ thống MUST hiển thị hướng dẫn người dùng chụp lại ảnh cận cảnh một món đồ và MUST ẩn nút Thử lại.
  - Nếu mã lý do là lỗi hệ thống tạm thời (`analysis_temporary_error` hoặc `auto_retry_exceeded`), hệ thống MUST hiển thị nút "Thử lại", cho phép gửi yêu cầu phân tích lại mà không cần chụp lại ảnh.
- **FR-016**: Khi kết nối thời gian thực (SSE) nhận được sự kiện cập nhật trạng thái phân tích, hệ thống MUST cập nhật ngay món đồ tương ứng trong danh sách mà không cần tải lại toàn bộ trang tủ đồ.
- **FR-017**: Nếu kết nối thời gian thực bị gián đoạn, hệ thống MUST có cơ chế tự động đồng bộ lại trạng thái từ máy chủ khi người dùng kéo làm mới hoặc mở lại màn hình tủ đồ.

### Key Entities

- **Món Đồ Tủ Cá Nhân (Wardrobe Item)**: Món trang phục của người dùng, gồm mã định danh, trạng thái nghiệp vụ (khả dụng, đang xử lý, lỗi, cần rà soát), ảnh hiển thị, danh mục thời trang và thuộc tính phân tích AI.
- **Dữ Liệu Phân Tích Thời Trang (Fashion Item Analysis)**: Metadata do AI tạo ra, chứa thông tin màu sắc, phong cách, chất liệu, mã lý do cần rà soát (`reviewReason`) hoặc mã lý do lỗi xử lý (`processingErrorReason`).
- **Phần Tử Canvas Studio (Studio Canvas Item)**: Món đồ đặt trên bảng vẽ canvas, gồm mã sản phẩm, liên kết ảnh, vai trò thời trang (`FashionRole`), tọa độ vị trí (X, Y), tỷ lệ thu phóng (Scale), kích thước khung bao (Width, Height) và thứ tự lớp hiển thị (Z-Index/LayerOrder).
- **Cấu Trúc Phối Trang Phục (Outfit Composition)**: Dạng tổng thể của set đồ, phân loại thành Đồ rời (`SEPARATE_PIECES`), Liền thân (`FULLBODY`), hoặc Chưa hoàn chỉnh (`INCOMPLETE` — được dựng như `SEPARATE_PIECES` với các vai trò hiện có).
- **Mã Lý Do Lỗi/Rà Soát (Reason Code)**: Mã định danh chuẩn kỹ thuật từ máy chủ AI (`uncertain_category`, `multiple_items_detected`, `full_body_outfit_detected`, `analysis_temporary_error`, `auto_retry_exceeded`).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% người dùng sau khi đăng nhập thành công được chuyển hướng ngay đến màn hình Tủ Đồ cá nhân trong **≤300ms, đo bằng `Stopwatch` từ lúc `login`/`completeWebSession` trả về tới khi `GoRouter` đã điều hướng xong, trong phiên đã warm (không tính cold start / build route lần đầu trên Web)**.
- **SC-002**: 100% các lần lưu bộ trang phục thành công không còn hiển thị biểu ngữ SnackBar ở đáy màn hình; thời gian chuyển hướng sang danh sách bộ đồ **≤500ms, đo từ lúc `saveOutfit` trả về thành công tới khi màn `/outfits` đã dựng khung (không tính thời gian fetch danh sách)**.
- **SC-003**: 100% các bộ outfit mở trên Canvas (cả từ AI Stylist và từ Outfit đã lưu) có các món phân bổ đúng vị trí giải phẫu (áo trên, quần dưới, giày đáy, áo khoác phủ ngoài), không có hiện tượng chồng đè lên nhau ở tâm màn hình.
- **SC-004**: 100% các món đồ trên Canvas hiển thị đúng tỷ lệ khung hình giải phẫu (quần dài dáng dọc, giày dép dáng ngang) và toàn bộ set đồ nằm gọn trong khung nhìn hiển thị của mọi kích thước màn hình điện thoại được hỗ trợ.
- **SC-005**: 100% các món đồ bị lỗi ảnh không hợp lệ (`multiple_items_detected` / `full_body_outfit_detected`) không hiển thị nút "Thử lại", loại bỏ hoàn toàn các lượt gửi retry vô ích gây lỗi 400 từ máy chủ.
- **SC-006**: 100% các món đồ cần chọn danh mục (`uncertain_category`) hỗ trợ người dùng chọn danh mục và kích hoạt phân tích lại thành công qua `retry-analysis`, chuyển đổi trạng thái mượt mà sang hoàn tất khi AI phân tích xong.
- **SC-007**: 0 cảnh báo phân tích tĩnh (`flutter analyze` đạt 0 issues) và toàn bộ các bộ kiểm thử tự động liên quan đều vượt qua thành công.

## Assumptions

- Điểm đến mặc định Wardrobe áp dụng đồng nhất trên Web và Android (kể cả khôi phục phiên), thay thế default Community của spec 012 (`kPostLoginRoute` → `/wardrobe`).
- Phía máy chủ Backend đã triển khai đầy đủ hợp đồng API theo đặc tả `023-analyze-status-handling` (hỗ trợ `POST /wardrobe-items/{id}/retry-analysis` với body `{ categoryId }`, mã lý do nằm trong `fashionItem.reviewReason` hoặc `fashionItem.processingErrorReason`, không còn hỗ trợ `confirm-review`).
- Màn hình Canvas Studio trên thiết bị di động có chiều cao vùng hiển thị trung bình từ 450px đến 650px tùy kích thước màn hình; việc thu phóng tọa độ sẽ tự động tương thích với kích cỡ thực tế của khung vẽ qua tỷ lệ canvas.
- Danh sách các nhóm danh mục hợp lệ đã có sẵn trong ứng dụng qua `CategoryModel` và hệ thống danh mục chuẩn của ClosY.
- Việc ẩn biểu ngữ SnackBar thành công chỉ áp dụng cho trường hợp phối/lưu outfit thành công; các thao tác khác hoặc thông báo lỗi vẫn tuân thủ phản hồi trực quan theo tiêu chuẩn của hệ thống.
