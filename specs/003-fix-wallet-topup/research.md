# Research: Fix Wallet Top-Up Flow

**Feature**: `003-fix-wallet-topup` | **Date**: 2026-09-11

All NEEDS CLARIFICATION markers from the spec (FR-011, FR-012, FR-013 — user did not answer, defaults applied) plus technical unknowns are resolved below.

## R1. QR hiển thị trong app bằng cách nào?

- **Decision**: Màn hình QR nạp ví mới render mã QR ngay trong app từ `paymentUrl` của lệnh nạp (chuỗi URL checkout PayOS), dùng package `qr_flutter`; kèm nút dự phòng "Mở trang thanh toán" (giữ `url_launcher`) và nút sao chép liên kết.
- **Rationale**: Đúng kỳ vọng của user ("trang hiển thị mã qr để chuyển tiền"); PayOS checkout URL mở trên mobile browser vẫn hiển thị QR, nhưng render QR trong app giữ người dùng ở lại app, không phụ thuộc browser ngoài/emulator chặn popup — chính là nguyên nhân lỗi (a). Nút mở trình duyệt giữ lại làm đường dự phòng.
- **Alternatives considered**:
  - Chỉ mở browser ngoài (hiện trạng) — loại bỏ vì đó chính là bug.
  - Package `pretty_qr_code` — đẹp hơn nhưng `qr_flutter` là chuẩn phổ biến, nhẹ, đủ dùng; chốt `qr_flutter` (bản mới nhất tương thích Dart 3 / Flutter 3.47, verify lúc implement).

## R2. Xác nhận nạp thành công khi backend chưa có API tra cứu trạng thái lệnh?

- **Decision**: Không thêm API backend. Mobile tự xác nhận bằng **chênh lệch số dư ví + đối chiếu lịch sử giao dịch**:
  1. Lúc tạo lệnh: chụp `balanceBefore` từ `GET /subscriptions/me/wallet`.
  2. Poll mỗi 3s: `GET /subscriptions/me/wallet`; thành công khi `balanceNow - balanceBefore >= expectedAmount - epsilon`.
  3. Đối chiếu chéo: `GET /subscriptions/me/wallet/statements` (page 1) có entry nạp tiền mới với amount khớp và `createdAt` sau thời điểm tạo lệnh → xác nhận chắc chắn.
  4. Timeout 15 phút (khớp hạn QR PayOS) → hiển thị hết hạn + nút tạo lệnh mới.
- **Rationale**: Mọi endpoint cần thiết đã tồn tại (`profile_repository.dart`: `getWallet`, `getWalletStatements`); không phụ thuộc backend team, không migration. Tránh hoàn toàn false-positive kiểu "thấy Premium là báo thành công".
- **Alternatives considered**:
  - Thêm endpoint backend `GET /wallet/topup/:orderCode/status` — chính xác nhất nhưng ngoài phạm vi repo mobile, cần phối hợp BE; ghi nhận làm cải tiến tương lai.
  - Chỉ so số dư — đủ cho đa số case nhưng dễ sai khi có biến động song song (ví dụ hoàn tiền cùng lúc); nên cộng thêm đối chiếu statements.

## R3. Đường quay về app sau khi trả tiền ngoài trình duyệt?

- **Decision**: Ba lớp, không đụng native trong iteration này:
  1. Nút "Tôi đã chuyển tiền — Kiểm tra kết quả" trên màn hình QR/chờ → gọi kiểm tra ngay.
  2. Auto-poll nền (3s) vẫn chạy khi user ở màn hình chờ.
  3. Kiểm tra lại khi app resume (`AppLifecycleState.resumed`) — bao phủ case user tự quay về.
  4. Deep-link `smartwardrobe://` + intent-filter Android dời sang giai đoạn sau (cần sửa `AndroidManifest.xml`, thêm handler) — ghi vào plan tương lai, không chặn fix này.
- **Rationale**: Fix được lỗi với thay đổi thuần Dart, rủi ro thấp nhất, test được ngay trên emulator.

## R4. Tách luồng nạp ví khỏi màn hình chờ mua Premium ra sao?

- **Decision**: Thêm phân loại mục đích thanh toán (`PaymentPurpose.topup` vs `.subscription`) truyền qua route `extra`:
  - Luồng mua Premium giữ nguyên route `/profile/subscription/waiting` + `PaymentWaitingScreen` (hồi quy an toàn), chỉ sửa dòng cứng `'249.000 đ'` → dùng `paymentLink.formattedAmount` (đúng cho cả 2 luồng).
  - Luồng nạp ví đi route mới `/profile/wallet/topup-qr` → màn hình QR + chờ xác nhận theo R2, thành công → về `/profile/wallet` (có reload số dư).
- **Rationale**: Không phá luồng đang chạy đúng (mua Premium), khoanh vùng bug vào luồng nạp ví; route riêng giúp deep-link tương lai (`/profile/wallet/...`) sạch.

## R5. Chuẩn state management / routing / UI của repo (từ skill closy-mobile-flutter)

- **Decision**: Giữ nguyên stack repo — `StateNotifierProvider` (`WalletNotifier` mở rộng thêm trạng thái poll), `GoRouter` (thêm 1 `GoRoute`), Dio hiện có (giữ header `Accept-Encoding: identity`), tokens Quiet Luxury (`AppColors`, Playfair Display tiêu đề), BottomSheet bọc `SingleChildScrollView`.
- **Rationale**: Tuân thủ conventions dự án, không thêm kiến trúc mới cho một bugfix.

## R6. Parse số tiền nhập "100.000" bị lệch highlight preset

- **Decision**: Dùng chung một hàm chuẩn hóa (strip `.` `,` + trim) cho cả `onChanged` lẫn submit; preset highlight so sánh trên giá trị đã chuẩn hóa.
- **Rationale**: Bug nhỏ nhưng gây nhầm lẫn đúng tại màn hình nạp tiền — sửa luôn trong cùng luồng (1 hàm dùng chung, ~5 dòng).
