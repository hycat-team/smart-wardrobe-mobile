# Hướng dẫn cài APK release lên máy Android thật

Dùng để test nhanh và chuẩn bị ảnh chụp, không cần chờ upload Google Play.

## File APK

```
D:\_HYCAT\smart-wardrobe-mobile\build\app\outputs\flutter-apk\app-release.apk
```

| Thuộc tính | Giá trị |
|---|---|
| Dung lượng | 63.3 MB |
| Package | `online.hycat.closy` |
| versionCode / versionName | `2` / `1.0.0` |
| API | `https://api.closy.hycat.online/api/v1` (production) |
| Chữ ký | upload keystore (`CN=hycat, OU=closy, O=hycat`) |

⚠ **APK này trỏ production, dữ liệu thật.** Tài khoản `user / 123456` sẽ bị
thay đổi khi bạn xoá món đồ hoặc bộ phối. Nên dùng tài khoản phụ nếu muốn
giữ nguyên dữ liệu mẫu.

---

## Cách 1 — Chép file và cài trực tiếp trên máy (không cần USB)

Đơn giản nhất, không cần cài gì trên PC.

1. Copy `app-release.apk` sang điện thoại (qua USB, Google Drive, Zalo, AirDrop)
2. Mở ứng dụng **Tệp** (Files) trên máy, tìm file `.apk`, bấm vào
3. Android sẽ hỏi *"Cho phép cài ứng dụng từ nguồn này không?"*
4. Bật quyền cho ứng dụng **Tệp** (hoặc **Chrome**) → quay lại → **Cài đặt**
5. Xong. Mở app "Smart Wardrobe" từ màn hình chính.

### Hai lỗi thường gặp

**"Ứng dụng không được cài từ nguồn chưa biết"**
Vào Cài đặt → Ứng dụng → Cài đặt app mới → bật *"Cho phép từ nguồn đó"*
cho ứng dụng đang mở file (Tệp/Chrome), rồi cài lại.

**"Ứng dụng này chưa được cài" / xung đột chữ ký**
Bản Play đã cài trùng package nhưng ký bằng keystore khác. Gỡ bản cũ trước:

```
Cài đặt → Ứng dụng → Smart Wardrobe → Gỡ cài đặt
```

Rồi cài lại APK.

---

## Cách 2 — Cài qua ADB từ PC (tiện hơn nếu làm nhiều lần)

Bật **Developer options** trên máy: Cài đặt → Giới thiệu điện thoại → Bấm
7 lần vào **Số hiệu bản dựng**. Sau đó vào Cài đặt → Hệ thống → Tuỳ chọn nhà
phát triển → bật **Gỡ lỗi USB**.

Kết nối USB máy với PC, chọn chế độ **Truyền tệp (MTP)**, chấp nhận
hộp thoại "Cho phép gỡ lỗi USB".

```powershell
adb install -r "D:\_HYCAT\smart-wardrobe-mobile\build\app\outputs\flutter-apk\app-release.apk"
```

`-r` = thay thế bản cũ, giữ dữ liệu. Bỏ `-r` để cài sạch.

Lệnh kiểm tra:
```powershell
adb shell pm list packages | Select-String smartwardrobe
```

Gỡ cài đặt:
```powershell
adb uninstall online.hycat.closy
```

### Cài và chạy ngay không cần cài app
```powershell
flutter run --release --use-application-binary="build\app\outputs\flutter-apk\app-release.apk"
```

---

## Sau khi cài — checklist test

Chạy theo thứ tự, ghi lại lỗi nếu có:

- [ ] App mở được, không crash, giao diện tiếng Việt
- [ ] **Đăng nhập** bằng `user` / `123456` — quan trọng nhất, xác nhận
      kết nối production
- [ ] **Đăng nhập Google** — bước quyết định xem có cần đăng ký Android
      OAuth client với SHA-1 không
- [ ] Tủ đồ: danh sách món hiển thị ảnh (không phải ô trống)
- [ ] **Thêm 1 món đồ** từ thư viện — xác nhận Cloudinary hoạt động
      (tách nền được, không phải cloud `demo`)
- [ ] Phối đồ AI: tạo được gợi ý
- [ ] Studio thủ công: kéo thả món lên canvas, lưu được
- [ ] Cộng đồng: xem được bài đăng
- [ ] Bộ phối đã lưu → xem chi tiết (ảnh bìa chiếm ~78%, thanh nút dính đáy)
- [ ] Hồ sơ: số dư + lịch sử ví + xem gói mở được
- [ ] Trang chính sách bảo mật mở được
- [ ] **Không** có mục thanh toán trong app (đúng chính sách Play)

### Dấu hiệu app đang trỏ sai môi trường

| Hiện tượng | Nguyên nhân |
|---|---|
| Không đăng nhập được, báo lỗi mạng | API sai, hoặc máy không có Internet |
| Tất cả món đồ lỗi ảnh | Thiếu `--dart-define=CLOUDINARY_CLOUD_NAME` |
| Ảnh upload không tách nền | BE trả signature sai, hoặc cloud sai |
| Trang trắng sau khi vào tủ đồ | API trả lỗi 500 — kiểm tra `api.closy.hycat.online` |

---

## Sau khi test OK

1. Chụp ảnh theo `docs/Store_Screenshots_Guide.md`
2. Upload AAB lên Play Internal testing:
   `build\app\outputs\bundle\release\app-release.aab`
3. Cài bản từ Play (link opt-in) và test lại một lần — đây mới là bản
   submit ảnh chụp từ đó

## Gỡ app khi cần

```
Cài đặt → Ứng dụng → Smart Wardrobe → Gỡ cài đặt
```

Xoá app **không** xoá tài khoản trên server. Muốn xoá dữ liệu thật sự thì
gửi yêu cầu tới `hycat.support@gmail.com`.
