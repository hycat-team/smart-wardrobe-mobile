# Specification Quality Checklist: Sửa nháy màn login, tràn viền Up bài, gợi ý AI sai

**Purpose**: Kiểm tra tính đầy đủ và chất lượng đặc tả trước khi chuyển sang lập kế hoạch
**Created**: 2026-10-02
**Feature**: [spec.md](../spec.md)

## Content Quality

- [x] CHK001 Không lộ chi tiết cài đặt (ngôn ngữ, framework, thư viện, tên file, tên hàm)
- [x] CHK002 Tập trung vào giá trị và nhu cầu người dùng
- [x] CHK003 Viết cho người đọc không kỹ thuật
- [x] CHK004 Tất cả phần bắt buộc đã điền (User Scenarios, Requirements, Success Criteria)

**Ghi chú CHK001**: Khối "Dependencies"/"Risks" chỉ mô tả hợp đồng dữ liệu ở mức khái niệm ("chia theo vai trò: áo, quần, giày, phụ kiện"), không nêu tên endpoint, tên trường JSON hay đường dẫn file. Việc truy ra file cụ thể đã bị loại bỏ khỏi User Scenarios và Edge Cases.

## Requirement Completeness

- [x] CHK005 Không còn marker [NEEDS CLARIFICATION]
- [x] CHK006 Yêu cầu chức năng có thể kiểm thử và không mơ hồ
- [x] CHK007 Tiêu chí thành công đo lường được
- [x] CHK008 Tiêu chí thành công không phụ thuộc công nghệ
- [x] CHK009 Tất cả kịch bản chấp nhận đã được định nghĩa
- [x] CHK010 Các trường hợp biên đã xác định
- [x] CHK011 Phạm vi được xác định rõ (có mục Out of Scope riêng)
- [x] CHK012 Phụ thuộc và giả định đã xác định

## Feature Readiness

- [x] CHK013 Mọi yêu cầu chức năng có tiêu chí chấp nhận rõ ràng
- [x] CHK014 Kịch bản người dùng phủ các luồng chính
- [x] CHK015 Tính năng đáp ứng các kết quả đo lường ở Success Criteria
- [x] CHK016 Không lọt chi tiết cài đặt vào đặc tả

## Ghi chú validation

### Đã sửa sau vòng kiểm tra đầu

- **Vòng 1 — CHK001 (lộ chi tiết cài đặt)**: bản nháp đầu tiên trong mục "Dependencies" có nêu tên hai nhóm dữ liệu cụ thể của ứng dụng và nội dung một trường JSON. Đã viết lại thành khái niệm trung tính. Đạt.
- **Vòng 1 — CHK006 (yêu cầu mơ hồ)**: FR-016 ban đầu viết "MUST đọc đúng cấu trúc của máy chủ" chung chung, không kiểm thử được. Đã tách thành FR-016 (chia vai trò), FR-017 (bắt buộc có định danh + tên), FR-018 (lấy ảnh từ cả hai nguồn) — mỗi câu kiểm thử được bằng dữ liệu vào/ra. Đạt.
- **Vòng 1 — CHK007/SC có tính đo lường**: SC ban đầu có "cảm nhận tốt hơn". Đã thay toàn bộ bằng tỷ lệ và ngưỡng đo được. Đạt.
- **Vòng 1 — CHK011 (phạm vi)**: bản nháp chưa nói rõ các lỗi tràn viền khác và độ chính xác mô hình ngôn ngữ có thuộc phạm vi không. Đã thêm mục Out of Scope. Đạt.
- **Vòng 2**: rà lại toàn bộ — không còn vấn đề nào mở. Đạt.

### Ghi chú còn lại

- Cả ba nhóm yêu cầu độc lập nhau về mặt kỹ thuật. Có thể lập kế hoạch rồi triển khai theo thứ tự Nhóm A+B → C → D, mỗi nhóm tự kiểm thử độc lập.
- Nhóm D phụ thuộc vào hợp đồng dữ liệu của máy chủ ổn định. Nếu máy chủ đổi cấu trúc gợi ý sau này, cần một đặc tả riêng.
- FR-005 (ngưỡng chống nháy) là một con số đề xuất, cần kiểm chứng trên máy thật ở giai đoạn kế hoạch. Nếu máy chủ dev chậm, ngưỡng có thể cần nới.

## Ghi chú

- Đánh dấu mục đã hoàn thành bằng `[x]`.
- Bổ sung nhận xét hoặc phát hiện trực tiếp trong file.
- Liên kết tới tài liệu tham chiếu: constitution, các đặc tả `specs/` liên quan, và hồ sơ ngày làm việc.