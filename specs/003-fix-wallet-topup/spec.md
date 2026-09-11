# Feature Specification: Fix Wallet Top-Up Flow

**Feature Branch**: `003-fix-wallet-topup`

**Created**: 2026-09-11

**Status**: Draft

**Input**: User description: "phần chức năng thanh toán đang có lỗi khi tui test trên emulator mô tả lỗi: test luồng nap tiền vào ví khí chọn số tiền cần nạp nhấn nạp thì chưa direct đúng qua trang hiển thị mã qr để chuyển tiền, sau đó tự báo thanh toán thành công và hiển thị vào trải nghiệm gói premium cuối dùng tui dính ở trang gói hội viên và hạn mức"

## Bối cảnh lỗi hiện tại (tóm tắt khảo sát code)

- Nút "Nạp tiền" mở sheet nhập số tiền (`TopUpBottomSheet`), gọi API tạo lệnh nạp, rồi mở trang thanh toán trong trình duyệt ngoài và chuyển sang màn hình chờ dùng chung với luồng mua Premium.
- Màn hình chờ chỉ kiểm tra trạng thái Premium (poll `isPremium`), không kiểm tra tiền có vào ví hay không; nội dung hiển thị cứng "249.000 đ / Premium (30 ngày)" bất kể số tiền nạp.
- Người dùng đã Premium (hoặc sau khi poll) thấy ngay màn hình "Chúc mừng nâng cấp Premium" dù chỉ nạp ví, rồi bị điều hướng sang trang "Gói Hội Viên & Hạn Mức" thay vì quay về ví.
- Không có màn hình mã QR trong app; đường quay về sau khi thanh toán (`returnUrl`/`cancelUrl`) không hoạt động trên Android.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Nạp ví và thấy mã QR để chuyển tiền (Priority: P1)

Người dùng có ví Closy, chọn số tiền cần nạp (ví dụ 50.000 đ), nhấn nạp và được đưa tới màn hình hiển thị mã QR / thông tin chuyển khoản đúng với số tiền đã chọn để quét và chuyển tiền.

**Why this priority**: Đây là bước đầu tiên và bắt buộc của luồng nạp tiền. Nếu người dùng không bao giờ thấy mã QR thì toàn bộ tính năng nạp ví không thể sử dụng được — đây chính là lỗi (a) người dùng báo cáo.

**Independent Test**: Có thể kiểm thử độc lập bằng cách mở ví, nhập số tiền hợp lệ, nhấn nạp và xác nhận màn hình QR hiện ra với đúng số tiền — không cần hoàn tất chuyển tiền thật.

**Acceptance Scenarios**:

1. **Given** người dùng đang ở màn hình ví với số dư hiện tại, **When** nhập số tiền hợp lệ (từ 10.000 đ trở lên) và nhấn nạp, **Then** app chuyển sang màn hình thanh toán hiển thị mã QR / thông tin chuyển khoản tương ứng với đúng số tiền đã nhập.
2. **Given** người dùng đã chọn số tiền nạp, **When** nhấn nạp nhưng tạo lệnh thanh toán thất bại (lỗi mạng / lỗi máy chủ), **Then** app ở lại màn hình nhập tiền và hiển thị thông báo lỗi dễ hiểu, không chuyển sang màn hình chờ.
3. **Given** người dùng ở màn hình mã QR, **When** quay lại (nút back), **Then** app quay về màn hình ví, lệnh nạp chưa thanh toán không làm thay đổi số dư.

---

### User Story 2 - Chỉ báo thành công khi tiền thực sự vào ví (Priority: P1)

Sau khi người dùng quét mã và chuyển tiền xong, app chỉ hiển thị "nạp thành công" khi đã xác nhận được số dư ví đã tăng / lệnh nạp đã được thanh toán. Không bao giờ tự báo thành công khi chưa có xác nhận, và không hiển thị nội dung Premium khi người dùng chỉ nạp ví.

**Why this priority**: Báo thành công giả là lỗi nghiêm trọng về niềm tin và tiền bạc — đây chính là lỗi (b) người dùng báo cáo. Quan trọng ngang P1 đầu tiên.

**Independent Test**: Có thể kiểm thử độc lập bằng cách tạo lệnh nạp nhưng chưa chuyển tiền — xác nhận app vẫn ở trạng thái "đang chờ", không hiện màn hình thành công; sau đó mô phỏng xác nhận thanh toán và kiểm tra màn hình thành công hiện ra.

**Acceptance Scenarios**:

1. **Given** người dùng đang ở màn hình chờ sau khi tạo lệnh nạp ví, **When** chưa thực hiện chuyển tiền, **Then** app tiếp tục hiển thị trạng thái đang chờ, tuyệt đối không hiển thị màn hình thành công.
2. **Given** người dùng đã chuyển tiền thành công, **When** hệ thống xác nhận lệnh nạp đã thanh toán và số dư ví đã tăng, **Then** app hiển thị màn hình thành công với đúng số tiền đã nạp (không phải 249.000 đ, không nhắc tới Premium).
3. **Given** người dùng Free (chưa Premium) nạp ví, **When** nạp thành công, **Then** app không hiển thị bất kỳ nội dung "nâng cấp Premium" nào.
4. **Given** người dùng đang chờ thanh toán quá thời gian quy định mà chưa thanh toán, **When** hết thời gian chờ, **Then** app hiển thị thông báo hết hạn / thất bại rõ ràng thay vì đứng yên ở màn hình chờ.

---

### User Story 3 - Sau nạp ví quay về ví đúng số dư, không kẹt ở trang gói (Priority: P2)

Sau khi nạp ví thành công, người dùng được đưa về màn hình ví với số dư đã cập nhật. Luồng mua Premium giữ nguyên hành vi cũ (về trang gói hội viên sau khi nâng cấp).

**Why this priority**: Khắc phục lỗi (c) — người dùng nạp ví xong bị "dính" ở trang Gói Hội Viên & Hạn Mức không liên quan, gây bối rối và không thấy được tiền vừa nạp.

**Independent Test**: Có thể kiểm thử độc lập bằng cách hoàn tất một lệnh nạp ví và xác nhận màn hình đích là ví với số dư mới; riêng luồng mua Premium vẫn về trang gói như cũ.

**Acceptance Scenarios**:

1. **Given** lệnh nạp ví vừa được xác nhận thành công, **When** người dùng nhấn nút tiếp tục trên màn hình thành công, **Then** app chuyển về màn hình ví và số dư hiển thị đã bao gồm số tiền vừa nạp.
2. **Given** người dùng mua gói Premium (không phải nạp ví), **When** thanh toán thành công, **Then** hành vi giữ nguyên như hiện tại — về trang Gói Hội Viên & Hạn Mức.
3. **Given** người dùng đang ở màn hình chờ của luồng nạp ví, **When** rời khỏi màn hình chờ, **Then** app quay về màn hình ví (không phải trang gói).

---

### Edge Cases

- Người dùng nhập số tiền dưới mức tối thiểu (10.000 đ), số tiền bằng 0, số tiền âm, hoặc để trống — app từ chối và báo rõ lý do, không tạo lệnh thanh toán.
- Người dùng nhập số tiền có dấu phân tách hàng nghìn (ví dụ "100.000") — app hiểu đúng là một trăm nghìn, không hiểu nhầm thành 100.
- Người dùng tạo lệnh nạp nhưng không thanh toán rồi thoát app, mở lại sau — số dư ví không đổi, không có thông báo thành công treo.
- Mất mạng giữa lúc chờ xác nhận thanh toán — app hiển thị trạng thái lỗi mạng và cho thử lại việc kiểm tra, không báo thành công cũng không mất lệnh.
- Lệnh nạp hết hạn thanh toán phía ngân hàng — app hiển thị hết hạn và cho tạo lệnh mới.
- Người dùng đã Premium nạp thêm ví — không hiện lại màn hình chào mừng Premium, chỉ báo nạp ví thành công.
- Nhấn nạp nhiều lần liên tiếp (double-tap) — chỉ tạo một lệnh thanh toán duy nhất.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Sau khi người dùng xác nhận số tiền nạp hợp lệ, hệ thống MUST chuyển tới màn hình thanh toán hiển thị mã QR / thông tin chuyển khoản tương ứng với đúng số tiền và đúng lệnh nạp vừa tạo.
- **FR-002**: Màn hình thanh toán của luồng nạp ví MUST hiển thị đúng số tiền người dùng đã chọn (không hiển thị số tiền cố định của gói Premium).
- **FR-003**: Hệ thống MUST chỉ hiển thị trạng thái "nạp thành công" khi đã xác nhận được lệnh nạp đã thanh toán và/hoặc số dư ví đã tăng; không được suy ra thành công từ trạng thái Premium hay bất kỳ trạng thái không liên quan nào.
- **FR-004**: Màn hình chờ của luồng nạp ví MUST kiểm tra trạng thái của chính lệnh nạp ví (không dùng chung logic kiểm tra Premium của luồng mua gói).
- **FR-005**: Sau khi nạp ví thành công, hệ thống MUST điều hướng người dùng về màn hình ví với số dư đã cập nhật; luồng mua Premium giữ nguyên điểm đến là trang Gói Hội Viên & Hạn Mức.
- **FR-006**: Khi hết thời gian chờ mà chưa thanh toán, hệ thống MUST hiển thị thông báo hết hạn/thất bại rõ ràng và hướng xử lý tiếp theo (tạo lệnh mới / quay về ví).
- **FR-007**: Khi tạo lệnh nạp thất bại (lỗi mạng, lỗi máy chủ), hệ thống MUST ở lại màn hình nhập tiền và hiển thị thông báo lỗi, không chuyển sang màn hình chờ.
- **FR-008**: Số tiền tối thiểu cho mỗi lần nạp là 10.000 đ; hệ thống MUST từ chối các giá trị nhỏ hơn, bằng 0, âm hoặc trống kèm thông báo rõ ràng.
- **FR-009**: Hệ thống MUST diễn giải đúng số tiền người dùng nhập kể cả khi có dấu phân tách hàng nghìn (ví dụ "100.000" = 100000 đ) một cách nhất quán giữa hiển thị gợi ý và giá trị thực tế tạo lệnh.
- **FR-010**: Nhấn nút nạp nhiều lần liên tiếp MUST chỉ tạo một lệnh thanh toán duy nhất (chống double-submit).
- **FR-011**: Sau khi thanh toán xong bên ngoài app (trình duyệt / app ngân hàng), người dùng quay về app bằng nút "Tôi đã chuyển tiền — Kiểm tra kết quả" trên màn hình chờ, hoặc hệ thống tự kiểm tra lại khi người dùng mở lại app (resume). (Quyết định tại plan: deep-link tự động dời sang giai đoạn sau vì cần sửa native.)
- **FR-012**: Màn hình thanh toán nạp ví hiển thị mã QR ngay trong app (mã hóa đường dẫn thanh toán của lệnh nạp), kèm nút dự phòng "Mở trang thanh toán" trong trình duyệt ngoài.
- **FR-013**: Việc xác nhận lệnh nạp đã thanh toán dựa trên kết hợp cả hai: chụp số dư ví trước khi tạo lệnh và poll kiểm tra số dư tăng đúng số tiền nạp, đối chiếu chéo với lịch sử giao dịch ví (không cần API backend mới).

### Key Entities

- **Lệnh nạp ví (Wallet Top-Up Order)**: Yêu cầu nạp tiền vào ví — gồm số tiền, mã đơn hàng, trạng thái (chờ thanh toán / thành công / hết hạn / thất bại), thời gian hết hạn.
- **Thông tin thanh toán (Payment Link)**: Dữ liệu để người dùng chuyển tiền — gồm đường dẫn/mã thanh toán, mã đơn hàng, số tiền, thời gian hết hạn.
- **Số dư ví (Wallet Balance)**: Số tiền hiện có trong ví của người dùng — tăng lên đúng bằng số tiền nạp khi lệnh được xác nhận thành công.
- **Trạng thái hội viên (Membership Status)**: Gói Free/Premium và hạn mức sử dụng — độc lập với số dư ví, không được dùng để suy ra kết quả nạp ví.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% lần nhấn nạp với số tiền hợp lệ đưa người dùng tới màn hình thanh toán hiển thị đúng số tiền đã chọn (kiểm thử 20/20 lượt trên emulator).
- **SC-002**: 0 trường hợp báo "nạp thành công" khi lệnh nạp chưa được xác nhận thanh toán (kiểm thử các kịch bản: chưa chuyển tiền, mất mạng giữa chừng, lệnh hết hạn).
- **SC-003**: 100% luồng nạp ví thành công kết thúc tại màn hình ví với số dư cập nhật đúng; 0 trường hợp lạc sang trang Gói Hội Viên & Hạn Mức.
- **SC-004**: Người dùng hoàn tất toàn bộ luồng nạp ví (chọn tiền → quét QR → xác nhận thành công → về ví) trong vòng 3 phút khi thanh toán suôn sẻ.
- **SC-005**: Luồng mua Premium hiện tại không bị ảnh hưởng (hồi quy): mua gói thành công vẫn về trang Gói Hội Viên & Hạn Mức như cũ.

## Assumptions

- Cổng thanh toán / API tạo lệnh nạp ví của backend (`POST /subscriptions/me/wallet/topup`) hoạt động đúng và trả về thông tin thanh toán hợp lệ — phạm vi spec này chỉ sửa phía mobile.
- Backend có cách để mobile xác nhận trạng thái lệnh nạp (truy vấn theo mã đơn hàng hoặc số dư ví cập nhật) — chi tiết do backend cung cấp trong giai đoạn plan.
- Số tiền nạp tối thiểu 10.000 đ giữ nguyên theo logic hiện tại của app.
- Luồng mua Premium trực tiếp và mua bằng ví không thuộc phạm vi sửa, chỉ kiểm thử hồi quy.
- Người dùng test trên Android emulator có trình duyệt ngoài để mở trang thanh toán khi cần.
