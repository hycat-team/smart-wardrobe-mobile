# Feature Specification: Premium Payment Mobile (Parity FE)

**Feature Branch**: `001-premium-payment-mobile`

**Created**: 2026-09-11

**Status**: Draft

**Input**: User description: "dựa trên luồng thanh toán gói premium bằng phương thức thanh toán của FE để lên plan làm trên mobile"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Mua Premium bằng VietQR / PayOS (Priority: P1)

Người dùng Free mở màn hình nâng cấp, xem bảng so sánh Free vs Premium, chọn "Quét VietQR Trực Tiếp (PayOS)", được mở cổng thanh toán PayOS, quét mã QR bằng app ngân hàng, quay lại app và thấy tài khoản tự động lên Premium kèm màn hình chúc mừng.

**Why this priority**: Đây là luồng doanh thu chính, tương đương nút "Chuyển khoản (VietQR)" trong dialog Thanh toán của FE (`PricingCard.tsx`). Không có nó thì mobile không bán được gói.

**Independent Test**: Tạo link mua gói premium, mở được trang PayOS, sau khi thanh toán thành công thì `GET /subscriptions/me` trả về gói premium và hạn mức mới — test được độc lập qua polling màn hình chờ.

**Acceptance Scenarios**:

1. **Given** người dùng đang gói Free và đã đăng nhập, **When** mở màn hình nâng cấp, **Then** thấy tên gói, giá VNĐ, thời hạn ngày, bảng so sánh đặc quyền và 2 phương thức thanh toán.
2. **Given** người dùng chọn VietQR/PayOS, **When** backend trả về link thanh toán, **Then** app mở trang PayOS (trình duyệt ngoài) và chuyển sang màn hình chờ có mã đơn, số tiền, phương thức.
3. **Given** đang ở màn hình chờ, **When** giao dịch PayOS thành công, **Then** trong vòng ~1 chu kỳ polling app tự phát hiện gói Premium và hiển thị màn hình chúc mừng với đặc quyền đã mở khóa.
4. **Given** tạo link thất bại (mất mạng/lỗi backend), **When** người dùng bấm thanh toán, **Then** app hiển thị thông báo lỗi tiếng Việt và KHÔNG chuyển màn hình.

---

### User Story 2 - Mua Premium bằng số dư Ví Closy (Priority: P1)

Người dùng có số dư ví đủ tiền mua gói, xác nhận dùng ví để thanh toán và được nâng cấp tức thì không qua PayOS — tương đương nút "Số dư ví CLOSY" của FE.

**Why this priority**: Ngang hàng với VietQR trong dialog FE; là phương thức thứ hai bắt buộc để parity.

**Independent Test**: Với ví đủ số dư, xác nhận thanh toán và kiểm tra gói chuyển Premium + số dư ví giảm đúng giá gói.

**Acceptance Scenarios**:

1. **Given** số dư ví >= giá gói, **When** mở màn hình nâng cấp, **Then** nút mua bằng ví hiển thị ở trạng thái khả dụng cùng số dư hiện tại.
2. **Given** ví đủ tiền, **When** xác nhận thanh toán, **Then** app gọi mua bằng ví, làm mới số dư + gói cước, hiển thị dialog thành công.
3. **Given** ví không đủ tiền, **When** bấm nút ví, **Then** app mở bottom sheet nạp tiền thay vì thực hiện mua.

---

### User Story 3 - Nạp tiền vào ví qua PayOS (Priority: P2)

Người dùng ví không đủ tiền, nhập số tiền cần nạp, mở PayOS thanh toán, quay lại thấy số dư ví tăng — tương đương luồng `topupWallet` của FE (`TopUpModal.tsx` → redirect PayOS).

**Why this priority**: Bổ trợ User Story 2; đã có `TopUpBottomSheet` trên mobile nhưng thiếu màn hình chờ/xác nhận sau khi rời app.

**Independent Test**: Tạo yêu cầu nạp, thanh toán xong, số dư ví tăng đúng số tiền và lịch sử giao dịch có bản ghi nạp.

**Acceptance Scenarios**:

1. **Given** người dùng nhập số tiền hợp lệ, **When** xác nhận nạp, **Then** app mở trang PayOS và ghi nhận yêu cầu đang chờ.
2. **Given** thanh toán nạp tiền thành công, **When** quay lại app, **Then** số dư ví và lịch sử giao dịch được làm mới.

---

### User Story 4 - Xem gói hiện tại, hạn mức AI và tự động gia hạn (Priority: P2)

Người dùng xem gói đang dùng, hạn mức AI còn lại trong ngày và bật/tắt tự động gia hạn — tương đương `CurrentPlanCard` + `useToggleAutoRenewMutation` của FE.

**Why this priority**: Parity hiển thị và quản lý sau mua; ngăn khiếu nại "không biết mình đang gói gì".

**Independent Test**: Mở màn hình chi tiết gói, thấy đúng tên gói, ngày hết hạn, hạn mức; bật/tắt tự động gia hạn và tải lại vẫn giữ trạng thái.

**Acceptance Scenarios**:

1. **Given** đã đăng nhập, **When** mở chi tiết gói, **Then** thấy tên gói, trạng thái, ngày hết hạn và hạn mức AI (phối đồ + chat).
2. **Given** đang dùng gói trả phí, **When** đổi trạng thái tự động gia hạn, **Then** trạng thái được lưu và hiển thị đúng sau khi tải lại.

---

### Edge Cases

- Thanh toán PayOS quá 15 phút chưa xong: dừng polling, cho phép mở lại link hoặc rời màn hình mà không mất trạng thái đơn.
- Người dùng bấm nút back khi đang chờ: hỏi xác nhận rời đi, nêu rõ giao dịch vẫn được xử lý nền.
- Link PayOS hết hạn khi mở lại: báo lỗi rõ ràng và cho tạo link mới.
- Gói đã là Premium mà vẫn vào màn hình nâng cấp: hiển thị trạng thái "đang dùng Premium" thay vì nút mua.
- Mất mạng giữa polling: giữ màn hình chờ, thử lại chu kỳ sau, không crash.
- Số tiền hiển thị ở màn hình chờ phải là giá gói thực tế, không phải giá trị cố định (hiện tại code mobile đang ghi cứng `249.000 đ` trong `payment_waiting_screen.dart`).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Hệ thống PHẢI hiển thị danh sách gói (`free` + `premium`), giá VNĐ, thời hạn, đặc quyền và bảng so sánh Free vs Premium trước khi thanh toán.
- **FR-002**: Hệ thống PHẢI tạo link mua trực tiếp qua `POST /subscriptions/me/purchase` với `planSlug` (kèm `returnUrl`/`cancelUrl` khi backend hỗ trợ) và mở trang PayOS ngoài app.
- **FR-003**: Hệ thống PHẢI có màn hình chờ sau khi mở PayOS, hiển thị mã đơn, số tiền thực, phương thức và tự kiểm tra trạng thái gói mỗi 3 giây.
- **FR-004**: Hệ thống PHẢI tự chuyển sang trạng thái chúc mừng khi phát hiện gói Premium, đồng thời làm mới gói cước và hạn mức AI.
- **FR-005**: Hệ thống PHẢI hỗ trợ mua bằng ví qua `POST /subscriptions/me/purchase-with-wallet`, gồm dialog xác nhận, kiểm tra số dư trước mua và làm mới ví + gói sau mua.
- **FR-006**: Hệ thống PHẢI hỗ trợ nạp ví qua `POST /subscriptions/me/wallet/topup` với số tiền do người dùng nhập và mở trang PayOS tương ứng.
- **FR-007**: Hệ thống PHẢI hiển thị gói hiện tại, ngày hết hạn, hạn mức AI/ngày và cho phép bật/tắt tự động gia hạn (`PUT /subscriptions/me/auto-renew`). (Đã chốt 2026-09-11: đưa toggle tự động gia hạn vào phạm vi đợt này để parity FE.)
- **FR-008**: Mọi lỗi (tạo link thất bại, ví không đủ, link hết hạn, mất mạng) PHẢI hiển thị thông báo tiếng Việt và không làm mất trạng thái màn hình hiện tại.
- **FR-009**: Hệ thống PHẢI đón deep link quay lại app sau thanh toán (`smartwardrobe://subscription/...`, `smartwardrobe://wallet/...`) và điều hướng đúng màn hình kết quả/hủy. (Đã chốt 2026-09-11: triển khai đón deep link trong đợt này, bên cạnh polling màn hình chờ.)
- **FR-010**: Phạm vi đợt này bao gồm cả 3 luồng để parity đầy đủ với FE: mua trực tiếp VietQR/PayOS, mua bằng ví và nạp ví. (Đã chốt 2026-09-11: full parity.)

### Key Entities

- **SubscriptionPlan**: Gói hội viên (slug, tên, giá, thời hạn ngày, sức chứa tủ/outfit, hạn mức AI phối đồ + chat mỗi ngày).
- **UserSubscription**: Gói đang dùng (tên gói, trạng thái, ngày hết hạn, cờ Premium, cờ tự động gia hạn).
- **DailyQuota**: Hạn mức AI còn lại trong ngày (lượt phối đồ, lượt chat Stylist).
- **PaymentLink**: Link thanh toán PayOS (URL thanh toán, mã đơn, trạng thái).
- **Wallet**: Ví nội bộ (số dư, lịch sử nạp/chi/hoàn).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Người dùng hoàn tất mua Premium bằng VietQR từ màn hình nâng cấp trong dưới 5 phút (kể cả thời gian quét QR ngân hàng).
- **SC-002**: 100% giao dịch PayOS thành công được app phát hiện và nâng cấp gói chậm nhất sau 1 chu kỳ polling kể từ khi backend xác nhận.
- **SC-003**: 95% lần mua bằng ví (đủ số dư) thành công ngay lần thử đầu mà không cần thao tác lại.
- **SC-004**: Không còn giá trị tiền ghi cứng ở màn hình chờ; số tiền hiển thị luôn khớp giá gói đã chọn.
- **SC-005**: Tỷ lệ người dùng bỏ dở ở màn hình chờ mà không rõ trạng thái giao dịch giảm còn 0 (mọi lối ra đều có xác nhận + hướng quay lại xem trạng thái).

## Assumptions

- Backend đã hỗ trợ `returnUrl`/`cancelUrl` trong DTO mua và nạp (đã kiểm chứng trong `billing_dto.go` và swagger).
- PayOS `return_url`/`cancel_url` mặc định của backend trỏ về web; mobile gửi URL riêng khi tạo link.
- Người dùng đã đăng nhập và có kết nối mạng khi thanh toán.
- Giá và slug gói (`premium-monthly`, 59.000 VNĐ/30 ngày) lấy từ `GET /subscriptions/plans`, giá trị ghi cứng trong app chỉ là dự phòng khi API lỗi.
- Quy ước mã hóa UTF-8 tiếng Việt và các gotcha Flutter trong `PROJECT_AGENT_GUIDE.md` vẫn áp dụng.
