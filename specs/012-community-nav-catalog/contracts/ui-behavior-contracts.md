# Contract: Hành vi UI/Mobile — 012

**Feature**: `012-community-nav-catalog` | **Date**: 2026-09-27

Hợp đồng hành vi (không phải HTTP). Tham chiếu `data-model.md`.

## C1 — Thanh điều hướng

- 5 tab, thứ tự: **[Tủ đồ, Cộng đồng, Phối đồ AI, Stylist AI, Hồ sơ]**; **không** có Home.
- Tab Community dùng icon `Icons.public`/`public_outlined`; nhãn "Cộng đồng".
- Bấm tab → mở đúng màn; tab đang chọn có chỉ báo như các tab khác (đồng nhất size/màu).
- Sau đăng nhập → vào `/community`.
- Deep-link `/home` → chuyển hướng `/community` (không lỗi, không màn trắng).

## C2 — Nạp nhiều ảnh vào tủ đồ

- Nút "Thêm đồ" cho chọn **nhiều ảnh** (`pickMultiImage`) ngoài camera/thư viện 1 ảnh.
- Với mỗi ảnh: signature → Cloudinary → batch-upload; UI hiển thị **tiến trình `đã xong/tổng`**.
- 1 ảnh lỗi → không chặn ảnh khác; giữ `failedFiles` + nút **Thử lại** phần lỗi.
- Tôn trọng hạn mức gói: chặn/nhận tối đa phần còn lại; thông báo rõ phần vượt.
- Trong lúc tải: khoá bấm lặp; sau xong: món mới (optimistic) hiển thị + cập nhật qua SSE/polling như cũ.

## C3 — Tủ đồ hệ thống (món thiếu ảnh)

- Món hệ thống có **ảnh rỗng** → **không hiển thị** trong grid và **không cho chọn/thêm**.
- Chỉ món có ảnh hợp lệ mới `isSelectable`.
- Nếu sau lọc danh sách trống → hiển thị **empty state tiếng Việt** (không hiện món trắng).
- (BE) bổ sung ảnh cho món mẫu để chúng xuất hiện lại.

## C4 — Đăng nhập Google theo tài khoản

- Mỗi lần bấm đăng nhập: **clear phiên cục bộ** + **signOut Google** trước → hiện account chooser.
- Đăng nhập Google B sau khi đã A → hồ sơ/tủ đồ là **của B**; không tái dùng phiên A.
- Nếu đổi tài khoản/đăng xuất: `sessionProvider` bump → state tài khoản cũ bị dispose.
- Lỗi/ huỷ → không để lại phiên dở dang của tài khoản trước.

## C5 — Ngôn ngữ (Việt hoá)

- Mọi chuỗi hiển thị trong luồng chính: **tiếng Việt**.
- Giữ nguyên: tên thương hiệu/model, URL, route name, biến/key code.
- Thông báo lỗi/rỗng/đang tải đều tiếng Việt (dùng `SnackBar`/widget chữ VI).

## C6 — Không hồi quy

- Deep-link thanh toán (`/profile/payment/result`, `/profile/subscription...`) và guard auth giữ nguyên hành vi.
- Các route/paywall/privacy không đổi cờ.
- `flutter analyze` 0 issues; test cũ liên quan vẫn pass.
