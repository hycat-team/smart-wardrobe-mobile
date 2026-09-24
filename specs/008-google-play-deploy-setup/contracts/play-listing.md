# Contract: Google Play Listing & Compliance

**Feature**: specs/008-google-play-deploy-setup
**Date**: 2026-09-19
**Type**: Submission contract (Google Play Console)
**Consumers**: người chịu trách nhiệm release, reviewer nội bộ

Play Console chỉ cho publish khi các mục dưới đây đầy đủ và nhất quán với hành vi thật của app.

## P1 — App identity

| Mục | Giá trị / ràng buộc |
|---|---|
| App name | `Smart Wardrobe` |
| Package name | `com.smartwardrobe.smart_wardrobe` (khớp AAB) |
| Default language | Vietnamese |
| Type | App |
| Pricing | Free |

## P2 — Store listing (bắt buộc)

- Title ≤ 30 ký tự.
- Short description ≤ 80 ký tự.
- Full description mô tả đúng chức năng (wardrobe, AI stylist, outfit) — không hứa tính năng trả phí đã ẩn.
- App icon 512×512; feature graphic 1024×500.
- ≥ 2 ảnh chụp điện thoại (khuyến nghị 4–8), không chứa nội dung gây hiểu nhầm.
- Liên kết Privacy Policy công khai, truy cập được.

## P3 — Data Safety (khớp hành vi thật)

- Thu thập: email, tên, thông tin hồ sơ, ảnh (ảnh trang phục), nội dung người dùng.
- Chia sẻ với bên thứ ba: hạ tầng lưu ảnh (Cloudinary), backend của đội.
- Mã hóa khi truyền: **Có** (điều kiện: C3/C4 của `release-config.md`).
- Không khai location (manifest không có quyền vị trí).
- Không khai analytics/crash của bên thứ ba (`pubspec.yaml` không có SDK tương ứng).
- Người dùng có thể yêu cầu xóa dữ liệu (theo chính sách/backend).
- Không được khai "không thu thập dữ liệu".

## P4 — Các khai báo khác

| Mục | Ràng buộc |
|---|---|
| Content rating | Hoàn tất bảng câu hỏi, kết quả khớp nội dung app |
| Target audience | Chọn nhóm tuổi đúng (người lớn/thanh thiếu niên theo thực tế) |
| Ads | Khai `No ads` nếu thực tế không có quảng cáo |
| App access | `Login required` + tài khoản test (email/mật khẩu) + hướng dẫn đường vào chức năng |
| Government apps / financial | Khai trung thực; không có tính năng tài chính bên ngoài ở bản đầu (đã ẩn) |

## P5 — Track progression

```text
Internal Testing  →  Closed Testing (≥12 tester opt-in, ≥14 ngày liên tục)  →  Production access  →  Production release
```

- Mỗi lần upload phải có `versionCode` mới.
- Closed Testing: duy trì danh sách 15–20 tester; theo dõi opt-in; rớt opt-in có thể reset điều kiện.
- Production access: trả lời đúng quá trình testing thật; không khai khống.

## P6 — Definition of Done (publish)

- AAB ký upload key đã lên track tương ứng.
- 100% mục bắt buộc của P2–P4 hoàn tất.
- Điều kiện P5 thỏa (nếu áp dụng).
- Bản release đã smoke test trên máy thật với API HTTPS, không còn điểm vào trả phí kỹ thuật số.
