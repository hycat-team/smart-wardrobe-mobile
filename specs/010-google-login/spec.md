# Feature Specification: Đăng nhập bằng Google (Google Sign-In)

**Feature Branch**: `010-google-login`

**Created**: 2026-09-25

**Status**: Draft

**Input**: User description: "làm tính năng logic google gọi API này của BE localhost:8080: 368645245473-u71cfbe461nl51us9dmlta6vfgcdun8a.apps.googleusercontent.com ở môi trường dev (set vào ENV)"

## Clarifications

### Session 2026-09-25

- Q: Tính năng đăng nhập Google v1 nhắm tới nền tảng nào? → A: Android + Web (Chrome dev); iOS để sau.
- Q: Web dùng luồng đăng nhập Google nào? → A: GIS lấy ID token → cùng endpoint như mobile (Bearer).
- Q: Có đưa cơ chế tự động làm mới token (refresh rotation) vào phạm vi feature này không? → A: Có — làm luôn trong feature, dùng chung cho mọi luồng đăng nhập.
- Q: Hành vi liên kết tài khoản khi email Google đã tồn tại? → A: Auto-link như BE; sau khi vào hiển thị thông báo không chặn (SnackBar).

### Session 2026-09-27

- Q: GIS trên web gặp `400: origin_mismatch` (origin dev chưa đăng ký) — xử lý thế nào? → A: Web chuyển sang **luồng redirect do BE điều khiển (guide §1)**, không dùng GIS; Android giữ native ID token + Bearer.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Đăng nhập/đăng ký bằng Google (Priority: P1)

Người dùng ở màn Đăng nhập (hoặc Đăng ký) bấm "Tiếp tục với Google", chọn tài khoản Google của mình, và được đăng nhập vào Closy ngay — tài khoản Closy được tạo tự động nếu là lần đầu, hoặc vào đúng tài khoản cũ nếu email Google (đã xác thực) trùng với tài khoản đang có.

**Why this priority**: Google là kênh đăng nhập/đăng ký ít ma sát nhất, giảm rào cản tạo tài khoản, tăng tỉ lệ hoàn tất onboarding và giữ chân người dùng. Đây là giá trị cốt lõi của tính năng.

**Independent Test**: Từ màn Đăng nhập, bấm nút Google, chọn một tài khoản Google; nếu đăng nhập thành công và người dùng vào được màn chính với phiên hợp lệ (mở được tủ đồ/hồ sơ) thì tính năng đạt giá trị.

**Acceptance Scenarios**:

1. **Given** chưa có tài khoản Closy với email Google hợp lệ, **When** người dùng đăng nhập bằng Google lần đầu, **Then** tài khoản Closy được tạo và người dùng vào màn chính với phiên hợp lệ.
2. **Given** đã có tài khoản Closy (tạo bằng mật khẩu) với email trùng email Google đã xác thực, **When** người dùng đăng nhập bằng Google, **Then** người dùng vào đúng tài khoản cũ (không tạo tài khoản trùng).
3. **Given** người dùng đã đăng nhập, **When** mở lại ứng dụng khi token còn hiệu lực, **Then** người dùng vẫn ở trạng thái đã đăng nhập (không phải đăng nhập Google lại).
4. **Given** người dùng đang thao tác trên nút Google, **When** quá trình đang xử lý, **Then** nút hiển thị trạng thái đang tải và không cho bấm lặp.

---

### User Story 2 - Xử lý lỗi & huỷ đăng nhập Google (Priority: P2)

Người dùng có thể huỷ ở màn chọn tài khoản Google, hoặc gặp các trường hợp từ chối (email Google chưa xác thực, email đã đăng ký bằng mật khẩu, email đã liên kết với Google khác, tài khoản bị khoá, danh tính Google không hợp lệ/hết hạn, lỗi hệ thống). Ứng dụng phải phản hồi rõ ràng, bằng tiếng Việt, không bị treo/crash.

**Why this priority**: Đảm bảo trải nghiệm không gây hoang mang và người dùng biết cách xử lý; đồng thời bảo vệ tính đúng đắn của tài khoản (không liên kết nhầm).

**Independent Test**: Có thể kiểm thử độc lập bằng cách mô phỏng từng kịch bản lỗi/huỷ; mỗi kịch bản cho ra một thông báo đúng và trạng thái UI ổn định.

**Acceptance Scenarios**:

1. **Given** người dùng đang ở màn Google, **When** người dùng huỷ/đóng, **Then** ứng dụng quay lại màn Đăng nhập và không báo lỗi nghiêm trọng.
2. **Given** email Google chưa được xác thực, **When** đăng nhập, **Then** ứng dụng báo "Email Google chưa được xác thực."
3. **Given** email trùng tài khoản đã tồn tại nhưng chưa xác thực, **When** đăng nhập, **Then** ứng dụng báo email đã được đăng ký và gợi ý đăng nhập bằng mật khẩu.
4. **Given** email đã liên kết với tài khoản Google khác, **When** đăng nhập, **Then** ứng dụng báo "Email đã liên kết với tài khoản Google khác."
5. **Given** tài khoản bị khoá, **When** đăng nhập, **Then** ứng dụng báo tài khoản bị vô hiệu hoá và hướng dẫn liên hệ hỗ trợ.
6. **Given** danh tính Google sai/hết hạn hoặc lỗi hệ thống, **When** đăng nhập, **Then** ứng dụng báo lỗi phù hợp và cho phép thử lại.

---

### User Story 3 - Duy trì phiên, làm mới token & đăng xuất (Priority: P3)

Sau khi đăng nhập Google, phiên của người dùng được duy trì an toàn giữa các lần mở app; khi access token hết hạn, ứng dụng tự làm mới; nếu làm mới thất bại thì đăng xuất an toàn về màn Đăng nhập. Khi người dùng đăng xuất, phiên được thu hồi ở hệ thống và xoá khỏi thiết bị.

**Why this priority**: Bảo đảm an toàn và tính liên tục của phiên; là điều kiện để các tính năng khác dùng được danh tính người dùng, nhưng phụ thuộc US1 đã hoạt động.

**Independent Test**: Đăng nhập Google, để access token hết hạn (hoặc giả lập 401), kiểm tra app tự làm mới mà người dùng không bị gián đoạn; sau đó đăng xuất và kiểm tra phiên đã bị thu hồi/xoá.

**Acceptance Scenarios**:

1. **Given** người dùng đã đăng nhập bằng Google, **When** access token hết hạn và người dùng gọi một API cần xác thực, **Then** ứng dụng tự làm mới phiên và tiếp tục thao tác mà không bắt đăng nhập lại.
2. **Given** làm mới phiên thất bại (refresh token hết hạn/bị thu hồi), **When** có API cần xác thực, **Then** ứng dụng đăng xuất và đưa người dùng về màn Đăng nhập.
3. **Given** người dùng đã đăng nhập, **When** người dùng đăng xuất, **Then** phiên bị thu hồi ở hệ thống, token bị xoá khỏi thiết bị và trạng thái ứng dụng được đặt lại sạch cho người dùng kế tiếp.

---

### Edge Cases

- **Không có kết nối / máy chủ dev không chạy**: đăng nhập Google thất bại ở bước đổi phiên — hiển thị thông báo không kết nối được, cho thử lại; không crash.
- **Người dùng đóng màn Google giữa chừng**: coi như huỷ; quay lại màn Đăng nhập, không báo lỗi nghiêm trọng.
- **Danh tính Google hết hạn/không hợp lệ trước khi đổi phiên**: báo phiên Google không hợp lệ, yêu cầu thử lại.
- **Đổi tài khoản Google trên thiết bị**: lần đăng nhập kế tiếp dùng đúng tài khoản người dùng chọn; không rò rỉ phiên của tài khoản trước.
- **Mất mạng ngay sau khi Google trả danh tính**: không lưu phiên dở dang; cho thử lại toàn bộ.
- **Nút Google bấm liên tục**: chỉ xử lý một yêu cầu tại một thời điểm.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Ứng dụng MUST hiển thị nút "Tiếp tục với Google" trên màn Đăng nhập và màn Đăng ký.
- **FR-002**: Khi người dùng chọn đăng nhập Google, ứng dụng MUST thu nhận danh tính Google (ID token) qua luồng đăng nhập của Google phù hợp với nền tảng đang chạy.
- **FR-003**: Ứng dụng MUST gửi danh tính Google kèm tên thiết bị tới hệ thống Closy để đổi lấy cặp phiên (access token + refresh token).
- **FR-004**: Ứng dụng MUST lưu phiên vào kho bảo mật của thiết bị và chỉ chấp nhận token đúng định dạng hợp lệ (tái sử dụng cơ chế lưu token hiện có).
- **FR-005**: Ứng dụng MUST đặt người dùng vào trạng thái đã đăng nhập và điều hướng như đăng nhập thường, bao gồm việc quay lại đích đến đã giữ trước đó nếu có.
- **FR-006**: Tài khoản mới qua Google MUST được tạo tự động; email Google đã xác thực trùng tài khoản hiện có MUST được liên kết vào đúng tài khoản cũ (không tạo trùng). Khi việc liên kết xảy ra, ứng dụng MUST hiển thị thông báo không chặn luồng (SnackBar) cho người dùng.
- **FR-007**: Ứng dụng MUST hiển thị thông báo tiếng Việt tương ứng cho từng trường hợp lỗi (email chưa xác thực, email đã đăng ký bằng mật khẩu, email đã liên kết Google khác, tài khoản bị khoá, danh tính không hợp lệ, lỗi hệ thống, không kết nối được).
- **FR-008**: Khi người dùng huỷ ở màn Google, ứng dụng MUST quay lại màn Đăng nhập mà không hiển thị lỗi nghiêm trọng.
- **FR-009**: Ứng dụng MUST tự động làm mới phiên khi access token hết hạn; nếu làm mới thất bại MUST đăng xuất và đưa người dùng về màn Đăng nhập. Cơ chế này dùng chung cho **mọi luồng đăng nhập** (mật khẩu lẫn Google), không riêng Google.
- **FR-010**: Khi đăng xuất, ứng dụng MUST thu hồi phiên ở hệ thống, xoá token khỏi thiết bị và đặt lại sạch mọi trạng thái gắn với tài khoản (tránh rò rỉ dữ liệu sang tài khoản khác).
- **FR-011**: Google Client ID dùng cho đăng nhập MUST được cấu hình qua biến môi trường **theo từng môi trường** (dev/prod/v2), KHÔNG hardcode trong mã nguồn; đổi môi trường không cần sửa code.
- **FR-012**: Nút Google MUST hiển thị trạng thái đang xử lý và ngăn bấm lặp cho tới khi hoàn tất/thất bại.

### Key Entities *(include if this feature involves data)*

- **Danh tính Google**: Danh tính do Google phát hành cho người dùng (ID token) sau khi người dùng đồng ý; là bằng chứng để hệ thống Closy xác thực.
- **Phiên Closy**: Cặp token (access token ngắn hạn + refresh token dài hạn) đại diện cho phiên đăng nhập của người dùng trong ứng dụng.
- **Tài khoản người dùng**: Hồ sơ người dùng trong Closy, có thể được tạo từ Google hoặc liên kết với một danh tính Google.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Người dùng hoàn tất đăng nhập Google trong vòng dưới 30 giây (không tính thời gian thao tác bên phía Google).
- **SC-002**: 100% các trường hợp lỗi đã liệt kê hiển thị đúng thông báo tiếng Việt tương ứng và không gây crash.
- **SC-003**: Tỉ lệ tạo tài khoản trùng cho người dùng đăng nhập bằng Google với email đã có là 0% (luôn vào đúng tài khoản cũ khi email đã xác thực).
- **SC-004**: Sau khi đăng nhập Google, ít nhất 99% lời gọi tới các chức năng cần xác thực thành công khi phiên còn hiệu lực.
- **SC-005**: Người dùng không phải đăng nhập lại Google khi mở lại ứng dụng trong thời gian phiên còn hiệu lực.
- **SC-006**: Đăng xuất thu hồi phiên thành công và không còn dữ liệu phiên của tài khoản cũ trên thiết bị (0 token còn lại).

## Assumptions

- Hệ thống Closy (backend) đã hỗ trợ đổi danh tính Google lấy phiên và hỗ trợ làm mới/đăng xuất phiên; mobile chỉ cần gọi đúng luồng. Hợp đồng tích hợp tham chiếu: `docs/google-login-frontend-guide.md` (và spec backend `021-google-login`).
- Môi trường dev dùng backend local tại `http://localhost:8080` (đã cấu hình trong `.env`); production dùng endpoint HTTPS thật.
- Google Client ID (loại Web/Server) **phụ thuộc môi trường backend** và được đặt trong biến môi trường (không hardcode): dev `localhost:8080` → `368645245473-u71cfbe461nl51us9dmlta6vfgcdun8a.apps.googleusercontent.com`; prod `api.closy.hycat.online` → `368645245473-5ovjq88e58p97u81asjssbt2bt8bnpt9.apps.googleusercontent.com`; v2 `api-v2.closy.hycat.online` → `368645245473-egk412r1rhc7s0iloms9e4mjh7bptsj3.apps.googleusercontent.com`.
- Nền tảng trong phạm vi v1: **Android + Web (Chrome dev)**; **iOS nằm ngoài phạm vi v1** (làm sau). Cùng một luồng: lấy danh tính Google → đổi phiên qua hệ thống Closy.
- Web dùng **luồng redirect do BE điều khiển** (`GET {API_BASE}/auth/google?redirectUrl=<origin>/auth/callback` → cookie `HttpOnly` → app xác nhận qua `GET /me`); **không dùng GIS** (tránh lỗi `origin_mismatch`). Android dùng **ID token** + Bearer.
- Việc cấu hình Google Cloud (authorized origins/redirect và client theo nền tảng) là phụ thuộc bên ngoài mã nguồn; đội vận hành/dev chịu trách nhiệm.
- Tài khoản chỉ-Google có thể đặt mật khẩu qua luồng quên mật khẩu hiện có (không nằm trong phạm vi UI mới của tính năng này).
- Ứng dụng tái sử dụng cơ chế phiên/điều hướng/an toàn state hiện có (session-scope, auth guard, pending redirect).
- **Ngoài phạm vi v1**: iOS; luồng web redirect/cookie do BE điều khiển; UI đặt/đổi mật khẩu riêng cho tài khoản chỉ-Google (dùng luồng quên mật khẩu hiện có); nút Google ở màn onboarding.
