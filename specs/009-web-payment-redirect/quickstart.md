# Quickstart: Web Payment Redirect (Phase 1)

**Feature**: `009-web-payment-redirect` | **Date**: 2026-09-24

Hướng dẫn kiểm chứng thủ công end-to-end sau khi implement. Mỗi kịch bản ánh xạ tới tiêu chí trong `spec.md` và contract trong `contracts/web-handoff-contract.md`. Không chứa code implement.

## Prerequisites

- Tài khoản test gói Free + tài khoản test đã có giao dịch web thành công (để đối chiếu).
- Biết địa chỉ website thanh toán (dạng văn bản, tự mở trình duyệt ngoài app).
- App bản mới đã gỡ mọi nút/form thanh toán; thiết bị có mạng.

## QS-1 — Không còn checkout trong app (SC-001)

1. Mở mọi điểm vào: màn hình gói/nâng cấp, thẻ ví (`closy_wallet_card`), màn hình ví chi tiết, màn hình gói hiện tại.
2. Xác minh: thấy tên + giá VNĐ + thời hạn + quyền lợi (gói), số dư + lịch sử (ví); không có nút quét QR/thanh toán, form nhập tiền, nút nạp/mua bằng ví.
3. Tìm toàn app cụm `launchUrl`, WebView thanh toán, điều hướng tới waiting/result — kỳ vọng: không còn đường nào tới checkout.
- **Pass khi**: 100% điểm vào không tạo/mở trang hay mã thanh toán.

## QS-2 — Hướng dẫn web thuần văn bản (SC-002, FR-002/005/006)

1. Chọn một gói trả phí → xác minh hiện `WebGuidanceCard` với địa chỉ website dạng văn bản + 3 bước + ghi chú cùng tài khoản; không có nút/link.
2. Ở màn hình ví, tìm nhu cầu nạp → xác minh cùng nội dung hướng dẫn, không còn `TopUpBottomSheet`.
3. Hỏi 5 người dùng lần đầu: "bước tiếp theo để trả tiền là gì?" — kỳ vọng ≥ 90% trả lời "tự mở trình duyệt, đăng nhập cùng tài khoản, trả trên web".
- **Pass khi**: nội dung đúng contract mục 3, không nút/link, user hiểu bước tiếp theo.

## QS-3 — Đồng bộ sau thanh toán web (SC-003)

1. Mở app ở màn hình gói/ví (ghi nhớ trạng thái cũ).
2. Trên trình duyệt ngoài app: đăng nhập website CÙNG tài khoản, mua gói / nạp ví thành công.
3. Quay lại app (từ nền) / mở lại màn hình → xác minh gói mới + hạn mức / số dư + lịch sử mới trong vòng 2 phút, không cần đăng xuất/cài lại/bấm làm mới thủ công.
4. Lặp lại khi giao dịch web chưa xong → xác minh app giữ trạng thái cũ + gợi ý kiểm tra lại sau.
- **Pass khi**: 95% lượt thử đạt; không báo thành công giả.

## QS-4 — Lỗi và link cũ (FR-009/010)

1. Tắt mạng, mở màn hình gói/ví → xác minh thông báo tiếng Việt + nút thử lại, không kẹt ở hướng dẫn.
2. Cố truy cập đường màn hình chờ/kết quả cũ (nếu còn route) → xác minh thông báo hết hiệu lực + hướng dẫn lên website, không mở checkout.
- **Pass khi**: lỗi thân thiện, link cũ không mở được.

## QS-5 — Hồi quy đọc (FR-008)

1. Mở lịch sử ví, thông tin gói hiện tại, quota → xác minh vẫn xem được bình thường sau khi gỡ luồng thanh toán.
- **Pass khi**: đọc đầy đủ, không crash, không còn gọi API tạo link/mua.
