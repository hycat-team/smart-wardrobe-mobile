# Feature Specification: Community Home, Bulk Add & System Catalog Admin

**Feature Branch**: `012-community-nav-catalog`

**Created**: 2026-09-27

**Status**: Draft

**Input**: User description: "thay thế trang home hiện tại thành trang community và đổi chỗ với wardrobe ở thanh công cụ (ẩn trang home); thêm tính năng nạp nhiều món đồ vào tủ cùng lúc; kiểm tra tủ đồ hệ thống có bị trống không, nếu thật vậy xóa đi; kiểm tra admin có chức năng với tủ đồ hệ thống không, nếu không có thì thêm."

## Context

Ba thay đổi độc lập cho app mobile Closy:
1. **Điều hướng**: thay tab Home bằng **Community**, đổi vị trí với **Wardrobe**, ẩn Home.
2. **Nhập tủ đồ hàng loạt**: nạp **nhiều món cùng lúc** thay vì 1 ảnh/lần.
3. **Tủ đồ hệ thống (system catalog)**: hiện có món nhưng **thiếu ảnh** → thêm vào tủ ra item trắng; và **admin** cần chức năng quản lý tủ hệ thống.

**Phát hiện khi khảo sát:**
- BE: `GET /system-catalog/wardrobe-items` trả 3 món nhưng `fashionItem.imageUrl` rỗng; `POST /wardrobe-items/catalog-init` thêm 3 item nhưng `imageUrl`/`rawImageUrl` rỗng ⇒ app hiển thị trắng.
- BE admin: `GET /api/v1/admin/wardrobe-items`, `PUT/DELETE /api/v1/admin/wardrobe-items/{id}`, admin categories CRUD — **không có POST tạo mới** item hệ thống.
- App mobile: **không có màn admin**; upload hiện dùng `pickImage` (đơn); system catalog đã có chọn nhiều (`initSelected`).

## Clarifications

### Session 2026-09-27

- Q: Tủ đồ hệ thống — sửa dữ liệu ảnh hay bỏ tính năng? → A: **Giữ + sửa dữ liệu ảnh**; app ẩn món thiếu ảnh.
- Q: Phạm vi admin tủ hệ thống trên mobile? → A: **Không làm admin trên mobile** (quản trị ở BE/web) — ngoài phạm vi v1.
- Q: Bổ sung việc fix Google login (nhiều tài khoản GG lại vào cùng 1 tài khoản)? → A: **Thêm vào phạm vi** (US5, P1): mỗi tài khoản Google phải vào đúng tài khoản Closy tương ứng.
- Q: (bổ sung) Tham chiếu logo/tab Community từ FE và ngôn ngữ app? → A: Tab **Community** tham khảo FE — dùng **icon `Globe`** (lucide) + nhãn "Cộng đồng"; brand dùng `logo-only.png`. **Việt hoá toàn bộ UI** (US6).
- Q: Thứ tự tab cuối cùng sau khi thay Home bằng Community và đổi chỗ với Wardrobe? → A: **[Tủ đồ, Cộng đồng, Phối đồ AI, Stylist AI, Hồ sơ]** (Wardrobe ↔ Community đổi chỗ; ẩn Home).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Community thành tab chính, ẩn Home (Priority: P1)

Người dùng mở app thấy tab **Community** thay cho Home; vị trí Community đổi với **Wardrobe**; Home không còn trên thanh công cụ.

**Why this priority**: Thay đổi điều hướng ảnh hưởng toàn bộ trải nghiệm vào app.

**Independent Test**: Mở app → thanh dưới có Community + Wardrobe ở vị trí mới; không còn Home; mọi tab vào đúng màn.

**Acceptance Scenarios**:

1. **Given** app mở, **When** nhìn thanh điều hướng, **Then** không còn tab Home; thứ tự tab là **Wardrobe, Community, AI Outfit, AI Chat, Profile**.
2. **Given** người dùng bấm tab Community, **Then** mở màn Community (không phải Home).
3. **Given** deep-link/route `/home` cũ, **When** truy cập, **Then** chuyển hướng sang Community (không lỗi).
4. **Given** đăng nhập xong, **When** vào app, **Then** tab mặc định là Community (thay cho Home trước đây).

---

### User Story 2 - Nạp nhiều món đồ vào tủ cùng lúc (Priority: P1)

Người dùng chọn **nhiều ảnh một lần** để thêm nhiều món vào tủ đồ; xem tiến trình từng ảnh.

**Why this priority**: Nhập tủ nhanh là nhu cầu thường xuyên; giảm thao tác lặp.

**Independent Test**: Chọn 3–5 ảnh → cả 3–5 món xuất hiện trong tủ (kèm phân tích AI), lỗi từng ảnh không chặn các ảnh khác.

**Acceptance Scenarios**:

1. **Given** ở màn Tủ đồ, **When** chọn nhiều ảnh (thư viện), **Then** từng ảnh được tải lên và mỗi món xuất hiện trong tủ.
2. **Given** một vài ảnh lỗi upload, **When** hoàn tất, **Then** các ảnh thành công vẫn vào tủ; ảnh lỗi báo rõ để thử lại.
3. **Given** người dùng đạt hạn mức gói, **When** chọn vượt số món còn lại, **Then** chặn/thông báo phần vượt, không mất các món hợp lệ.
4. **Given** đang tải, **When** xem UI, **Then** có tiến trình (đã xong/tổng) và khoá thao tác trùng.

---

### User Story 3 - Xử lý tủ đồ hệ thống bị "trống" (Priority: P2)

Tủ đồ hệ thống hiển thị món nhưng khi thêm vào tủ lại ra món không có ảnh. Cần sửa hoặc bỏ tính năng.

**Why this priority**: Gây nhầm lẫn; item rỗng ảnh làm hỏng trải nghiệm tủ.

**Independent Test**: Thêm từ tủ hệ thống → món hiển thị **có ảnh** đúng; nếu bỏ tính năng thì không còn tuỳ chọn "thêm từ tủ hệ thống".

**Acceptance Scenarios**:

1. **Given** món trong tủ hệ thống có ảnh hợp lệ, **When** thêm vào tủ, **Then** món hiển thị đúng ảnh + danh mục.
2. **Given** món hệ thống thiếu ảnh, **Then** không xuất hiện để thêm (hoặc bị ẩn khỏi danh sách).
3. *(Nếu chọn bỏ)* **Given** đã bỏ tính năng, **When** mở luồng thêm đồ, **Then** không còn tuỳ chọn "Tủ đồ hệ thống".

> Chờ trả lời Q1 (sửa dữ liệu ảnh hay bỏ tính năng).

---

### User Story 4 - Admin quản lý tủ đồ hệ thống (Priority: P2) — ⛔ NGOÀI PHẠM VI v1

Quản trị viên xem/sửa/xoá món trong tủ đồ hệ thống và quản lý danh mục.

**Why this priority**: Tủ hệ thống cần được vận hành (dữ liệu ảnh/danh mục) mà hiện app không có công cụ.

**Independent Test**: Tài khoản admin mở khu quản trị → sửa danh mục/giá món hệ thống, xoá món; tài khoản thường không thấy.

**Acceptance Scenarios**:

1. **Given** tài khoản role admin, **When** mở khu quản trị tủ hệ thống, **Then** thấy danh sách món hệ thống (phân trang).
2. **Given** admin chọn 1 món, **When** sửa danh mục/giá/thuộc tính, **Then** lưu thành công và phản ánh ở danh sách.
3. **Given** admin xoá 1 món hệ thống, **Then** món biến mất khỏi tủ hệ thống.
4. **Given** tài khoản không phải admin, **When** cố truy cập, **Then** bị chặn.

> **Q2=C**: KHÔNG làm admin trên mobile v1; quản trị tủ hệ thống thực hiện trên BE/web. (Story giữ để tham chiếu — không triển khai.)

---

### User Story 5 - Mỗi tài khoản Google vào đúng tài khoản Closy (Priority: P1)

Người dùng đăng nhập bằng các tài khoản Google khác nhau; mỗi tài khoản Google phải vào **đúng** tài khoản Closy tương ứng, không dùng chung phiên với tài khoản đã đăng nhập trước đó.

**Why this priority**: Lỗi định danh/bảo mật nghiêm trọng — nhiều tài khoản Google khác nhau lại vào cùng một tài khoản Closy.

**Independent Test**: Đăng xuất → đăng nhập bằng Google B (khác A) → hồ sơ/tủ đồ hiển thị của B, không phải A.

**Acceptance Scenarios**:

1. **Given** đã đăng nhập bằng Google A, **When** đăng xuất rồi đăng nhập bằng Google B, **Then** vào đúng tài khoản Closy của B.
2. **Given** phiên cũ của A còn trong thiết bị, **When** bắt đầu đăng nhập Google B, **Then** app xoá sạch token/phiên cũ trước khi tạo phiên mới.
3. **Given** người dùng chọn "dùng tài khoản khác" ở màn Google, **Then** app tôn trọng tài khoản được chọn (không tự quay lại tài khoản trước).
4. **Given** đăng nhập thành công, **Then** dữ liệu (hồ sơ/tủ đồ) khớp đúng tài khoản vừa chọn.

---

### User Story 6 - Việt hoá toàn bộ giao diện (Priority: P2)

Người dùng thấy toàn bộ giao diện bằng **tiếng Việt** (nhãn tab, tiêu đề, nút, gợi ý nhập, thông báo, trạng thái rỗng/lỗi); tab Community theo phong cách FE.

**Why this priority**: App là sản phẩm tiếng Việt; còn nhiều chuỗi tiếng Anh lẫn lộn gây thiếu chuyên nghiệp.

**Independent Test**: Duyệt các màn chính (đăng nhập, tủ đồ, studio, stylist, community, hồ sơ, marketplace) — không còn chuỗi tiếng Anh trong nhãn/nút/thông báo.

**Acceptance Scenarios**:

1. **Given** bất kỳ màn chính, **When** xem nhãn/nút/tiêu đề, **Then** hiển thị tiếng Việt (không còn "Home/Wardrobe/Profile/Digital Closet/Retry/Search...").
2. **Given** thanh điều hướng, **Then** nhãn tab là **Tủ đồ, Cộng đồng, Phối đồ AI, Stylist AI, Hồ sơ** (icon Community theo FE — `Globe`).
3. **Given** trạng thái rỗng/lỗi/đang tải, **Then** thông báo tiếng Việt.

---

### Edge Cases

- **Hạn mức gói** khi nhập hàng loạt: chỉ nhận số món còn lại, thông báo phần vượt.
- **Mất mạng giữa chừng** khi upload nhiều ảnh: giữ món đã xong, cho thử lại phần lỗi.
- **Ảnh quá lớn**: chặn/nén trước khi upload.
- **Route/Deep-link cũ `/home`**: redirect an toàn sang Community.
- **Admin sai quyền / token hết hạn**: chặn + thông báo.
- **Món hệ thống thiếu ảnh**: không cho thêm (US3).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Thanh điều hướng MUST ẩn **Home** và dùng **Community** thay thế; Home không còn là tab.
- **FR-002**: Community và Wardrobe MUST đổi vị trí cho nhau; thứ tự tab cuối là **[Tủ đồ, Cộng đồng, Phối đồ AI, Stylist AI, Hồ sơ]**.
- **FR-003**: Tab mặc định sau đăng nhập MUST là **Community** (thay cho Home trước đây).
- **FR-004**: Route/deep-link `/home` cũ MUST chuyển hướng an toàn sang Community (không lỗi).
- **FR-005**: App MUST cho phép chọn **nhiều ảnh cùng lúc** để thêm nhiều món vào tủ.
- **FR-006**: Mỗi ảnh MUST được xử lý độc lập (upload + phân tích AI); lỗi một ảnh MUST KHÔNG chặn các ảnh khác.
- **FR-007**: UI MUST hiển thị tiến trình tổng (đã xong/tổng) và khoá bấm lặp khi đang tải.
- **FR-008**: App MUST tôn trọng hạn mức gói khi thêm hàng loạt; thông báo phần vượt.
- **FR-009**: Món thêm từ tủ đồ hệ thống MUST hiển thị đúng ảnh + danh mục; món hệ thống **thiếu ảnh** MUST bị ẩn/không cho thêm.
- **FR-010**: (Q1=A) Giữ tính năng tủ đồ hệ thống; app MUST **ẩn/không cho thêm** món hệ thống **thiếu ảnh**; BE MUST bổ sung ảnh cho món mẫu để thêm được đúng ảnh + danh mục.
- **FR-011**: Khu quản trị admin **ngoài phạm vi mobile v1** (Q2=C) — quản trị tủ hệ thống/danh mục thực hiện trên BE/web.
- **FR-012**: Đăng nhập Google MUST vào **đúng tài khoản Closy** khớp tài khoản Google được chọn; đăng nhập bằng tài khoản Google khác MUST **KHÔNG** dùng lại tài khoản/phiên trước đó.
- **FR-013**: Khi bắt đầu phiên đăng nhập Google mới, app MUST **xoá token/phiên cũ** trước khi tạo phiên mới; màn chọn tài khoản Google MUST cho phép **chọn tài khoản khác** (không tự tái dùng tài khoản trước).
- **FR-014**: Các thay đổi điều hướng MUST giữ nguyên hoạt động deep-link/guard/`pendingRedirect` hiện có.
- **FR-015**: Thanh điều hướng MUST dùng nhãn **tiếng Việt**: **Tủ đồ, Cộng đồng, Phối đồ AI, Stylist AI, Hồ sơ**.
- **FR-016**: Tab Community MUST dùng **icon tham chiếu FE** (`Globe`/quả cầu) và giữ phong cách Quiet Luxury (đồng nhất size/màu với các tab khác).
- **FR-017**: Toàn bộ **chuỗi hiển thị UI** (nhãn, nút, tiêu đề, gợi ý nhập, thông báo, trạng thái rỗng/lỗi/đang tải) MUST là **tiếng Việt**; giữ nguyên tên riêng/thương hiệu/tên model (vd "Closy", "THE ROW").
- **FR-018**: Việc Việt hoá MUST **không đổi hành vi** (route, logic, test keys không liên quan chuỗi hiển thị).

### Key Entities

- **SystemCatalogItem**: món mẫu hệ thống (id, danh mục, thuộc tính, **ảnh**, giá) dùng để người dùng thêm vào tủ.
- **WardrobeItem**: món trong tủ người dùng (được tạo từ upload hoặc từ món hệ thống).
- **AdminUser**: tài khoản có quyền quản trị (role admin) để vận hành tủ hệ thống/danh mục.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% lối vào app dùng Community làm tab chính; 0 lỗi điều hướng sau thay đổi.
- **SC-002**: Người dùng thêm **≥3 món trong 1 thao tác chọn ảnh**, tỉ lệ thành công ≥ 95% (ảnh hợp lệ).
- **SC-003**: 100% món thêm từ tủ hệ thống hiển thị **có ảnh** (món thiếu ảnh bị ẩn; BE bổ sung ảnh cho món mẫu).
- **SC-004**: 100% ca kiểm thử với **≥2 tài khoản Google khác nhau** vào đúng tài khoản Closy tương ứng (0 ca dùng chung tài khoản).
- **SC-005**: Không hồi quy: deep-link thanh toán/wardrobe/community vẫn hoạt động sau đổi nav.
- **SC-006**: **0 chuỗi tiếng Anh** còn lại trong **các màn người dùng thấy** (đăng nhập, tủ đồ, studio, stylist, community, hồ sơ, marketplace, thanh toán) — kiểm bằng rà soát thủ công.

## Assumptions

- Thứ tự tab cuối (đã chốt ở Clarifications): **[Tủ đồ, Cộng đồng, Phối đồ AI, Stylist AI, Hồ sơ]** (Home ẩn hoàn toàn).
- Việc "nạp nhiều món" chủ yếu là **chọn nhiều ảnh để upload**; thêm nhiều từ **tủ hệ thống** đã có sẵn (giữ nguyên).
- Món hệ thống thiếu ảnh là **lỗi dữ liệu** (BE); cần sửa dữ liệu nếu chọn giữ tính năng.
- BE đã có `GET/PUT/DELETE /admin/wardrobe-items` + admin categories; **chưa có** endpoint tạo mới món hệ thống.
- Khu **admin trên mobile ngoài phạm vi v1** (Q2=C).
- Lỗi "nhiều tài khoản Google vào cùng 1 tài khoản" là **bug định danh/phiên** (chưa xác định gốc): nghi do app tái dùng phiên/token cũ hoặc luồng Google tự chọn lại tài khoản trước — sẽ điều tra ở `/speckit.plan`/implement.
- **Việt hoá**: phạm vi là **chuỗi hiển thị** (không dịch code/route/test); ưu tiên các màn người dùng thấy nhiều. Chuỗi tiếng Anh hiện có (vd: `Home/Wardrobe/AI Outfit/AI Chat/Profile`, `Digital Closet`, `Retry`, `Search curate pieces...`) sẽ được thay.
- **Community tab**: FE dùng icon lucide **`Globe`** cho "Cộng Đồng"; mobile dùng icon tương đương (`Icons.public`) + nhãn "Cộng đồng".
