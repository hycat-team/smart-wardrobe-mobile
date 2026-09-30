# Store Listing — Closy

Nội dung dán sẵn cho Play Console (2026-09-30). Giới hạn ký tự của Google
đã được kiểm tra.

---

## 1. App Details

| Trường | Giá trị |
|---|---|
| **App name** (≤30) | `Closy: AI Stylist & Tủ đồ số` |
| **Default language** | Vietnamese |
| **App or game** | App |
| **Free or paid** | Free |
| **Category** | Lifestyle |
| **Contact email** | `hycat.support@gmail.com` |
| **Privacy policy URL** | `https://closy.hycat.online/privacy` |

Tên gói bắt buộc (không sửa sau khi tạo app): `online.hycat.closy`

> **Tên hiển thị đã đổi thành "Closy"** (30/09). Đổi `android:label` trong
> `android/app/src/main/AndroidManifest.xml` → tên icon trên máy là Closy.
> Tên gói `online.hycat.closy` **giữ nguyên** vì Play khóa
> vĩnh viễn sau lần publish đầu.

---

## 1b. Graphics (đã tạo, dùng luôn)

| Tài nguyên | File | Kích thước | Dung lượng |
|---|---|---|---|
| App icon | `store-assets/play-icon-512.png` | 512×512, PNG 32-bit có alpha | 74 KB |
| Feature graphic | `store-assets/play-feature-graphic-1024x500.png` | 1024×500 | 61 KB |
| Phone screenshots | `store-assets/phone-screenshots/closy-screenshot-1..8.jpg` | 1145×2290 (2:1) | ~1 MB tổng |

Sinh bằng `tool/prep_store_graphics.ps1` và `tool/prep_store_screenshots.ps1`.

**Quy tắc Play đã kiểm tra:** cạnh dài không được vượt **2 lần** cạnh ngắn.
Ảnh gốc 1080×2400 có tỉ lệ 2,22 → **sẽ bị từ chối**. Đã cắt 110px status bar
(bỏ thông báo Zalo — Play khuyến nghị không hiện thông báo của nhà cung cấp khác)
rồi nới 2 bên để đạt đúng 2:1, giữ nguyên nội dung app.

---

## 2. Short description (≤80 ký tự)

```
Tủ đồ số thông minh cùng AI Stylist. Gợi ý phối đồ và cộng đồng phong cách.
```
*(77/80 ký tự)*

---

## 3. Full description

```
Closy đưa tủ quần áo của bạn vào thế giới số, nơi trí tuệ nhân tạng
giúp bạn phối đồ nhanh hơn và tận dụng tốt hơn những gì đã sở hữu.

TỦ ĐỒ THÔNG MINH
• Chụp ảnh món đồ, hệ thống tự tách nền và nhận diện danh mục
• Quản lý theo mùa, dịp, màu sắc và chất liệu
• Thống kê giá trị tủ đồ, tỷ lệ sử dụng và những món ít mặc

GỢI Ý PHỐI ĐỒ AI
• Nhận gợi ý bộ đồ theo dịp, mùa, thời tiết và phong cách cá nhân
• Trợ lý Stylist AI tư vấn 24 giờ về cách phối đồ

OUTFIT STUDIO THỦ CÔNG
• Kéo thả món đồ lên canvas, tự điều chỉnh bố cục theo vai trò
• Lưu và quản lý các bộ phối đã hoàn thiện

CỘNG ĐỒNG PHONG CÁCH
• Xem các bộ đồ phối từ thành viên khác
• Chia sẻ phong cách của chính bạn

BẢO MẬT
• Mọi dữ liệu truyền qua mạng đều được mã hóa
• Không thu thập vị trí, không bán dữ liệu
```

---

## 4. Graphic assets — ĐÃ CÓ SẴN, chỉ cần upload

| Tài nguyên | File cần upload | Yêu cầu |
|---|---|---|
| App icon | `store-assets/play-icon-512.png` | 512×512 PNG, có alpha, ≤1 MB |
| Feature graphic | `store-assets/play-feature-graphic-1024x500.png` | 1024×500, ≤1 MB |
| Phone screenshots | `store-assets/phone-screenshots/closy-screenshot-1..8.jpg` | 2–8 ảnh, 1145×2290 (2:1) |

Đây là ảnh chụp từ **app thật** trên máy, đã cắt status bar và đúng tỉ lệ
Play (xem §1b). Không dùng ảnh trong `assets/mockups/` — chúng tiếng Anh, vẽ
trong khung iPhone giả, khác app thật, Play có thể từ chối.

Sinh lại bằng `tool/prep_store_graphics.ps1` + `tool/prep_store_screenshots.ps1`.


---

## 5. Data Safety (bắt buộc trước khi review)

Khai theo hành vi thật của app. Xem `docs/privacy-policy.md` làm nguồn.

### Dữ liệu thu thập

| Loại | Có | Ghi chú |
|---|---|---|
| Email | ✅ | Định danh tài khoản |
| Tên (họ tên) | ✅ | Hồ sơ người dùng |
| Ảnh | ✅ | Ảnh trang phục người dùng tự tải lên |
| Thông tin cá nhân khác | ✅ | Ngày sinh, giới tính, địa chỉ (hồ sơ) |
| Tin nhắn | ❌ | Trừ nội dung bài đăng cộng đồng do user tự soạn |
| Vị trí | ❌ | App không thu thập |
| Lịch sử ứng dụng | ❌ | — |
| Khẩn cấp | ❌ | — |

### Mục đích sử dụng

| Mục đích | Email | Tên | Ảnh | Hồ sơ |
|---|---|---|---|---|
| Quản lý tài khoản | ✅ | ✅ | — | — |
| Tính năng ứng dụng | ✅ | ✅ | ✅ | ✅ |

### Bảo mật

- **Mã hóa khi truyền (Encrypted in transit)**: ✅ tick — tất cả qua HTTPS
- **Có cơ chế xóa dữ liệu**: ✅ — người dùng gửi yêu cầu xóa qua
  `hycat.support@gmail.com`, xóa trong 30 ngày
- **Không chia sẻ với bên thứ ba** trong Data Safety: chỉ máy chủ đội +
  Cloudinary (hạ tầng lưu trữ, không bán dữ liệu)

### Không tick

- ❌ Ads / Analytics SDK bên thứ ba
- ❌ Data sharing
- ❌ Location / Contact list / SMS

---

## 6. App content

| Mục | Trả lời |
|---|---|
| **Ads** | Không có quảng cáo |
| **App access** | `Login required` — tài khoản test `user` / `123456` |
| **Content rating** | Hoàn tất questionnaire (không có nội dung nhạy cảm) |
| **Target audience** | 13+ (không hướng đến trẻ em) |
| **News app** | Không |
| **COVID-19 app** | Không |

---

## 7. Trước khi bấm Review

- [ ] Privacy Policy URL mở được **không cần đăng nhập**
- [ ] Email `hycat.support@gmail.com` khớp cả 3 nơi:
      Play Console, màn `/profile/privacy`, trang web
- [ ] Screenshots chụp từ **bản cài từ Play** (không phải debug build)
- [ ] Screenshot không chứa dữ liệu của người dùng thật
- [ ] `versionCode` lớn hơn bản đã upload
- [ ] Smoke test đăng nhập Google đã chạy (xem `Release_Play_Checklist.md` §4)
