# Feature Specification: Google Play Deploy Setup

**Feature Branch**: `008-google-play-deploy-setup`

**Created**: 2026-09-19

**Status**: Draft

**Input**: User description: "lên plan setup deploy lên CH play" (kèm tài liệu tham chiếu `docs/Flutter_to_Google_Play_Deployment_Guide.md`)

## Clarifications

### Session 2026-09-19

- Q: Ứng dụng publish dưới loại tài khoản Google Play developer nào? → A: Tài khoản cá nhân (Personal) tạo sau 13/11/2023 — bắt buộc Closed Testing tối thiểu 12 tester opt-in liên tục 14 ngày trước khi xin Production access.
- Q: Kế hoạch lần này nhắm tới cột mốc nào trên Google Play? → A: Đi trọn tới Production release công khai trên Google Play (theo thứ tự Internal Testing → Closed Testing → Production).
- Q: Xử lý tính năng trả phí kỹ thuật số (subscription & nạp ví PayOS) thế nào? → A: Bản Play đầu tiên tạm ẩn/khóa các luồng này, app ở chế độ miễn phí; tích hợp Google Play Billing để ở giai đoạn sau.
- Q: Điểm cuối API production dùng HTTPS hay HTTP cleartext? → A: Dùng endpoint HTTPS thật; release build trỏ tới URL HTTPS qua cấu hình build và tắt truyền cleartext (chỉ giữ cho debug/local).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Phát hành bản cài đặt được ký lên Internal Testing (Priority: P1)

Đội phát triển chuẩn bị đúng định danh ứng dụng và phiên bản, tạo và bảo quản khóa ký, cấu hình ký cho bản phát hành, build ra gói phát hành, rồi tải gói đó lên kênh Internal Testing của Google Play. Tester nội bộ nhận lời mời, cài app từ Play trên máy Android thật và dùng thử đầy đủ các chức năng chính.

**Why this priority**: Đây là cột mốc giá trị nhỏ nhất — có một bản cài đặt thật, ký đúng, cài được từ Play. Chưa cần công khai nhưng đã chứng minh toàn bộ đường ống release hoạt động.

**Independent Test**: Có thể kiểm thử độc lập bằng cách build gói phát hành, tải lên kênh Internal Testing, mời ít nhất 1 tester, để tester cài từ Play và chạy qua checklist chức năng.

**Acceptance Scenarios**:

1. **Given** bản phát hành hiện ký bằng khóa debug, **When** hoàn tất US1, **Then** định danh gói được chốt là production (`com.smartwardrobe.smart_wardrobe`, đã là ID production từ trước) và bản phát hành được ký bằng khóa tải lên riêng, không dùng khóa debug.
2. **Given** khóa ký đã tạo, **When** build bản phát hành, **Then** tạo ra gói phát hành hợp lệ, cài và mở được trên máy Android thật.
3. **Given** gói phát hành đã tải lên Internal Testing, **When** tester đã opt-in, **Then** tester cài được từ Play và app chạy đúng với backend production.
4. **Given** tester cài bản phát hành, **When** chạy checklist chức năng (đăng nhập, dữ liệu, tải ảnh, camera, quyền), **Then** mọi mục đạt, không crash; các luồng trả phí kỹ thuật số và deep-link thanh toán không xuất hiện.
5. **Given** file khóa và mật khẩu đã tạo, **When** kiểm tra hệ thống quản lý mã nguồn, **Then** không có khóa/mật khẩu nào bị đưa lên.

---

### User Story 2 - Hoàn tất hồ sơ cửa hàng và khai báo bắt buộc (Priority: P2)

Đội phát triển tạo ứng dụng trên Google Play Console, hoàn thiện hồ sơ cửa hàng (tên, mô tả, biểu tượng, ảnh chụp) và các khai báo bắt buộc (chính sách bảo mật, an toàn dữ liệu, xếp hạng nội dung, đối tượng người dùng, quyền truy cập ứng dụng, quảng cáo) phản ánh đúng hành vi thật của app.

**Why this priority**: Không có hồ sơ và khai báo đầy đủ thì bản phát hành không thể được duyệt. Đây là điều kiện để kênh testing trở nên hữu ích và để tiến tới production.

**Independent Test**: Có thể kiểm thử độc lập bằng cách rà từng mục trong danh sách khai báo của Play Console và đối chiếu với hành vi thật của app.

**Acceptance Scenarios**:

1. **Given** ứng dụng đã tạo trên Play Console, **When** hoàn tất hồ sơ cửa hàng, **Then** các trường bắt buộc (tên, mô tả ngắn/dài, biểu tượng, ảnh chụp) đều hợp lệ và đầy đủ.
2. **Given** app có lưu dữ liệu người dùng, **When** khai báo an toàn dữ liệu, **Then** nội dung khai báo khớp đúng dữ liệu thực tế thu thập/chia sẻ (email, tên, ảnh, vị trí, thiết bị, phân tích, dữ liệu crash), bảo mật khi truyền và khả năng yêu cầu xóa.
3. **Given** app yêu cầu đăng nhập, **When** khai báo quyền truy cập, **Then** có tài khoản test kèm hướng dẫn để người kiểm duyệt vào được các chức năng.
4. **Given** app có chính sách bảo mật, **When** khai báo, **Then** chính sách phản ánh đúng hành vi app và truy cập được bằng liên kết công khai.
5. **Given** các khai báo đã hoàn tất, **When** gửi bản phát hành đi duyệt, **Then** không bị từ chối vì thiếu/sai khai báo.

---

### User Story 3 - Từ Closed Testing tới Production Release (Priority: P3)

Đội phát triển đưa ứng dụng qua kênh Closed Testing với đủ số tester duy trì opt-in liên tục, xin quyền truy cập Production, rồi phát hành bản production cho người dùng cuối và vượt qua vòng duyệt của Google.

**Why this priority**: Là đích cuối phục vụ người dùng thật, nhưng phụ thuộc US1 và US2 và có thể mất nhiều ngày chờ điều kiện testing, nên xếp sau.

**Independent Test**: Có thể kiểm thử độc lập bằng cách mời đủ tester opt-in, theo dõi đủ thời gian liên tục, xin Production access, phát hành và xác nhận app hiển thị công khai.

**Acceptance Scenarios**:

1. **Given** bản phát hành đã ổn ở Internal Testing, **When** mở Closed Testing, **Then** có kênh Closed Testing với danh sách tester đã mời.
2. **Given** tài khoản cá nhân tạo sau mốc Google quy định, **When** xin Production access, **Then** đã có tối thiểu 12 tester (khuyến nghị 15–20) opt-in liên tục tối thiểu 14 ngày.
3. **Given** đã đủ điều kiện testing, **When** gửi yêu cầu Production access, **Then** câu trả lời mô tả đúng quá trình testing và độ sẵn sàng thật của app.
4. **Given** đã được cấp Production access, **When** tạo bản phát hành production và bắt đầu rollout, **Then** gói phát hành được tải lên đúng và Google bắt đầu duyệt.
5. **Given** Google duyệt thành công, **When** rollout hoàn tất, **Then** người dùng thật tìm thấy và cài được app từ Google Play.

---

### Edge Cases

- Khóa ký hoặc mật khẩu bị mất/sai — bản cập nhật sau không ký được; phải có bản sao lưu an toàn và xác minh trước khi release.
- Số hiệu phiên bản không tăng so với lần tải trước — gói bị từ chối; phải tăng số hiệu mỗi lần tải.
- Bản phát hành chạy khác bản debug (cấu hình máy chủ, xử lý mã rút gọn, quyền, ký, cấu hình native) — phải test chính bản phát hành, không chỉ bản debug.
- Tester chưa opt-in hoặc đã opt-out giữa chừng — điều kiện testing không được tính; cần dư số lượng tester (khuyến nghị 15–20).
- Nếu sau này bật lại thu tiền kỹ thuật số qua kênh ngoài Google Play Billing — app có nguy cơ bị từ chối/gỡ; phải chuyển sang Google Play Billing.
- Ứng dụng vẫn bật truyền dữ liệu không mã hóa (`usesCleartextTraffic`) và fallback về địa chỉ API mẫu — release build phải loại bỏ điều này, nếu không app không kết nối được và khai báo dữ liệu sai.
- Scheme deep-link `smartwardrobe://` giữ trong manifest nhưng xử lý PayOS bị vô hiệu ở bản Play đầu tiên; khi bật lại thanh toán sau này phải kiểm thử lại deep-link trên bản phát hành.
- Không có kết nối mạng hoặc máy chủ production lỗi khi tester dùng — phải có thông báo thân thiện, app không crash.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Ứng dụng MUST dùng định danh gói production, không dùng định danh mẫu.
- **FR-002**: Số hiệu phiên bản MUST tăng mỗi lần tải lên một bản phát hành mới.
- **FR-003**: Đội phát triển MUST tạo khóa ký tải lên, lưu an toàn tệp khóa, mật khẩu kho và mật khẩu khóa.
- **FR-004**: Bản phát hành MUST được ký bằng khóa tải lên, không dùng khóa debug; bản debug MUST không bị ảnh hưởng.
- **FR-005**: Hệ thống quản lý mã nguồn MUST loại trừ tệp khóa, tệp keystore và tệp cấu hình chứa mật khẩu.
- **FR-006**: Quy trình build MUST tạo ra gói Android App Bundle phát hành hợp lệ và gói này MUST cài/mở được trên máy thật.
- **FR-007**: Bản phát hành MUST được kiểm thử trên thiết bị thật cho các luồng chính: đăng nhập/đăng ký, kết nối máy chủ production, tải ảnh, camera và quyền truy cập lúc chạy.
- **FR-008**: Ứng dụng MUST được tạo trên Google Play Console với tên, ngôn ngữ mặc định (Vietnamese), loại (app/game), và hình thức Free đúng.
- **FR-009**: Hồ sơ cửa hàng MUST có đầy đủ tên, mô tả ngắn, mô tả đầy đủ, biểu tượng, ảnh chụp màn hình và ảnh nổi bật nếu được yêu cầu.
- **FR-010**: Ứng dụng MUST có chính sách bảo mật công khai phản ánh đúng hành vi thật.
- **FR-011**: Khai báo an toàn dữ liệu MUST mô tả đúng dữ liệu thu thập/chia sẻ, mục đích, tính bắt buộc, mã hóa khi truyền và khả năng yêu cầu xóa.
- **FR-012**: Các khai báo xếp hạng nội dung, đối tượng người dùng, quảng cáo và quyền truy cập ứng dụng MUST được hoàn tất đúng.
- **FR-013**: Nếu app yêu cầu đăng nhập, MUST cung cấp tài khoản test kèm hướng dẫn để người kiểm duyệt dùng được các chức năng.
- **FR-014**: Bản phát hành MUST được tải lên kênh Internal Testing và tester nội bộ MUST cài được từ Play.
- **FR-015**: Tester nội bộ MUST xác nhận các luồng chính chạy đúng trên bản cài từ Play.
- **FR-016**: Ứng dụng MUST được đưa qua kênh Closed Testing với tối thiểu 12 tester (khuyến nghị 15–20) duy trì opt-in liên tục ít nhất 14 ngày, do tài khoản là Personal tạo sau 13/11/2023.
- **FR-017**: Yêu cầu cấp quyền Production MUST dựa trên tình trạng testing và độ sẵn sàng thật, không khai báo quá sự thật.
- **FR-018**: Bản phát hành production MUST được tải lên và bắt đầu rollout sau khi được cấp quyền.
- **FR-019**: Quy trình release MUST có checklist xác minh cuối cùng (bảo mật, build, hồ sơ, testing, production) trước mỗi lần phát hành.
- **FR-020**: Khi release gặp lỗi (không ký được, bị từ chối vì phiên bản, bản phát hành lỗi), MUST có cách xử lý đã biết và không làm mất dữ liệu người dùng.
- **FR-021**: Bản phát hành Play đầu tiên MUST tạm ẩn/khóa mọi luồng thu tiền kỹ thuật số (gói subscription và nạp ví qua PayOS); không có điểm vào nào dẫn tới thanh toán ngoài Google Play Billing.
- **FR-022**: Khi tính năng trả phí kỹ thuật số được bật lại trong tương lai, MUST dùng Google Play Billing, không dùng kênh thanh toán ngoài.
- **FR-023**: Bản phát hành MUST trỏ tới endpoint API production HTTPS thật, không dùng địa chỉ mẫu/`[IP_ADDRESS]`.
- **FR-024**: Bản phát hành MUST tắt truyền dữ liệu không mã hóa (cleartext); chỉ bản debug/local được phép dùng cleartext.

### Key Entities

- **Bản phát hành (Release Build)**: Gói phát hành đã ký cho một phiên bản cụ thể — định danh, số hiệu phiên bản, khóa ký.
- **Thông tin ký (Signing Credential)**: Tệp khóa và mật khẩu/alias dùng để ký bản phát hành — tài sản bảo mật tối quan trọng.
- **Kênh testing (Test Track)**: Internal Testing / Closed Testing — tập tester được mời, trạng thái opt-in, thời gian duy trì.
- **Hồ sơ cửa hàng (Store Listing)**: Nội dung hiển thị công khai — tên, mô tả, hình ảnh.
- **Khai báo tuân thủ (Compliance Declaration)**: Chính sách bảo mật, an toàn dữ liệu, xếp hạng nội dung, đối tượng, quyền truy cập.
- **Tài khoản test (Testing Account)**: Tài khoản đăng nhập cấp cho người kiểm duyệt/tester.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Tạo và build thành công gói phát hành được ký bằng khóa tải lên; 3/3 máy Android thật cài và mở app không crash.
- **SC-002**: 100% mục trong checklist chức năng bản phát hành đạt trên máy thật (đăng nhập, dữ liệu production, tải ảnh, camera, quyền); 0 điểm vào trả phí kỹ thuật số và 0 deep-link thanh toán xuất hiện.
- **SC-003**: 0 tệp khóa/mật khẩu xuất hiện trong lịch sử quản lý mã nguồn tại thời điểm release.
- **SC-004**: Hồ sơ cửa hàng và các khai báo bắt buộc đạt 100% trường bắt buộc; bản phát hành đầu tiên không bị từ chối vì thiếu/sai khai báo.
- **SC-005**: Tester nội bộ cài được app từ Play trong vòng 1 ngày sau khi tải bản phát hành lên kênh Internal Testing.
- **SC-006**: Đạt tối thiểu 12 tester opt-in liên tục trong 14 ngày mà không bị gián đoạn (tài khoản Personal tạo sau 13/11/2023).
- **SC-007**: Yêu cầu Production access được chấp thuận và bản phát hành production được duyệt để hiển thị công khai trên Google Play.
- **SC-008**: Mỗi lần phát hành sau đều tăng số hiệu phiên bản và không tái sử dụng số hiệu đã tải lên.
- **SC-009**: 3/3 máy thật cài bản release kết nối được tới API production HTTPS; 0 yêu cầu cleartext và 0 tham chiếu địa chỉ `[IP_ADDRESS]` trong bản phát hành.

## Assumptions

- Đội có quyền truy cập Google Play Console và tài khoản nhà phát triển loại **Personal tạo sau 13/11/2023**, nên điều kiện Closed Testing 12 tester × 14 ngày liên tục là bắt buộc trước khi xin Production access.
- Backend production đã sẵn sàng và phục vụ qua HTTPS; các luồng trả phí kỹ thuật số (subscription, nạp ví PayOS) và deep-link thanh toán được tạm ẩn trong bản Play đầu tiên nên chưa cần hoạt động trên Play.
- Chính sách bảo mật sẽ được đặt tại một liên kết công khai do đội quản lý.
- Kế hoạch đi theo thứ tự khuyến nghị: Internal Testing trước, rồi Closed Testing, rồi Production — không tải thẳng lên Production.
- Phạm vi lần này chỉ gồm phát hành Android lên Google Play; phát hành iOS (App Store) và bản web nằm ngoài phạm vi.
- Ứng dụng dùng để kiểm thử nội bộ có đủ tài khoản test và dữ liệu mẫu.
- Một người chịu trách nhiệm release sẽ quản lý thông tin ký; không chia sẻ qua kênh công khai.
- Các yêu cầu của Google Play có thể thay đổi theo thời điểm; trước khi release chính thức sẽ kiểm tra lại yêu cầu hiển thị trực tiếp trong Play Console.
