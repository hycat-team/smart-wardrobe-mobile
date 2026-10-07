# Feature Specification: Sửa nháy màn login, tràn viền Up bài, gợi ý AI sai

**Feature Branch**: `015-fix-login-stylist-composer`

**Created**: 2026-10-02

**Status**: Draft

**Input**: User description: "Thêm loading screen cho màng hình đăng nhập lúc lấy token (hạn chế hiện lại màng hình login); Up bài lỗi tràn viền; AI chat hiện tại đang không chính xác, nếu gợi ý phối đồ thì cũng gợi ý ra hình ảnh không xem được"

## Overview

Ba lỗi độc lập, cùng được báo trong một đợt QA và ảnh hưởng trực tiếp tới độ tin cậy của app:

1. **Nháy màn hình đăng nhập** — mở app hoặc refresh trình duyệt luôn thấy form đăng nhập trước khi hệ thống biết người dùng đã đăng nhập hay chưa.
2. **Tràn viền ở màn Up bài** — dải "HÌNH ẢNH & VIDEO" cùng hai nút "Thêm ảnh" / "Thêm video" tràn ra ngoài khung khi cửa sổ hẹp.
3. **Gợi ý phối đồ sai và ảnh không xem được** — khi hỏi stylist về cách phối đồ, các thẻ gợi ý hiện ra **trống/rỗng** thay vì hiện món đồ thật, và khi hệ thống gợi ý lỗi nó vẫn trả về một bộ gợi ý cứng không liên quan tới tủ đồ.

Lý do gốc của (3) là **lệch hợp đồng dữ liệu** giữa app và máy chủ, không phải lỗi hiển thị. Phạm vi sửa **chỉ trong app**; máy chủ giữ nguyên.

## Clarifications

### Session 2026-10-02

- Q: Khi kiểm tra phiên thất bại (mất mạng hoặc máy chủ lỗi), có xoá phiên đăng nhập đang có không? → A: Phân biệt nguyên nhân — lỗi mạng/máy chủ lỗi thì **giữ phiên** và cho thử lại; chỉ khi token thật sự không hợp lệ mới xoá phiên.
- Q: Khi hạn mức gợi ý đã cạn và máy chủ trả về bộ gợi ý dự phòng của riêng nó, ứng dụng hiển thị thế nào? → A: Hiển thị kèm **nhãn rõ là gợi ý dự phòng**, và hiện số hạn mức còn lại khi đã cạn.
- Q: Nhãn vai trò tiếng Việt lấy từ đâu khi máy chủ trả vai trò bằng tiếng Anh? → A: Ứng dụng tự ánh xạ bằng **danh sách đóng**; vai trò lạ thì hiển thị nguyên chuỗi gốc máy chủ trả về.
- Q: Ngưỡng chống nháy của màn hình khởi động nên đặt bao nhiêu? → A: **1 giây** — ưu tiên tốc độ, chấp nhận có lúc splash chỉ thoáng qua.
- Q: Splash có luôn hiện không, hay chỉ hiện khi kiểm tra phiên chậm? → A: **Luôn hiện** ở mọi lần khởi động, tự ẩn sau tối đa 1 giây; có trường hợp bỏ qua splash thì coi là lỗi.
- Q: Khi hạn mức gợi ý cạn, hiển thị thông tin gì vì máy chủ không có mốc thời gian làm mới? → A: Chỉ hiện **số hạn mức còn lại** kèm hướng dẫn chung rằng gợi ý tự làm mới vào ngày mới.
- Q: Vai trò, nhãn dự phòng và số hạn mức được mang theo ở đâu? → A: **Mở rộng model hiển thị sẵn có của stylist** bằng ba trường này, không tạo bộ model phẳng mới song song.
- Q: Khi giữ phiên nhưng không lấy được hồ sơ vì lỗi mạng, người dùng thấy gì? → A: **Giữ ở màn hình khởi động** kèm thông báo và nút "Thử lại"; không cho vào app cho tới khi lấy được hồ sơ.
- Q: Có tự thử lại trong khi chờ không, hay chỉ chờ người dùng bấm? → A: **Chỉ thử lại khi người dùng bấm.** Không có yêu cầu nào tự phát sinh.
- Q: Khi đăng xuất hoặc đổi tài khoản **giữa phiên**, có hiện màn hình khởi động không? → A: **Không.** Splash chỉ hiện khi khởi động ứng dụng; đăng xuất/đổi tài khoản thì chuyển thẳng sang màn đăng nhập.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Mở app thấy splash thay vì màn đăng nhập (Priority: P1)

Một người dùng đã đăng nhập trước đó mở app trên điện thoại, hoặc nhấn F5 trên trình duyệt web. Họ thấy một màn hình khởi động ngắn, sau đó vào thẳng màn tủ đồ. Họ **không** bị đưa ra màn đăng nhập rồi mới bị đưa vào lại.

**Why this priority**: Đây là ấn tượng đầu tiên mỗi phiên và xảy ra với 100% người dùng. Nháy màn đăng nhập khi đã đăng nhập khiến người dùng tưởng bị đăng xuất, và nhiều người sẽ bấm nhầm vào nút đăng nhập Google.

**Independent Test**: Xoá toàn bộ trạng thái điều hướng, khởi động lại app khi đã đăng nhập → phải thấy splash rồi vào tủ đồ, không thấy form đăng nhập.

**Acceptance Scenarios**:

1. **Given** người dùng đã đăng nhập và có phiên hợp lệ, **When** mở app lần đầu, **Then** hiện màn hình khởi động và vào thẳng tủ đồ, không hiển thị form đăng nhập ở bất kỳ thời điểm nào.
2. **Given** người dùng đang đăng nhập trên trình duyệt web, **When** nhấn tải lại trang, **Then** quá trình tương tự lần 1 — không thấy form đăng nhập.
3. **Given** người dùng chưa từng đăng nhập, **When** mở app, **Then** sau màn hình khởi động thì hiện form đăng nhập như bình thường.
4. **Given** phiên đã hết hạn, **When** mở app, **Then** sau màn hình khởi động thì hiện form đăng nhập, và dữ liệu phiên cũ bị xoá.
5. **Given** không có mạng, **When** mở app, **Then** ứng dụng không treo vô hạn ở màn hình khởi động — nếu đang có phiên hợp lệ thì **giữ nguyên phiên** và ở lại màn hình khởi động kèm thông báo tạm thời cùng nút "Thử lại"; nếu chưa có phiên thì hiện màn đăng nhập kèm thông báo không kết nối được máy chủ.
6. **Given** máy chủ từ chối token đang lưu, **When** mở app, **Then** phiên bị xoá và hiển thị màn đăng nhập.
7. **Given** đang chờ ở màn hình khởi động vì lỗi mạng, **When** bấm "Thử lại" và mạng đã trở lại, **Then** ứng dụng lấy được hồ sơ và vào thẳng tủ đồ, phiên vẫn nguyên vẹn.

---

### User Story 2 - Đang lấy token thì không thao tác lại được (Priority: P1)

Người dùng bấm "Đăng nhập". Trong lúc ứng dụng đang kiểm tra thông tin đăng nhập với máy chủ, toàn bộ màn hình bị phủ lại; không thể bấm nút đăng nhập lần nữa. Sau đó ứng dụng vào thẳng màn hình chính.

**Why this priority**: Nếu không chặn, người dùng bấm liên tục sẽ gửi nhiều yêu cầu đăng nhập cùng lúc, dễ dẫn tới phiên bị ghi đè hoặc báo sai mật khẩu một cách khó hiểu.

**Independent Test**: Bấm Đăng nhập rồi quan sát màn hình trong lúc chờ → phải thấy lớp phủ chặn tương tác; bấm nhiều lần liên tiếp chỉ tạo ra một yêu cầu.

**Acceptance Scenarios**:

1. **Given** đã nhập tài khoản và mật khẩu hợp lệ, **When** bấm Đăng nhập, **Then** toàn màn hình bị phủ lại với trạng thái đang xử lý và không thể tương tác cho tới khi có kết quả.
2. **Given** đang trong trạng thái đang xử lý, **When** người dùng cố bấm lại nút Đăng nhập nhiều lần, **Then** hệ thống bỏ qua và chỉ gửi **một** yêu cầu.
3. **Given** thông tin đăng nhập sai, **When** hoàn tất xử lý, **Then** lớp phủ biến mất, người dùng thấy thông báo lỗi tiếng Việt và có thể sửa lại.
4. **Given** đang trong trạng thái đang xử lý đăng nhập Google, **When** người dùng đổi ý và quay lại, **Then** ứng dụng thoát trạng thái đang xử lý và không kẹt vĩnh viễn.

---

### User Story 3 - Màn Up bài không tràn viền trên màn hình hẹp (Priority: P2)

Người dùng mở màn viết bài cộng đồng. Dải tiêu đề "HÌNH ẢNH & VIDEO (n/10)" và hai nút "Thêm ảnh", "Thêm video" hiển thị trọn vẹn. Trên cửa sổ hẹp, các nút tự xuống dòng thay vì tràn ra ngoài màn hình.

**Why this priority**: Tràn viền làm mất chức năng — nút bị cắt bởi mép màn hình có thể không bấm được, và dải đỏ cảnh báo phủ lên giao diện, phá vỡ cảm giác chỉn chu của sản phẩm.

**Independent Test**: Thu nhỏ cửa sổ trình duyệt xuống khoảng 320px rồi mở màn Up bài → không có dải cảnh báo tràn, mọi nút vẫn bấm được.

**Acceptance Scenarios**:

1. **Given** cửa sổ hẹp, **When** mở màn Up bài, **Then** tiêu đề và hai nút đều hiển thị đầy đủ, nội dung không vượt ra ngoài khung.
2. **Given** cửa sổ hẹp không đủ chỗ cho cả tiêu đề lẫn hai nút trên một dòng, **When** hiển thị, **Then** các nút tự xuống dòng và vẫn bấm được.
3. **Given** cửa sổ rộng, **When** hiển thị, **Then** bố cục giữ nguyên như hiện tại.
4. **Given** đã thêm đủ 10 tệp, **When** nhìn dải này, **Then** bộ đếm hiện "(10/10)" và cả hai nút hiển thị ở trạng thái không bấm được như quy định hiện hành.

---

### User Story 4 - Gợi ý phối đồ hiện đúng món đồ kèm ảnh thật (Priority: P1)

Người dùng hỏi stylist "gợi ý phối đồ cho đi đi làm". Stylist trả lời bằng văn bản, kèm dải thẻ gợi ý món đồ — **mỗi thẻ hiện đúng tên món và hình ảnh xem được**, phân biệt được các vai trò như áo, quần, giày.

**Why this priority**: Đây là tính năng cốt lõi định vị của sản phẩm. Gợi ý ra ảnh vỡ hoặc trống khiến tính năng trông như hỏng hoàn toàn, và người dùng không có cách nào biết món nào được gợi ý.

**Independent Test**: Đặt câu hỏi về phối đồ trong stylist → dải thẻ hiện, không thẻ nào trống, mọi ảnh tải được.

**Acceptance Scenarios**:

1. **Given** người dùng hỏi về cách phối đồ, **When** stylist trả lời, **Then** dải thẻ gợi ý hiển thị tên món, thương hiệu nếu có, và hình ảnh tải được.
2. **Given** dữ liệu gợi ý có nhiều món, **When** hiển thị, **Then** không có thẻ nào bị trống; món nào thiếu ảnh thì hiện nhãn vai trò thay vì biểu tượng vỡ.
3. **Given** người dùng hỏi về thời tiết, màu sắc hoặc dịp, **When** stylist trả lời, **Then** phần gợi ý món đồ không xuất hiện nếu câu hỏi không liên quan tới cách phối đồ.
4. **Given** người dùng tải lại lịch sử một cuộc trò chuyện cũ, **When** cuộc trò chuyện mở ra, **Then** nội dung trò chuyện hiển thị đầy đủ và không báo lỗi.

---

### User Story 5 - Lỗi gợi ý được thông báo thay vì bị giấu (Priority: P2)

Người dùng hỏi về cách phối đồ nhưng máy chủ không trả lời được. Ứng dụng giữ nguyên phần trò chuyện đã có và cho biết rằng phần gợi ý món đồ tạm thời không có — thay vì tự động thay bằng một bộ gợi ý không liên quan.

**Why this priority**: Bộ gợi ý cứng bị trộn lẫn vào câu trả lời khiến người dùng tin rằng đó là gợi ý thật của stylist, nhưng không khớp với tủ đồ của họ. Im lặng nuốt lỗi cũng khiến không ai sửa được.

**Independent Test**: Gọi API gợi ý trong điều kiện lỗi → có thông báo, không có bộ gợi ý cứng nào xuất hiện.

**Acceptance Scenarios**:

1. **Given** yêu cầu gợi ý món đồ thất bại, **When** trả lời hoàn tất, **Then** phần trò chuyện hiển thị nguyên văn, kèm thông báo gợi ý món đồ tạm thời không có.
2. **Given** yêu cầu gợi ý thất bại, **When** người dùng đọc lại cuộc trò chuyện, **Then** không thấy bất kỳ danh sách món nào không liên quan tới câu hỏi.
3. **Given** yêu cầu gợi ý món đồ thất bại, **When** người dùng hỏi lại, **Then** ứng dụng thử lại được thay vì kẹt ở trạng thái lỗi.
4. **Given** hạn mức gợi ý đã cạn và máy chủ trả về gợi ý dự phòng của riêng nó, **When** người dùng đọc câu trả lời, **Then** bộ gợi ý có nhãn "gợi ý dự phòng", hiện số hạn mức còn lại kèm thông báo gợi ý tự làm mới vào ngày mới, không hiển thị ngày giờ cụ thể, và không bị trình bày như gợi ý chuẩn của stylist.

### Edge Cases

- Mở app khi **vừa mới thoát hẳn** (không còn dữ liệu phiên): phải hiện splash rồi tới form đăng nhập, không nháy qua tủ đồ.
- Phiên hợp lệ nhưng máy chủ chậm: splash phải tự kết thúc, không giữ nguyên vô hạn.
- Phiên hợp lệ nhưng **không có mạng lúc mở app**: phiên phải được giữ nguyên, người dùng **ở lại màn hình khởi động** kèm thông báo tạm thời và nút "Thử lại", và không bị đưa ra màn đăng nhập. Ngưỡng 1 giây **không** áp dụng cho tình huống này.
- Máy chủ báo lỗi tạm thời (không phải từ chối token) khi kiểm tra phiên: hành xử như mất mạng — giữ phiên, ở lại màn hình khởi động, cho thử lại.
- Người dùng bấm "Thử lại" nhiều lần liên tiếp khi vẫn còn lỗi: không được tạo ra một loạt yêu cầu dồn dập.
- Người dùng bấm "Thử lại" và lần này máy chủ trả **token không hợp lệ** (trường hợp hiếm nhưng có thể xảy ra): phải xoá phiên và chuyển sang màn đăng nhập, không phải quay lại vòng chờ.
- Người dùng để ứng dụng đứng yên ở màn hình khởi động rồi quay lại app sau vài phút: **không** được tự thử lại nếu người dùng chưa bấm — màn hình phải vẫn chờ (FR-035).
- Bấm Đăng nhập rồi bấm nút "Quay lại" trong khi đang xử lý: phải thoát được trạng thái đang xử lý.
- **Đăng xuất hoặc đổi tài khoản giữa phiên** (cả nút Đăng xuất lẫn luồng Google): phải chuyển thẳng sang màn đăng nhập, **không** nháy qua màn hình khởi động.
- Tải lại trang web (F5) giữa lúc đang ở trong app: coi như khởi động ứng dụng → phải hiện màn hình khởi động.
- Người dùng chưa đăng nhập bấm Đăng nhập Google rồi huỷ chọn tài khoản: không được kẹt ở lớp phủ đang xử lý.
- Màn Up bài ở cửa sổ cực hẹp (khoảng 300px) và khi tiêu đề đã đếm "(10/10)".
- Stylist trả về món đồ không có ảnh, hoặc trả về danh sách rỗng.
- Stylist trả về món từ thương hiệu thay vì tủ đồ (có `brandItem` thay `fashionItem`).
- Hạn mức gợi ý đã cạn: máy chủ trả về bộ dự phòng của riêng nó — ứng dụng phải gắn nhãn dự phòng và hiện số hạn mức còn lại (bằng 0).
- Máy chủ trả về một nhóm vai trò mà cả món chính lẫn món thay thế đều không có địa chỉ ảnh.
- Máy chủ trả về vai trò **chưa có trong bảng ánh xạ** của ứng dụng: phải hiển thị nguyên chuỗi gốc, không ẩn nhãn.
- Trò chuyện cũ được tải lại từ máy chủ: máy chủ không lưu phần gợi ý món đồ trong từng tin nhắn.
- **Thẻ gợi ý mất vĩnh viễn sau khi tải lại lịch sử** — đây là **giới hạn đã biết và được
  chấp nhận**, không phải hồi quy (spec 015 — T055, chốt 2026-10-02). Máy chủ không lưu kết
  quả gợi ý và ứng dụng không cache cục bộ, nên không có gì để khôi phục. Người dùng hỏi lại
  là thẻ hiện trở lại. Phương án lưu cục bộ đã được cân nhắc và loại vì tăng phạm vi ngoài đặc
  tả; xem `quickstart.md` §K11.

## Requirements *(mandatory)*

### Functional Requirements

**Nhóm A — Trạng thái phiên và màn hình khởi động**

- **FR-001**: Hệ thống MUST phân biệt được **bốn** trạng thái phiên:
 1. *Đang kiểm tra* — trạng thái mặc định lúc khởi động. MUST khác trạng thái *Chưa đăng nhập*, và phải đặt lại khi người dùng bấm **Thử lại**.
 2. *Đã đăng nhập* — kiểm tra thành công, đã có hồ sơ người dùng.
 3. *Lỗi tạm thời* — kiểm tra thất bại do mạng hoặc máy chủ, nhưng token chưa bị từ chối. Phiên **được giữ**, người dùng ở lại màn hình khởi động. Trạng thái này kết thúc khi thử lại thành công (→ *Đã đăng nhập*) hoặc khi máy chủ từ chối token (→ *Chưa đăng nhập*).
 4. *Chưa đăng nhập* — không có token, hoặc token đã bị từ chối.
- **FR-002**: Hệ thống MUST kết thúc trạng thái *đang kiểm tra* trong mọi trường hợp kết thúc của việc kiểm tra phiên, gồm cả khi không có mạng hoặc máy chủ lỗi.
- **FR-026**: Khi kiểm tra phiên thất bại, hệ thống MUST phân biệt hai nguyên nhân: lỗi tạm thời (không có mạng, máy chủ không phản hồi hoặc báo lỗi) và token không còn hợp lệ.
- **FR-027**: Với lỗi tạm thời, hệ thống MUST **giữ nguyên** phiên đăng nhập đang có (không xoá token) và MUST **không** cho người dùng vào app cho tới khi lấy được hồ sơ. Trong lúc chờ, ứng dụng MUST giữ người dùng ở màn hình khởi động, hiển thị thông báo lỗi tạm thời bằng tiếng Việt, và cung cấp nút **Thử lại** để kiểm tra lại.
- **FR-035**: Trong lúc chờ ở màn hình khởi động, ứng dụng MUST **không** tự phát sinh yêu cầu kiểm tra lại. Việc thử lại chỉ xảy ra khi người dùng bấm nút **Thử lại**. Ứng dụng MUST NOT có vòng lặp tự thử lại theo thời gian.
- **FR-028**: Chỉ khi máy chủ từ chối token, hệ thống MUST xoá phiên đăng nhập và hiển thị màn đăng nhập.
- **FR-003**: Khi trạng thái là *đang kiểm tra*, hệ thống MUST hiển thị màn hình khởi động và MUST NOT hiển thị bất kỳ màn hình nào khác, đặc biệt là màn đăng nhập. Màn hình khởi động **luôn** hiện ở mọi lần **khởi động ứng dụng** — không có trường hợp bỏ qua. Màn hình khởi động MUST **không** hiện khi người dùng đăng xuất hoặc chuyển tài khoản **trong lúc ứng dụng đang chạy** — hai hành động này phải chuyển thẳng sang màn đăng nhập.
- **FR-004**: Việc định tuyến MUST NOT chuyển hướng người dùng tới màn đăng nhập khi trạng thái là *đang kiểm tra*.
- **FR-005**: Màn hình khởi động MUST tự ẩn sau **tối đa 1 giây** kể từ lúc xuất hiện. Nếu việc kiểm tra phiên hoàn tất sớm hơn, màn hình ẩn sớm hơn — nhưng vẫn phải **đã hiện ra**. Ứng dụng MUST NOT thêm độ trễ cố ý sau khi việc kiểm tra phiên đã xong.
- **FR-006**: Màn hình khởi động MUST dùng bộ nhận diện và bảng màu hiện hành của sản phẩm, không dùng màu mặc định của hệ điều hành.

**Nhóm B — Phủ màn hình khi lấy phiên đăng nhập**

- **FR-007**: Khi ứng dụng đang lấy phiên đăng nhập sau thao tác đăng nhập, toàn bộ màn đăng nhập MUST bị phủ bằng một lớp chặn tương tác.
- **FR-008**: Trong khi bị phủ, mọi thao tác chạm/nhấn lên màn đăng nhập MUST bị bỏ qua, kể cả nhấn lại nút đăng nhập.
- **FR-009**: Lớp phủ MUST có thông báo trạng thái đang xử lý và MUST có nhãn tiếng Việt.
- **FR-010**: Khi thao tác đăng nhập kết thúc — thành công, thất bại, bị huỷ, hoặc hết thời gian chờ — lớp phủ MUST được gỡ, kể cả khi người dùng huỷ giữa chừng.
- **FR-011**: Trạng thái đang lấy phiên MUST áp dụng cho cả đăng nhập bằng mật khẩu và đăng nhập bằng Google.

**Nhóm C — Màn Up bài**

- **FR-012**: Dải "HÌNH ẢNH & VIDEO (n/10)" cùng các nút thêm tệp MUST hiển thị đầy đủ ở mọi bề rộng cửa sổ, không có nội dung nào tràn ra ngoài khung.
- **FR-013**: Khi bề rộng không đủ cho tiêu đề và hai nút trên cùng một dòng, các nút MUST tự xuống dòng thay vì tràn ngang.
- **FR-014**: Khi bề rộng đủ, bố cục phải giống hệt hiện tại.
- **FR-015**: Mọi cải tiến bố cục MUST giữ nguyên hành vi hiện có: chặn chọn thêm khi đã đủ 10 tệp, và bộ đếm hiển thị đúng số tệp.

**Nhóm D — Gợi ý phối đồ của stylist**

- **FR-016**: Ứng dụng MUST đọc cấu trúc gợi ý theo đúng hợp đồng dữ liệu mà máy chủ trả về, theo đó món đồ được chia theo **vai trò** (áo, quần, giày, phụ kiện…), mỗi vai trò có một món chính và danh sách món thay thế.
- **FR-017**: Mỗi món được hiển thị MUST lấy được định danh, tên và địa chỉ ảnh từ máy chủ; ứng dụng MUST NOT hiển thị một thẻ gợi ý nào mà không có ít nhất định danh và tên.
- **FR-018**: Địa chỉ ảnh phải được lấy từ cả hai nguồn món: món trong tủ đồ và món của thương hiệu.
- **FR-019**: Khi một món không có địa chỉ ảnh, ứng dụng MUST hiển thị nhãn vai trò thay cho hình ảnh, MUST NOT hiển thị biểu tượng lỗi hoặc khung trống.
- **FR-020**: Ứng dụng MUST hiển thị vai trò của mỗi món gợi ý bằng nhãn tiếng Việt.
- **FR-031**: Nhãn vai trò tiếng Việt MUST lấy từ một bảng ánh xạ **đóng** nằm trong ứng dụng, không phụ thuộc vào việc máy chủ có cung cấp trường nhãn riêng.
- **FR-032**: Khi vai trò không có trong bảng ánh xạ, ứng dụng MUST hiển thị nguyên chuỗi vai trò do máy chủ trả về, và MUST NOT ẩn nhãn.
- **FR-033**: Ứng dụng MUST mang được từ phản hồi máy chủ tới tận nơi hiển thị ba giá trị: **vai trò** của từng món, **cờ gợi ý dự phòng**, và **số hạn mức còn lại**. Việc chỉ nhận một trong ba giá trị này ở tầng hiển thị coi là chưa đạt FR-020, FR-029 và FR-030.
- **FR-034**: Ứng dụng MUST dùng **một** mô hình dữ liệu duy nhất để truyền tải kết quả gợi ý tới màn trò chuyện. Cấm tồn tại hai bộ mô hình song song mô tả cùng một kết quả.
- **FR-021**: Phần gợi ý món đồ chỉ được thêm vào câu trả lời khi câu hỏi thực sự liên quan tới cách phối đồ hoặc tới một bộ đồ cụ thể; các câu hỏi về thời tiết, màu sắc hoặc địa điểm riêng lẻ MUST NOT tự động kèm gợi ý món đồ.
- **FR-022**: Khi yêu cầu gợi ý món đồ thất bại, ứng dụng MUST giữ nguyên phần trả lời văn bản đã nhận được và MUST hiển thị thông báo rằng phần gợi ý món đồ tạm thời không có.
- **FR-023**: Khi yêu cầu gợi ý món đồ thất bại, ứng dụng MUST NOT hiển thị bất kỳ danh sách món nào không do máy chủ trả về. Ràng buộc này chỉ áp dụng cho danh sách do **ứng dụng** tự chế ra.
- **FR-029**: Khi máy chủ trả về **gợi ý dự phòng của máy chủ** (khác với danh sách tự chế của ứng dụng), ứng dụng MUST hiển thị kèm nhãn tiếng Việt nói rõ đây là gợi ý dự phòng, và MUST NOT trình bày nó như gợi ý chuẩn của stylist.
- **FR-030**: Khi hạn mức gợi ý đã cạn, ứng dụng MUST hiển thị số hạn mức còn lại kèm hướng dẫn chung rằng gợi ý tự làm mới vào ngày mới. Ứng dụng MUST NOT hiển thị ngày giờ cụ thể cho thời điểm làm mới, vì máy chủ không cung cấp thông tin này.
- **FR-024**: Khi tải lại lịch sử trò chuyện, ứng dụng MUST hiển thị đúng nội dung mà máy chủ trả về và MUST NOT phụ thuộc vào trường dữ liệu mà máy chủ không cung cấp. Thẻ gợi ý **không** được kỳ vọng quay lại sau khi tải lại: máy chủ không lưu kết quả gợi ý theo từng tin nhắn và ứng dụng không cache cục bộ — xem *Edge Cases* và `quickstart.md` §K11 (giới hạn đã biết, T055).
- **FR-025**: Mọi lỗi khi lấy gợi ý món đồ MUST được ghi nhận để chẩn đoán được, thay vì bị bỏ qua im lặng.

### Key Entities

- **Phiên đăng nhập**: trạng thái của người dùng gồm *đang kiểm tra* / *đã đăng nhập* / *chưa đăng nhập*, đi kèm hồ sơ người dùng và thông báo lỗi/thành công. Mở rộng từ trạng thái xác thực hiện có.
- **Món đồ gợi ý**: một món trong kết quả gợi ý, gồm vai trò, định danh, tên, thương hiệu, màu sắc, địa chỉ ảnh, và nguồn gốc (tủ đồ của người dùng hay của thương hiệu).
- **Nhóm vai trò**: một vai trò trong bộ gợi ý (áo, quần, giày, phụ kiện…), gồm một món chính và danh sách món thay thế.
- **Bộ gợi ý**: kết quả gợi ý hoàn chỉnh gồm tiêu đề, phần giải thích, danh sách nhóm vai trò, **cờ cho biết đây có phải gợi ý dự phòng của máy chủ hay không**, và **số hạn mức còn lại**. Hai giá trị cuối là thuộc tính bắt buộc vì nhãn dự phòng (FR-029) và thông báo hạn mức (FR-030) phải đọc được từ chính bộ gợi ý này.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% lần mở app khi đã đăng nhập không hiển thị màn đăng nhập.
- **SC-002**: Màn hình khởi động xuất hiện trong 100% các lần khởi động app và biến mất trong 1 giây khi việc kiểm tra phiên **hoàn tất thành công**. Nếu việc kiểm tra trễ hoặc lỗi tạm thời, màn hình khởi động ở lại kèm thông báo và nút "Thử lại" thay vì biến mất theo ngưỡng 1 giây.
- **SC-003**: Mỗi lần bấm Đăng nhập tạo ra đúng một yêu cầu, kể cả khi người dùng bấm nhiều lần liên tiếp trong lúc đang xử lý.
- **SC-004**: Màn Up bài không còn hiển thị dải cảnh báo tràn viền ở mọi bề rộng cửa sổ từ 300px trở lên; mọi nút thêm tệp luôn bấm được.
- **SC-005**: Khi stylist gợi ý cách phối đồ, 100% thẻ gợi ý có tên món hiển thị và 100% thẻ có địa chỉ ảnh thì tải được.
- **SC-006**: Không còn trường hợp phần gợi ý món đồ hiển thị danh sách món không liên quan tới câu hỏi do lỗi hệ thống.
- **SC-007**: Người dùng luôn nhận được một thông báo rõ ràng khi phần gợi ý món đồ không tải được, thay vì thấy nội dung sai lệch hoặc im lặng.
- **SC-008**: Tải lại lịch sử trò chuyện không còn làm mất nội dung hoặc báo lỗi.
- **SC-009**: Người dùng có phiên hợp lệ không bị đưa ra màn đăng nhập khi khởi động app gặp lỗi mạng hoặc máy chủ lỗi tạm thời; phiên được giữ nguyên và sau khi kết nối lại người dùng vào thẳng app mà không phải đăng nhập lại.
- **SC-010**: Mọi bộ gợi ý dự phòng của máy chủ đều có nhãn nhận dạng; người dùng không thể nhầm nó với gợi ý chuẩn của stylist.
- **SC-011**: Đăng xuất hoặc chuyển tài khoản giữa lúc ứng dụng đang chạy thì **không** màn hình khởi động nào xuất hiện; người dùng thấy thẳng màn đăng nhập.

## Assumptions

### Thuật ngữ chuẩn

Hai khái niệm sau là **khác nhau** và không được dùng lẫn tên trong mã, tài liệu hay thông báo:

- **Gợi ý dự phòng của máy chủ** — danh sách món do máy chủ tự sinh khi không đủ điều kiện gợi ý thật (thường khi hết hạn mức). Là dữ liệu thật của máy chủ, phải hiển thị kèm nhãn dự phòng.
- **Danh sách tự chế của ứng dụng** — danh sách món từ trước đây ứng dụng tự nhúng sẵn. Nằm ngoài phạm vi sửa: phải **gỡ khỏi luồng trò chuyện**.

### Giả định

- Phạm vi sửa **chỉ trong ứng dụng**. Máy chủ giữ nguyên hợp đồng dữ liệu hiện tại; ứng dụng chịu trách nhiệm đọc đúng cấu trúc đó.
- Cấu trúc gợi ý theo vai trò đã là hợp đồng chính thức của máy chủ và đã được dùng ở màn gợi ý phối đồ trong Studio — chỉ có màn trò chuyện stylist là chưa dùng.
- Màn hình khởi động là màn hình toàn màn hình, không thao tác được, hiển thị trong suốt quá trình kiểm tra phiên.
- Ngưỡng chống nháy ở FR-005 không được làm người dùng chờ quá lâu trong trường hợp bình thường. Con số đã chốt là 1 giây; cần đo lại trên máy thật và mở rộng nếu thiết bị chậm vẫn bị nháy.
- Việc sửa tràn viền giới hạn ở dải "HÌNH ẢNH & VIDEO" của màn Up bài. Các trường hợp tràn viền khác ghi nhận trong nhật ký khi chạy thử sẽ ghi thành nợ kỹ thuật riêng, không thuộc đợt này.
- Bộ gợi ý dự phòng hiện có trong mã nguồn sẽ bị gỡ khỏi luồng trò chuyện. Máy chủ vẫn có thể tự trả về kết quả dự phòng của riêng nó — xem mục *Thuật ngữ chuẩn*.
- Ứng dụng web và ứng dụng Android dùng chung mã nguồn nên một sửa đổi áp dụng cho cả hai.

## Out of Scope

- Thay đổi hợp đồng dữ liệu hoặc hành vi của máy chủ.
- Sửa các lỗi tràn viền ngoài màn Up bài.
- Cải thiện độ chính xác của mô hình ngôn ngữ đằng sau stylist — phạm vi này chỉ sửa cách ứng dụng đọc và hiển thị kết quả.
- Thay đổi thuật toán gợi ý phối đồ.

## Dependencies

- Máy chủ phải tiếp tục cung cấp gợi ý theo cấu trúc chia vai trò hiện tại.
- Không cần thay đổi cấu hình định tuyến hay tài khoản nào.

## Risks

- Thêm màn hình khởi động làm thay đổi cảm nhận về tốc độ khởi động của ứng dụng — cần kiểm chứng bằng máy thật.
- Gỡ việc bỏ qua lỗi sẽ làm lộ ra các trường hợp lỗi trước đây bị che giấu, khiến người dùng thấy thông báo lỗi ở những tình huống trước đây tưởng như bình thường. Đây là hành vi đúng nhưng khác trước, cần nêu rõ khi bàn giao.