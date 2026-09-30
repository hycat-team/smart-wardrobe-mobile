# Chọn và cài đúng file APK

Bản build `--split-per-abi` tạo ra **3 file riêng biệt**, mỗi file dành cho
một loại máy. Chọn sai → app không cài được hoặc báo lỗi ngay.

File nằm ở:
```
D:\_HYCAT\smart-wardrobe-mobile\build\app\outputs\flutter-apk\
```

---

## 1. Chọn file nào

| File | Dung lượng | Dùng cho máy nào |
|---|---|---|
| **`app-arm64-v8a-release.apk`** | **24.1 MB** | **Hầu hết điện thoại từ 2018 trở lại — chọn file này** |
| `app-armeabi-v7a-release.apk` | 21.9 MB | Máy cũ, máy rẻ, máy bảo mật (32-bit) |
| `app-x86_64-release.apk` | 25.6 MB | **Chỉ dùng cho emulator máy tính**, không cài lên điện thoại |
| ~~`app-release.apk`~~ | 62.7 MB | Bản universal, chứa cả 3 — chạy được mọi máy nhưng nặng |

### Cách chọn chắc chắn nhất

**Thử `arm64-v8a` trước.** Đây là kiến trúc của mọi flagship hiện nay
(Samsung Galaxy, iPhone đổi sang Android, Xiaomi, Oppo, Vivo…).

Cài được → xong. Báo lỗi `INSTALL_FAILED_NO_MATCHING_ABIS` → thử
`armeabi-v7a`.

### Cách xem máy dùng kiến trúc nào

**Cách 1 — không cần công cụ, thử thẳng:**
Cài `arm64-v8a`. Nếu được thì đúng luôn.

**Cách 2 — dùng ADB (chính xác 100%):**
```powershell
adb shell getprop ro.product.cpu.abi
```
Kết quả sẽ là `arm64-v8a`, `armeabi-v7a`, hoặc `x86_64`.

**Cách 3 — xem trên máy không cần PC:**
Cài app **CPU-Z** hoặc **DevCheck** từ Play Store, mở mục "CPU" / "Abi".

**Cách 4 — web:** <https://whatismybrowser.com/phone-detector> nhập tên
máy, xem mục Architecture.

---

## 2. Tại sao có nhiều file

Máy Android dùng CPU khác nhau, mà mỗi CPU cần mã máy (native code) khác
nhau. Một app Flutter phải chứa **cả 3 bản** trong một file thì mới chạy
được trên mọi máy — đó là lý do `app-release.apk` nặng 63 MB.

| Kiến trúc | Dung lượng lib | Dùng trên |
|---|---|---|
| `arm64-v8a` | 19.6 MB | Máy 64-bit (mới) |
| `armeabi-v7a` | 17.4 MB | Máy 32-bit (cũ) |
| `x86_64` | 21.1 MB | Emulator, Chromecast |

Bản universal nhét cả 3 vào → 62.7 MB. Bản tách chỉ nhét 1 → 24.1 MB.
**Tiết kiệm 62%.**

### Vì sao x86_64 vô dụng trên điện thoại

Kiến trúc `x86_64` là của **máy tính Intel/AMD**. Điện thoại dùng kiến trúc
ARM của ARM Holdings. Nên `x86_64` chỉ dành cho Android Studio Emulator.

---

## 3. Cài đặt

### Cách A — chép file vào máy (không cần USB)

1. Copy **1 file .apk** (đúng kiến trúc) sang điện thoại qua USB / Drive / Zalo
2. Mở app **Tệp** (Files) → bấm vào file `.apk`
3. Nếu hỏi *"Cho phép cài ứng dụng từ nguồn này không?"* → bật quyền cho
   **Tệp** hoặc **Chrome** → quay lại → **Cài đặt**

### Cách B — qua ADB

Bật Developer options: Cài đặt → Giới thiệu điện thoại → bấm 7 lần
**Số hiệu bản dựng**. Rồi Cài đặt → Hệ thống → Tuỳ chọn nhà phát triển →
bật **Gỡ lỗi USB**.

```powershell
# Kiểm tra máy dùng kiến trúc nào
adb shell getprop ro.product.cpu.abi

# Cài đúng file
adb install -r "build\app\outputs\flutter-apk\app-arm64-v8a-release.apk"
```

`-r` = thay thế bản cũ, giữ dữ liệu. Bỏ `-r` để cài sạch.

Gỡ cài đặt:
```powershell
adb uninstall online.hycat.closy
```

---

## 4. Lỗi thường gặp

| Lỗi | Nguyên nhân | Cách sửa |
|---|---|---|
| `INSTALL_FAILED_NO_MATCHING_ABIS` | Chọn sai kiến trúc | Thử `arm64-v8a`, không được thì `armeabi-v7a` |
| `App not installed` | Đã có bản Play, chữ ký khác | Gỡ bản cũ rồi cài lại |
| `App not installed` (lần 2) | Bản cũ cùng chữ ký nhưng versionCode thấp hơn | Gỡ bản cũ rồi cài lại |
| `Ứng dụng không được cài từ nguồn chưa biết` | Chưa bật quyền nguồn | Cài đặt → Ứng dụng → Cài đặt app mới → bật cho nguồn đó |
| `Parse error` / hỏng file | File chép sang bị hỏng | Chép lại, kiểm tra kích thước khớp bảng ở mục 1 |

### Vì sao phải gỡ bản cũ

Android yêu cầu: **app mới phải ký bằng cùng keystore** và **versionCode
không được thấp hơn** bản đang cài.

Nếu máy bạn đã cài app từ Google Play (ký đúng upload keystore của bạn),
thì APK này cũng ký bằng keystore đó → chỉ cần gỡ là cài được, không mất
dữ liệu.

Cách gỡ: Cài đặt → Ứng dụng → Smart Wardrobe → **Gỡ cài đặt**

---

## 5. Vì sao bản tách lại có versionCode khác — và vì sao không sao

Bạn sẽ thấy khi kiểm tra:

| File | versionCode |
|---|---|
| `app-release.apk` (universal) | `2` |
| `app-arm64-v8a-release.apk` | `2002` |
| `app-armeabi-v7a-release.apk` | `1002` |
| `app-x86_64-release.apk` | `4002` |

Flutter tự cộng `1000 × số thứ tự kiến trúc` vào versionCode để các file
không đụng nhau. Đây là **hành vi đúng và cần thiết** (tài liệo Android:
`configure-APK-splits`).

### Ảnh hưởng thực tế

⚠ **Nếu bạn cài APK tách (versionCode 2002) rồi cài bản từ Play (AAB,
versionCode 2) — sẽ báo lỗi downgrade.** Vì 2 < 2002.

**Cách xử lý:** gỡ bản APK trước khi cài bản Play. Nhắc lại: gỡ app
**không** xoá tài khoản trên server.

Nếu muốn cài đè cho gọn thì dùng bản **universal** (`app-release.apk`) vì nó
cùng versionCode 2 với AAB.

### Không ảnh hưởng lên Google Play

Bản upload lên Play là **`.aab`**, không phải 3 file APK này. Play tự tách
cho từng máy và **tự quản lý versionCode**. Nên các con số `2002/1002/4002`
chỉ có ý nghĩa khi bạn cài tay.

---

## 6. Build lại như thế nào

Thêm `--split-per-abi` vào lệnh build:

```powershell
flutter build apk --release `
  --split-per-abi `
  --no-tree-shake-icons `
  --dart-define=API_BASE_URL=https://api.closy.hycat.online/api/v1 `
  --dart-define=API_BASE_URL_ANDROID=https://api.closy.hycat.online/api/v1 `
  --dart-define=CLOUDINARY_CLOUD_NAME=dzvwkngxu `
  --dart-define=GOOGLE_CLIENT_ID=368645245473-5ovjq88e58p97u81asjssbt2bt8bnpt9.apps.googleusercontent.com `
  --dart-define=ENABLE_PAID_FEATURES=false
```

Khác với bản universal chỉ **một từ**: `--split-per-abi`.

Kết quả (đã build và kiểm chứng trên máy này):

```
√ Built app-armeabi-v7a-release.apk (21.9MB)
√ Built app-arm64-v8a-release.apk (24.1MB)
√ Built app-x86_64-release.apk (25.6MB)
```

### Khi nào dùng bản nào

| Mục đích | Dùng |
|---|---|
| Cài máy thật để test/chụp ảnh | **Bản tách** — nhẹ, nhanh |
| Muốn một file duy nhất, không cần chọn | `app-release.apk` (63 MB) |
| Upload lên Google Play | **`app-release.aab`** — không phải APK |

---

## 7. Kiểm tra trước khi cài

```powershell
powershell -ExecutionPolicy Bypass -File tool\verify_release.ps1
```

Script kiểm tra file universal. Nếu bạn dùng bản tách, kiểm tra thủ công:

```powershell
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
$aapt2 = "$env:LOCALAPPDATA\Android\Sdk\build-tools\36.0.0\aapt2.exe"
$apksigner = "$env:LOCALAPPDATA\Android\Sdk\build-tools\36.0.0\apksigner.bat"

$f = "build\app\outputs\flutter-apk\app-arm64-v8a-release.apk"
& $aapt2 dump badging $f | Select-String "package:|native-code"
& $apksigner verify --print-certs $f | Select-String "certificate DN"
```

Kết quả đúng:

```
package: name='online.hycat.closy' versionCode='2002' versionName='1.0.0'
native-code: 'arm64-v8a'
Signer #1 certificate DN: CN=hycat, OU=closy, O=hycat, ...
```

Ba dấu hiệu cần đúng:
- `package` = `online.hycat.closy`
- `native-code` đúng kiến trúc máy bạn
- Có dòng `certificate DN` → **đã ký** (không có dòng này = build lỗi)

---

## 8. Gợi ý cho người dùng thật

Người dùng tải từ Google Play sẽ **không** thấy 3 file này. Play nhận
`.aab` rồi tự tải đúng phần cần cho máy mỗi người, dung lượng tải về
tương đương bản tách (khoảng 25 MB, có thể còn nhỏ hơn vì Play nén thêm).

Ba file APK chỉ phục vụ **bạn test nội bộ**. Không bao giờ gửi file này cho
người dùng cuối.
