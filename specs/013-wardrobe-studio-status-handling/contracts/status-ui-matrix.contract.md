# Contract: status → UI matrix (wardrobe)

| `data.status` | Nhãn badge | Card tủ đồ | Chi tiết món | Ngăn Studio |
|---|---|---|---|---|
| `inWardrobe` (0) | (không) | Dùng phối đồ | Đầy đủ thuộc tính | Cho chọn |
| `processing` (3) | "Đang phân tích" | Khóa phối đồ, ẩn retry | Khóa phối đồ, ẩn retry | Mờ + huy hiệu, không cho chọn |
| `needsReview` (5) + `uncertain_category` | "Cần chọn danh mục" | Mở chi tiết | Danh sách category + "Gửi phân tích lại" (bắt buộc chọn) | Ẩn (chưa dùng được) |
| `failed` (4) + `multiple_items_detected` | "Ảnh có nhiều món" | Gợi ý ảnh khác + nút xóa | Gợi ý "chụp cận cảnh một món", **ẩn retry** | Ẩn |
| `failed` (4) + `full_body_outfit_detected` | "Ảnh toàn thân" | Gợi ý ảnh khác + nút xóa | Gợi ý "chụp cận cảnh một món", **ẩn retry** | Ẩn |
| `failed` (4) + `analysis_temporary_error` / `auto_retry_exceeded` | "Lỗi tạm thời" | Nút "Thử lại" (khóa khi đang gửi) | Nút "Thử lại" (khóa khi đang gửi) | Ẩn |
| failed + mã lạ | "Không thể phân tích…" | Nút xóa/thử lại theo message | Message mặc định | Ẩn |

Tất cả chuỗi tiếng Việt; giữ tên mã kỹ thuật trong log/debug.
