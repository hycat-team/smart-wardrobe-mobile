# Feature Specification: Home Stats Infinite Scroll

**Feature Branch**: `006-home-stats-infinite-scroll`

**Created**: 2026-09-14

**Status**: Draft

**Input**: User description: "lên plan fix UI/UX mô tả lỗi hiện tại: 1. trang home call api theo trang thống kê tủ đồ 2. trang wardrobe và outfit list update thêm scroll vô hạn khi scroll hết item của 1 trang kéo xuống sẽ load thêm"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Trang Home hiển thị số liệu đúng như trang Thống kê (Priority: P1)

Người dùng mở trang Home thấy các con số tổng quan (tổng số món trong tủ, tổng số outfit đã lưu, giá trị tủ đồ, phân bổ danh mục) trùng khớp với con số trên trang Thống kê tủ đồ. Khi kéo làm mới ở Home, số liệu cả hai trang cùng cập nhật. Khi mất mạng, Home báo rõ không tải được số liệu thay vì hiện số thiếu.

**Why this priority**: Home là màn hình đầu tiên người dùng thấy; số liệu sai (thiếu do chỉ đếm món đã tải về) gây mất niềm tin ngay từ cái nhìn đầu tiên và lệch với trang Thống kê.

**Independent Test**: Có thể kiểm thử độc lập bằng cách mở Home ghi lại các con số → mở trang Thống kê → so sánh trùng khớp; thêm 1 món mới → làm mới cả hai → cùng tăng.

**Acceptance Scenarios**:

1. **Given** người dùng có hơn 1 trang món đồ (vd 35 món), **When** mở trang Home, **Then** tổng số món hiển thị là 35 (số thật từ thống kê), không phải 20 (số món của trang đầu).
2. **Given** người dùng đang ở Home, **When** kéo làm mới, **Then** số liệu thống kê trên Home được tải lại cùng lúc với danh sách, không giữ số cũ.
3. **Given** mất mạng khi mở Home, **When** phần số liệu chưa tải được, **Then** Home hiển thị trạng thái lỗi + nút thử lại cho đúng phần đó, các phần khác (lời chào, banner) vẫn hiện bình thường.

---

### User Story 2 - Kéo hết danh sách tự tải thêm (Wardrobe) (Priority: P1)

Người dùng kéo xuống cuối lưới tủ đồ thì các món trang tiếp theo tự động tải thêm và nối vào danh sách, kèm chỉ báo đang tải ở cuối. Khi đã hết món, chỉ báo biến mất (hoặc hiện "đã hết"). Kéo làm mới hoặc đổi danh mục lọc thì danh sách quay về trang đầu.

**Why this priority**: Tủ đồ trên 20 món hiện không xem được món cũ — người dùng tưởng mất đồ. Quan trọng ngang US1 và độc lập.

**Independent Test**: Có thể kiểm thử độc lập bằng tài khoản có 35 món: kéo tới cuối → thấy thêm món + chỉ báo tải → hết thì dừng; đổi danh mục → reset về đầu.

**Acceptance Scenarios**:

1. **Given** người dùng có 35 món và đang xem 20 món đầu, **When** kéo tới gần cuối danh sách, **Then** 15 món còn lại tự tải thêm và nối tiếp, hiện chỉ báo tải trong lúc chờ.
2. **Given** đã tải hết toàn bộ món, **When** kéo tới cuối, **Then** không gọi tải thêm nữa và không hiện chỉ báo tải mãi.
3. **Given** người dùng đang ở trang 2 của danh sách, **When** đổi danh mục lọc hoặc kéo làm mới, **Then** danh sách quay về trang đầu của bộ lọc mới, không lẫn món của bộ lọc cũ.
4. **Given** đang tải thêm thì mất mạng, **When** yêu cầu thất bại, **Then** danh sách giữ nguyên các món đã có, hiện thông báo lỗi nhẹ và cho kéo thử lại (không mất vị trí cuộn).

---

### User Story 3 - Kéo hết danh sách tự tải thêm (Outfit) (Priority: P2)

Người dùng kéo xuống cuối lưới outfit thì các outfit trang tiếp theo tự tải thêm, cùng hành vi chỉ báo/hết danh sách/lỗi như tủ đồ. Danh sách outfit đông (trên 50 bộ) vẫn duyệt được hết.

**Why this priority**: Cùng lỗi UX như Wardrobe nhưng outfit thường ít hơn nên mức độ thấp hơn; triển khai cùng mẫu để nhất quán.

**Independent Test**: Có thể kiểm thử độc lập bằng tài khoản có trên 50 outfit: kéo tới cuối trang đầu → outfit tiếp theo hiện ra.

**Acceptance Scenarios**:

1. **Given** người dùng có trên 50 outfit, **When** kéo tới gần cuối danh sách, **Then** outfit trang tiếp theo tự tải thêm và nối tiếp.
2. **Given** đã tải hết toàn bộ outfit, **When** kéo tới cuối, **Then** không gọi tải thêm nữa.
3. **Given** đang ở chế độ chọn nhiều để xóa, **When** tải thêm trang mới, **Then** lựa chọn đã tick được giữ nguyên, món mới thêm vào không tự tick.

---

### Edge Cases

- Thêm/xóa món khi đang ở trang 2+ — tổng số cập nhật đúng, danh sách không trùng/khuyết món sau khi tải lại.
- Đổi danh mục khi request trang cũ chưa về — kết quả cũ về trễ bị bỏ, không lẫn vào danh mục mới.
- Kéo nhanh liên tục tới cuối nhiều lần — chỉ có 1 request tải thêm tại 1 thời điểm, không tải trùng trang.
- Tổng số món = 0 — hiện trạng thái trống như cũ, không hiện chỉ báo tải thêm.
- Số món vừa đúng bội số của kích thước trang (vd đúng 40 món, trang 20) — app nhận biết hết danh sách sau 1 lần gọi rỗng, không kẹt chỉ báo tải.
- Home mở khi chưa đăng nhập (khách khám phá) — phần số liệu hiện trạng thái phù hợp, không crash, không hiện số giả.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Trang Home MUST lấy các con số tổng quan (tổng món, tổng outfit, giá trị tủ, phân bổ danh mục) từ cùng nguồn số liệu với trang Thống kê tủ đồ, không tự đếm từ danh sách phân trang.
- **FR-002**: Các con số trên Home và trang Thống kê MUST trùng nhau tại cùng thời điểm sau khi làm mới.
- **FR-003**: Kéo làm mới ở Home MUST tải lại cả số liệu thống kê, không chỉ tải lại danh sách.
- **FR-004**: Khi số liệu thống kê chưa tải được (đang tải/lỗi mạng), Home MUST hiển thị trạng thái tương ứng (chờ/thử lại) cho đúng phần số liệu, không hiển thị số thiếu như số thật.
- **FR-005**: Danh sách Wardrobe MUST tự tải trang tiếp theo khi người dùng kéo tới gần cuối, nối món mới vào cuối danh sách hiện tại kèm chỉ báo đang tải.
- **FR-006**: Danh sách Outfit MUST tự tải trang tiếp theo khi kéo tới gần cuối, hành vi chỉ báo giống Wardrobe.
- **FR-007**: Khi đã tải hết (số món hiện có đạt tổng số), cả hai danh sách MUST dừng gọi tải thêm.
- **FR-008**: Món tải thêm MUST NOT trùng với món đã có (kể cả khi dữ liệu thay đổi giữa chừng, trùng id thì gộp lại).
- **FR-009**: Đổi bộ lọc danh mục hoặc kéo làm mới MUST đưa danh sách về trang đầu và xóa món của bộ lọc/trang cũ.
- **FR-010**: Trong lúc 1 request tải thêm đang chạy, hệ thống MUST NOT gửi thêm request tải thêm khác cho cùng danh sách.
- **FR-011**: Tải thêm thất bại MUST giữ nguyên danh sách và vị trí cuộn, báo lỗi nhẹ và cho thử lại bằng cách kéo tiếp.
- **FR-012**: Chế độ chọn nhiều (xóa hàng loạt) MUST giữ nguyên lựa chọn khi tải thêm trang mới.

### Key Entities

- **Số liệu thống kê tủ đồ (Wardrobe Stats)**: Số tổng quan của người dùng — gồm tổng món, tổng outfit, giá trị tủ, phân bổ theo danh mục; là nguồn chuẩn cho cả Home và trang Thống kê.
- **Trang danh sách (List Page)**: Một đợt món/outfit tải về — gồm danh sách món, số trang hiện tại, tổng số; các trang nối tiếp nhau thành danh sách đầy đủ.
- **Trạng thái tải thêm (Load-more State)**: Trạng thái cuối danh sách — đang tải / đã hết / lỗi thử lại.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% lần so sánh song song (10/10 lượt) các con số Home trùng khớp trang Thống kê sau khi làm mới.
- **SC-002**: Tài khoản 35 món: kéo 1 lần tới cuối tải đủ 35 món trong vòng 5 giây (mạng ổn định), 0 món trùng, 0 món thiếu.
- **SC-003**: Tài khoản trên 50 outfit: kéo tới cuối tải đủ toàn bộ, không dừng ở 50.
- **SC-004**: 0 request trùng lặp khi kéo nhanh 5 lần liên tiếp tới cuối (kiểm tra log mạng).
- **SC-005**: Đổi danh mục 10/10 lần đều reset về trang đầu, không lẫn món cũ.
- **SC-006**: Không hồi quy: kéo làm mới, lọc danh mục, xóa đơn/xóa hàng loạt, mở chi tiết vẫn đúng 100% trong 20 lượt test.

## Assumptions

- Nguồn số liệu thống kê hiện có của trang Thống kê (tổng quan + phân bổ danh mục) dùng được chung cho Home, không cần nguồn mới.
- Kích thước 1 trang giữ nguyên như hiện tại (tủ đồ 20 món, outfit 50 bộ); chỉ thêm cơ chế tải nối tiếp.
- Tổng số món/outfit do hệ thống trả về là chuẩn để xác định hết danh sách (kèm 1 lần gọi rỗng dự phòng khi tổng là bội số của kích thước trang).
- Trang Home của teammate (chưa merge) là nền để gắn số liệu; nếu cấu trúc Home đổi, giai đoạn plan điều chỉnh điểm gắn.
- Người dùng test trên tài khoản có trên 20 món và trên 50 outfit để kiểm chứng tải thêm.
