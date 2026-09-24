# Feature Specification: Web Payment Redirect

**Feature Branch**: `009-web-payment-redirect`

**Created**: 2026-09-24

**Status**: Draft

**Input**: User description: "thay đổi luồng payment trên mobile theo hướng là vẫn hiển thị các gói cho người dùng nhưng khi thanh toán thì sẽ yêu cầu người dùng lên website đăng nhập để thanh toán cũng như nạp tiền vào ví để tránh việc duyệt của google play"

## Clarifications

### Session 2026-09-24

- Q: Khi người dùng bấm mua gói / nạp ví trên mobile, app nên đưa họ lên website bằng cách nào? → A: Chỉ hiện hướng dẫn tự mở (hiển thị địa chỉ website + các bước, không có nút mở link).
- Q: Màn hình gói trên mobile có nên tiếp tục hiển thị giá tiền cụ thể của từng gói không? → A: Giữ đầy đủ giá (tên + giá + thời hạn + quyền lợi như hiện tại, chỉ gỡ hành động trả tiền).
- Q: Sau khi thanh toán trên website, app mobile nên cập nhật gói và số dư mới bằng cách nào? → A: Tự động khi quay lại (tự tải lại gói + ví mỗi khi quay lại app / mở lại màn hình).
- Q: Các nút thanh toán cũ trong app như mua bằng ví và form nhập số tiền nạp ví nên xử lý thế nào? → A: Ẩn hoàn toàn (gỡ bỏ form nhập tiền và nút mua bằng ví, chỉ giữ xem số dư + lịch sử).
- Q: Luồng chỉ-hiển-thị-gói và thanh toán trên web này nên áp dụng cho những nền tảng nào? → A: Cả Android và iOS (áp dụng thống nhất cho mọi bản mobile).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Xem gói và được hướng dẫn lên website thanh toán (Priority: P1)

Người dùng đăng nhập trên app mobile mở màn hình gói hội viên / nâng cấp, xem đầy đủ danh sách gói (tên, giá, thời hạn, quyền lợi), chọn gói muốn mua và được hướng dẫn tiếp tục thanh toán trên website: mở trình duyệt, đăng nhập cùng tài khoản, hoàn tất thanh toán ở đó, sau đó quay lại app thấy quyền lợi mới.

**Why this priority**: Đây là thay đổi cốt lõi để tuân thủ chính sách Google Play — giữ khả năng giới thiệu gói trên mobile nhưng loại bỏ mọi hành vi thu tiền trong app. Không có luồng này thì app có nguy cơ bị từ chối duyệt.

**Independent Test**: Chỉ với một tài khoản gói Free, mở màn hình gói, bấm mua và xác minh (1) không có trang thanh toán nào mở ra trong app, (2) người dùng nhận được hướng dẫn lên website rõ ràng, (3) sau khi thanh toán xong trên website và quay lại app, gói mới hiển thị đúng.

**Acceptance Scenarios**:

1. **Given** người dùng đã đăng nhập và đang ở gói Free, **When** mở màn hình gói, **Then** thấy danh sách gói với tên, giá VNĐ, thời hạn và quyền lợi so sánh, không có nút quét mã / thanh toán trực tiếp trong app.
2. **Given** người dùng chọn một gói trả phí và bấm tiếp tục / nâng cấp, **When** hành động được ghi nhận, **Then** app hiển thị hướng dẫn lên website (địa chỉ website, các bước đăng nhập cùng tài khoản và thanh toán), không tạo hay mở bất kỳ liên kết thanh toán nào.
3. **Given** người dùng đã hoàn tất thanh toán gói trên website, **When** quay lại app / mở lại màn hình gói, **Then** thấy gói mới (ví dụ Premium), thời hạn và hạn mức tương ứng mà không cần thao tác làm mới thủ công.
4. **Given** việc tải danh sách gói thất bại (mất mạng / lỗi máy chủ), **When** mở màn hình gói, **Then** app hiển thị thông báo lỗi thân thiện và nút thử lại, không hiển thị hướng dẫn thanh toán sai lệch.

---

### User Story 2 - Nạp ví bằng cách lên website (Priority: P1)

Người dùng mở thẻ / màn hình ví trên mobile, xem được số dư và lịch sử, khi muốn nạp thêm thì được hướng dẫn lên website đăng nhập và nạp tiền; sau khi nạp xong trên web, số dư trên mobile được cập nhật.

**Why this priority**: Nạp ví là hành vi thu tiền thứ hai (song song với mua gói) và cũng phải rời khỏi app để tránh chính sách Play. Thiếu nó thì luồng ví vẫn vi phạm.

**Independent Test**: Mở ví và xác minh không còn form nhập số tiền / nút nạp hay mua bằng ví nào trong app, chỉ có hướng dẫn văn bản lên website; sau khi nạp thành công trên website, mở lại ví trên mobile thấy số dư tăng đúng.

**Acceptance Scenarios**:

1. **Given** người dùng xem ví trên mobile, **When** quan sát màn hình, **Then** thấy số dư khả dụng và lịch sử giao dịch; không còn form nhập số tiền hay nút nạp / mua bằng ví trong app, thay vào đó là hướng dẫn văn bản lên website khi có nhu cầu nạp.
2. **Given** người dùng có nhu cầu nạp tiền, **When** đọc hướng dẫn trong app, **Then** nội dung nêu rõ phải tự mở trình duyệt, đăng nhập website bằng cùng tài khoản và thực hiện nạp ở đó (không có nút mở link trong app).
3. **Given** người dùng đã nạp thành công trên website, **When** quay lại app và làm mới ví, **Then** số dư và lịch sử hiển thị giá trị mới.

---

### User Story 3 - Đồng bộ trạng thái sau thanh toán web (Priority: P2)

Người dùng sau khi thanh toán / nạp ví trên website quay lại app đang mở sẵn và thấy trạng thái mới mà không phải đăng xuất, xóa app hay tạo tài khoản mới.

**Why this priority**: Nếu app không cập nhật kịp, người dùng nghĩ thanh toán thất bại và tạo khiếu nại / đánh giá xấu, làm mất tác dụng của việc chuyển thanh toán lên web.

**Independent Test**: Thanh toán trên website xong, quay lại app (đang chạy nền) và xác minh gói / số dư tự cập nhật trong thời gian ngắn mà không cần bấm làm mới.

**Acceptance Scenarios**:

1. **Given** app đang mở ở màn hình gói / ví trước khi thanh toán web, **When** người dùng quay lại app (mở lại từ nền hoặc mở lại màn hình), **Then** app tự động tải lại trạng thái gói và số dư mới nhất.
2. **Given** người dùng quay lại app khi giao dịch web chưa hoàn tất, **When** trạng thái được làm mới, **Then** app vẫn hiển thị trạng thái cũ kèm gợi ý kiểm tra lại sau, không báo thành công giả.

---

### Edge Cases

- Người dùng đăng nhập website bằng tài khoản khác với tài khoản trên mobile thì sao? App mobile không thay đổi; hướng dẫn phải nhấn mạnh "cùng tài khoản / cùng email".
- Người dùng bấm quay lại app ngay khi chưa thanh toán xong trên web: trạng thái giữ nguyên, không hiển thị thành công.
- Người dùng ngoại tuyến khi mở màn hình gói / ví: hiển thị lỗi và thử lại, không kẹt ở hướng dẫn thanh toán.
- Người dùng còn giao dịch chờ thanh toán từ phiên bản cũ (đã tạo link trước khi đổi luồng): không tiếp tục mở link cũ; hiển thị thông báo link cũ hết hiệu lực và hướng dẫn lên website.
- Người dùng không tìm thấy website / nhập sai địa chỉ: hướng dẫn phải hiển thị địa chỉ website đầy đủ ở dạng văn bản dễ đọc, không dùng nút mở link hay sao chép tự động.
- Chính sách cửa hàng ứng dụng diễn giải việc "điều hướng ra web để trả tiền hàng số" vẫn vi phạm: nội dung hiển thị trên mobile chỉ mang tính giới thiệu thông tin, không dùng ngôn ngữ thúc ép thanh toán ngoài để lách phí, tuân thủ diễn giải mới nhất của chính sách.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Hệ thống mobile PHẢI hiển thị danh sách gói hội viên ở chế độ chỉ xem thông tin (tên gói, giá VNĐ, thời hạn, quyền lợi / so sánh), không có nút hay hành động nào khởi tạo thanh toán trong app.
- **FR-002**: Khi người dùng chọn mua / nâng cấp gói trên mobile, hệ thống PHẢI hiển thị hướng dẫn tiếp tục trên website thay vì xử lý thanh toán, bao gồm: địa chỉ website, yêu cầu đăng nhập cùng tài khoản, các bước thanh toán trên web.
- **FR-003**: Hệ thống mobile PHẢI KHÔNG tạo yêu cầu thanh toán, KHÔNG mở trang thanh toán / mã QR thanh toán, và KHÔNG nhúng trang thanh toán trong app (kể cả trình duyệt trong app) đối với cả mua gói và nạp ví.
- **FR-004**: Chức năng nạp ví trên mobile PHẢI được gỡ bỏ hoàn toàn khỏi app (không còn form nhập số tiền, không còn nút xác nhận nạp hay mua gói bằng ví). Trên mobile chỉ giữ xem số dư và lịch sử ở chế độ chỉ đọc; nhu cầu nạp ví hay dùng ví mua gói đều được hướng dẫn thực hiện trên website.
- **FR-005**: Hướng dẫn lên website PHẢI nhấn mạnh người dùng đăng nhập website bằng cùng tài khoản đang dùng trên mobile (ví dụ cùng email / số điện thoại) để gói và số dư đồng bộ đúng.
- **FR-006**: Hệ thống mobile KHÔNG được cung cấp bất kỳ nút / liên kết nào mở website hay trang thanh toán từ app (kể cả trang chủ / trang giá chung). Hướng dẫn lên website CHỈ ở dạng văn bản đọc được (địa chỉ website đầy đủ, dễ đọc / ghi nhớ) để người dùng tự mở trình duyệt ngoài app.
- **FR-007**: Hệ thống mobile PHẢI tự động tải lại trạng thái gói hội viên và số dư ví mới nhất mỗi khi người dùng quay lại app (từ nền) hoặc mở lại màn hình gói / ví, để phản ánh kết quả thanh toán đã thực hiện trên website mà không cần đăng xuất, cài lại hay bấm làm mới thủ công.
- **FR-008**: Hệ thống mobile PHẢI giữ khả năng xem lịch sử ví / giao dịch và thông tin gói hiện tại ở chế độ chỉ đọc, độc lập với việc thanh toán đã chuyển lên web.
- **FR-009**: Đối với các liên kết / mã thanh toán cũ còn dang dở từ trước khi đổi luồng (nếu tồn tại), hệ thống PHẢI không tiếp tục mở hay xử lý chúng mà hiển thị thông báo hết hiệu lực và hướng dẫn lên website.
- **FR-010**: Mọi thông báo lỗi (tải gói, tải ví, mất mạng) PHẢI bằng tiếng Việt, thân thiện, nêu rõ bước tiếp theo (thử lại / kiểm tra mạng / lên website khi cần) và không để người dùng kẹt ở trạng thái chờ thanh toán.

### Key Entities

- **Gói hội viên (hiển thị)**: Thông tin chỉ đọc trên mobile gồm tên, giá, thời hạn, quyền lợi; không chứa trạng thái thanh toán trong app.
- **Gói của người dùng**: Trạng thái hiện tại (gói Free / trả phí, thời hạn, hạn mức) được đồng bộ từ kết quả thanh toán trên website.
- **Ví (chỉ đọc trên mobile)**: Số dư khả dụng và lịch sử giao dịch để đối chiếu sau khi nạp trên website.
- **Hướng dẫn thanh toán web**: Nội dung hướng dẫn gồm địa chỉ website, yêu cầu cùng tài khoản, các bước đăng nhập và thanh toán / nạp ví trên web.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% thao tác bấm mua gói / nạp ví trên bản mobile mới không tạo và không mở bất kỳ trang hay mã thanh toán nào (kiểm chứng bằng thử nghiệm thủ công trên mọi điểm vào gói và ví).
- **SC-002**: 90% người dùng thử nghiệm lần đầu hiểu được cần lên website để thanh toán mà không cần hỗ trợ thêm (trả lời đúng khi được hỏi bước tiếp theo sau khi bấm mua).
- **SC-003**: Sau khi thanh toán / nạp ví thành công trên website, người dùng thấy gói mới và số dư mới trên mobile trong vòng 2 phút sau khi quay lại app, ở 95% lượt thử.
- **SC-004**: Tỷ lệ khiếu nại "đã trả tiền nhưng app chưa lên gói" không tăng quá 5% so với trước khi đổi luồng trong 30 ngày đầu sau phát hành.
- **SC-005**: Bản mobile vượt qua vòng duyệt cửa hàng ứng dụng mà không bị yêu cầu gỡ bỏ hay chỉnh sửa liên quan đến thanh toán ngoài.

## Assumptions

- Người dùng mobile và website dùng chung một hệ thống tài khoản; đăng nhập cùng email / số điện thoại thì gói và ví đồng bộ.
- Địa chỉ website thanh toán đã có, hoạt động ổn định và hỗ trợ đầy đủ mua gói + nạp ví; phạm vi spec này chỉ thay đổi phía mobile, không thay đổi website hay backend thanh toán.
- Mục tiêu chính là tuân thủ chính sách Google Play nên mọi hành vi thu tiền (kể cả mở liên kết thanh toán ra trình duyệt ngoài) đều được loại khỏi app mobile; tính năng thanh toán qua cửa hàng ứng dụng (IAP / Google Play Billing) ngoài phạm vi đợt này.
- Người dùng có trình duyệt và kết nối mạng để tự mở website và đăng nhập; app mobile vẫn cần mạng để hiển thị gói, số dư và làm mới trạng thái.
- Danh sách gói, giá và quyền lợi hiển thị trên mobile chỉ để giới thiệu; giá trị thanh toán có hiệu lực cuối cùng là giá trên website tại thời điểm trả tiền.
- Luồng này áp dụng thống nhất cho mọi bản mobile (cả Android và iOS), không phân biệt nền tảng, để thống nhất trải nghiệm và tránh rủi ro duyệt trên mọi cửa hàng ứng dụng.
