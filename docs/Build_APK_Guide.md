# Hướng dẫn build APK release từng bước

Tài liệu này giải thích **từng lệnh** và **tại sao cần**, dành cho người muốn
tự build lại sau này. Mọi số liệu trong đây đã được kiểm chứng trên máy này.

Mục đích của APK: cài lên máy Android thật để **test** và **chụp ảnh** trước
khi lên Play. Nó không phải thứ submit lên Google Play (thứ đó là `.aab`).

---

## Mục lục

1. [Bạn cần chuẩn bị gì](#1-bạn-cần-chuẩn-bị-gì)
2. [Cấu hình production ở đâu](#2-cấu-hình-production-ở-đâu)
3. [Các bước build](#3-các-bước-build)
4. [Hiểu từng lệnh](#4-hiểu-từng-lệnh)
5. [Kiểm tra kết quả](#5-kiểm-tra-kết-quả)
6. [Xử lý lỗi thường gặp](#6-xử-lý-lỗi-thường-gặp)
7. [Cài lên máy thật](#7-cài-lên-máy-thật)
8. [Checklist test](#8-checklist-test-sau-khi-cài)

---

## 1. Bạn cần chuẩn bị gì

Kiểm tra bằng `flutter doctor`:

```powershell
flutter doctor
```

Trên máy này, các thành phần đã có sẵn:

| Thành phần | Giá trị | Ghi chú |
|---|---|---|
| Flutter | 3.47.2 (stable) | tại `C:\src\flutter` |
| Java | OpenJDK 25.0.2 | của Android Studio |
| Android SDK | tại `C:\Users\Mavil\AppData\Local\Android\sdk` | ghi ở `android/local.properties` |
| Upload keystore | `C:\Users\Mavil\upload-keystore.jks` | **bắt buộc**, xem mục 1.1 |
| `android/key.properties` | trong repo | **bắt buộc**, xem mục 1.2 |

### 1.1 Keystore (chữ ký số)

Là file chứng minh "app này là của tôi" khi cài lên Google Play. Mất thì
mất vĩnh viễn quyền update app.

Đã có sẵn: `C:\Users\Mavil\upload-keystore.jks` (RSA 2048-bit, hạn đến
15/02/2054, alias `upload`).

Tạo mới nếu chưa có:
```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkey -v `
  -keystore "$env:USERPROFILE\upload-keystore.jks" `
  -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Ở câu hỏi `Enter key password for <upload>` → **nhấn Enter** để dùng luôn
mật khẩu keystore (chỉ phải nhớ một mật khẩu).

### 1.2 File `key.properties`

```
D:\_HYCAT\smart-wardrobe-mobile\android\key.properties
```

Nội dung:
```properties
storePassword=<mật khẩu bạn đặt>
keyPassword=<mật khẩu bạn đặt>
keyAlias=upload
storeFile=C:\\Users\\Mavil\\upload-keystore.jks
```

⚠ **`\\` phải gấp đôi.** Đây là quy tắc escape của định dạng file
`.properties` của Java. Một dấu `\` đơn sẽ bị đọc thành escape (ví dụ `\u`
= Unicode) và Gradle sẽ không tìm thấy file keystore.

⚠ **Build release sẽ fail nếu thiếu file này.** `android/app/build.gradle.kts`
(dòng 51-54) chủ động throw exception, không fallback về debug key — đây là
thiết kế có chủ ý để tránh vô tình phát hành bản ký sai.

---

## 2. Cấu hình production ở đâu

Đây là phần dễ hiểu nhầm nhất. Đọc kỹ.

### Không có file config riêng cho production

Toàn bộ cấu hình nằm trong **tham số dòng lệnh** khi build. File `.env`
trong repo **không dùng cho bản build** (đã gỡ khỏi `assets` ngày
2026-09-30 để không lộ cấu hình production trong file phát hành).

### `.env` chỉ dùng cho `flutter run`

```powershell
# Dùng cho phát triển — đọc file .env
flutter run --dart-define=API_BASE_URL=http://localhost:5000/api/v1

# Dùng cho phát hành — đọc tham số dòng lệnh, BỎ QUA .env
flutter build apk --release --dart-define=API_BASE_URL=https://api.closy.hycat.online/api/v1
```

### Tại sao `--dart-define` lại quan trọng

Flutter **nạp giá trị lúc biên dịch** rồi ghi thẳng vào bytecode (file
`.so`/`.dll`). Nghĩa là:

1. Giá trị bị **đóng bóng cứng** vào app — không đổi được lúc chạy
2. Muốn đổi config → **phải build lại từ đầu**
3. Nếu quên truyền `--dart-define`, code rơi về giá trị mặc định trong
   source và app sẽ hỏng

Trong `app_constants.dart` có cơ chế fail-fast: nếu bản release mà URL rỗng
hoặc chứa `[IP_ADDRESS]`, app **throw exception** ngay khi khởi động thay vì
lặng lẽ chạy sai.

### 5 giá trị bắt buộc

| Tham số | Giá trị production | Tại sao cần |
|---|---|---|
| `API_BASE_URL` | `https://api.closy.hycat.online/api/v1` | Backend chính, dùng cho web/desktop |
| `API_BASE_URL_ANDROID` | `https://api.closy.hycat.online/api/v1` | **Android runtime đọc biến này TRƯỚC** `API_BASE_URL`. Thiếu → emulator trỏ localhost |
| `CLOUDINARY_CLOUD_NAME` | `dzvwkngxu` | Tên cloud lưu ảnh. Thiếu → rơi về `'demo'`, upload hỏng |
| `GOOGLE_CLIENT_ID` | `368645245473-5ovjq88e...` | Đăng nhập Google. Phải là client **PROD** |
| `ENABLE_PAID_FEATURES` | `false` | Chính sách Google Play: không thu tiền trong app |

### Cạm bẫy: chọn sai GOOGLE_CLIENT_ID

`.env` có 3 client ID:

```
GOOGLE_CLIENT_ID      = 368645245473-u71cfbe461...   ← DEV
GOOGLE_CLIENT_ID_PROD = 368645245473-5ovjq88e5...   ← PROD (dùng cái này)
GOOGLE_CLIENT_ID_V2   = 368645245473-egk412r1r...   ← api-v2
```

Backend có **allow-list client ID theo môi trường** (`docs/google-login-frontend-guide.md:29`).
Dùng client dev với API production → app nhận `idToken` sai `aud` → **BE từ chối**.

---

## 3. Các bước build

Mở PowerShell, đảm bảo đang ở đúng thư mục dự án:

```powershell
cd D:\_HYCAT\smart-wardrobe-mobile
```

### Bước 1 — Tăng version (chỉ khi phát hành bản mới)

Mở `pubspec.yaml`, sửa dòng 4:
```yaml
version: 1.0.0+2
```

Cấu trúc: `<tên hiển thị>+<mã số tăng dần>`

- `1.0.0` — người dùng thấy
- `2` — hệ thống phân biệt. **Phải lớn hơn mọi bản đã upload**, nếu không
  Play Console từ chối

### Bước 2 — Dọn dẹp

```powershell
flutter clean
flutter pub get
```

`flutter clean` xoá toàn bộ thư mục `build/`, buộc build lại từ đầu. Cần
khi: đổi SDK, đổi cấu hình, hoặc build bị lỗi lạ.

⚠ **`flutter clean` XOÁ file APK/AAB đã build.** Copy ra chỗ khác trước nếu
cần giữ.

### Bước 3 — Build

```powershell
flutter build apk --release `
  --no-tree-shake-icons `
  --dart-define=API_BASE_URL=https://api.closy.hycat.online/api/v1 `
  --dart-define=API_BASE_URL_ANDROID=https://api.closy.hycat.online/api/v1 `
  --dart-define=CLOUDINARY_CLOUD_NAME=dzvwkngxu `
  --dart-define=GOOGLE_CLIENT_ID=368645245473-5ovjq88e58p97u81asjssbt2bt8bnpt9.apps.googleusercontent.com `
  --dart-define=ENABLE_PAID_FEATURES=false
```

Chạy mất khoảng **80 giây**. Màn hình sẽ hiện dòng tiến trình, cuối cùng:

```
✓ Built build\app\outputs\flutter-apk\app-release.apk (63.3MB)
```

### Kết quả

| Đường dẫn | Dung lượng | Dùng để |
|---|---|---|
| `build\app\outputs\flutter-apk\app-release.apk` | 63.3 MB | **Cài máy thật, test, chụp ảnh** |
| `build\app\outputs\bundle\release\app-release.aab` | 62.3 MB | **Upload lên Google Play** |

Hai lệnh khác nhau:

| | Lệnh | File | Mục đích |
|---|---|---|---|
| Cài tay | `flutter build apk --release` | `.apk` | Test nhanh, cài trực tiếp |
| Lên Play | `flutter build appbundle --release` | `.aab` | Google Play bắt buộc |

---

## 4. Hiểu từng lệnh

### `flutter build apk --release`

| Thành phần | Ý nghĩa |
|---|---|
| `flutter build` | Lệnh build của Flutter |
| `apk` | Định dạng đầu ra: Android Package |
| `--release` | Bản tối ưu, dành cho người dùng thật |

Khác `--release`:
- **Debug** — chạy nhanh, có hot reload, **không** tối ưu, KHÔNG ký, KHÔNG
  dùng để chụp ảnh
- **Profile** — đo hiệu năng

### `--no-tree-shake-icons`

Lệnh mặc định chạy `font-subset.exe` để tối ưu icon. Trên Windows, **Windows
Application Control chặn file thực thi này** → build lỗi.

Tắt tree-shaking icon: file lớn hơn một chút, nhưng build thành công. Ảnh
chụp màn hình không bị ảnh hưởng.

### 5 cặp `--dart-define=X=Y`

Gán giá trị hằng cho biến đọc bằng `String.fromEnvironment` /
`bool.fromEnvironment` trong code. Giá trị được ghi vào bytecode lúc biên dịch.

Đọc ở `app_constants.dart`:
```dart
static String get baseUrl {
  const definedUrl = String.fromEnvironment('API_BASE_URL');
  const definedAndroidUrl = String.fromEnvironment('API_BASE_URL_ANDROID');
  // Android runtime dùng definedAndroidUrl TRƯỚC
  ...
}
```

⚠ Dấu `=` dính liền, **không có khoảng trắng**. Sai cú pháp thường bị bỏ
qua âm thầm → app rơi về localhost → không đăng nhập được.

⚡ Backtick `` ` `` ở cuối dòng nghĩa là "nối dòng" trong PowerShell. Phải có
thêm backtick ngay sau chữ ` đó. Thiếu backtick → chỉ chạy được dòng đầu.

### `--release` dùng signing config nào

`android/app/build.gradle.kts` dòng 65-69:
```kotlin
buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
    }
}
```
→ đọc `android/key.properties`.

---

## 5. Kiểm tra kết quả

Đừng tin build thành công là đủ. Có script tự động kiểm tra tất cả:

```powershell
powershell -ExecutionPolicy Bypass -File tool\verify_release.ps1
```

Script kiểm tra 6 nhóm: file tồn tại, package/version/ABI, chữ ký khớp
keystore, config production đã nhúng, không lọt `.env`, không lỗ secret.
Kết quả hiện tại:

```
=== 1. File exists ===
  [ OK ] APK: 63.3 MB
  [ OK ] AAB: 62.3 MB

=== 2. Package / version ===
  [ OK ] package = com.smartwardrobe.smart_wardrobe
  [ .. ] versionCode = 2  versionName = 1.0.0
  [ OK ] versionCode matches metadata (2)
  [ OK ] All 3 ABIs present (ARM/ARM64/x86)

=== 3. Signature ===
  [ OK ] Signed: CN=hycat, OU=closy, O=hycat, L=Ho Chi Minh, ST=Thu Duc
  [ .. ] Keystore SHA-256 = FA:5E:06:57:...:24

=== 4. Production config ===
  [ OK ] Production API embedded
  [ OK ] Cloudinary dzvwkngxu embedded
  [ OK ] Production Google client ID embedded
  [ OK ] Dev client ID absent

=== 5. No .env leak ===
  [ OK ] No .env inside APK

=== 6. No secret leak ===
  [ OK ] No Cloudinary api_secret (signature comes from BE)

RESULT: PASS - ready to install on a real device.
```

Exit code `0` = pass, `1` = có lỗi. Nếu `[FAIL]` ở mục 3 hoặc 4 thì **không
cài lên máy**, phải sửa rồi build lại.

### Các lệnh kiểm tra thủ công

Dưới đây là các lệnh mà script chạy, để bạn hiểu hoặc chạy riêng.

#### 5.1 File có tồn tại

```powershell
Get-Item "build\app\outputs\flutter-apk\app-release.apk" | Select-Object Name, Length
```
Kỳ vọng: `Length` khoảng 66.000.000 (≈63 MB).

### 5.2 Đúng package và version

```powershell
$aapt2 = "$env:LOCALAPPDATA\Android\Sdk\build-tools\36.0.0\aapt2.exe"
& $aapt2 dump badging "build\app\outputs\flutter-apk\app-release.apk" | Select-String "package:|sdkVersion|native-code"
```

Kỳ vọng:
```
package: name='com.smartwardrobe.smart_wardrobe' versionCode='2' versionName='1.0.0'
minSdkVersion:'24'
targetSdkVersion:'36'
native-code: 'arm64-v8a' 'armeabi-v7a' 'x86_64'
```

- `versionCode` phải lớn hơn bản trước
- `native-code` có cả 3 kiến trúc → chạy được trên mọi máy Android

### 5.3 Đã ký đúng keystore

```powershell
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
$sdk = "$env:LOCALAPPDATA\Android\Sdk"
$apksigner = "$sdk\build-tools\36.0.0\apksigner.bat"
& $apksigner verify --print-certs "build\app\outputs\flutter-apk\app-release.apk"
```

Kỳ vọng thấy:
```
Signer #1 certificate DN: CN=hycat, OU=closy, O=hycat, L=Ho Chi Minh, ST=Thu Duc, C=Unknown
Signer #1 certificate SHA-256 digest: fa5e065786d8011cda38cfea7d1a92fc8e410ed07c377afcb7e7fa3dcd70aa24
```

`SHA-256 digest` này phải khớp với keystore:
```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -list -v `
  -keystore "$env:USERPROFILE\upload-keystore.jks" -storepass <mật khẩu> -alias upload |
  Select-String "SHA256"
```

Lưu ý: `keytool` in nhãn `SHA256:` (không có dấu gạch), còn `apksigner` in
`SHA-256 digest:`. Giá trị giống nhau, chỉ khác format — một chữ thường, có
thêm dấu `:`.

⚠ **Không có dòng DN** → build **không** ký. Đó là lỗi nghiêm trọng, file cài
lên máy sẽ không chạy được trên bản đã có trên Play.

### 5.4 Config production đã nhúng đúng

Đây là bước quan trọng nhất — xác nhận app thật sự trỏ production, không phải
localhost. Bỏ qua bước này thì có thể build nhầm mà không biết.

```powershell
$tmp = "$env:TEMP\apkcheck"
Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $tmp | Out-Null
Push-Location $tmp
& "C:\Program Files\Android\Android Studio\jbr\bin\jar.exe" xf `
  "D:\_HYCAT\smart-wardrobe-mobile\build\app\outputs\flutter-apk\app-release.apk" `
  "lib/arm64-v8a/libapp.so"
Pop-Location

$t = [System.Text.Encoding]::ASCII.GetString([System.IO.File]::ReadAllBytes("$tmp\lib\arm64-v8a\libapp.so"))
@('https://api.closy.hycat.online/api/v1','dzvwkngxu','5ovjq88e58p97u81asjssbt2bt8bnpt9','u71cfbe461nl51us9dmlta6vfgcdun8a','10.0.2.2','api_secret') |
  ForEach-Object { if ($t -match [regex]::Escape($_)) { "FOUND : $_" } else { "absent: $_" } }
```

Kết quả đúng — 3 dòng đầu FOUND, 3 dòng sau absent:
```
FOUND : https://api.closy.hycat.online/api/v1       ← production ✓
FOUND : dzvwkngxu                                    ← Cloudinary ✓
FOUND : 5ovjq88e58p97u81asjssbt2bt8bnpt9            ← client PROD ✓
absent: u71cfbe461nl51us9dmlta6vfgcdun8a            ← client DEV không được nhúng ✓
absent: 10.0.2.2                                     ← không còn localhost emulator ✓
absent: api_secret                                   ← không lọt secret ✓
```

### 5.5 Không lộ file .env

```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\jar.exe" tf `
  "build\app\outputs\flutter-apk\app-release.apk" | Select-String "\.env$"
```

**Kết quả phải rỗng.** Nếu có dòng nào trả về, file cấu hình đã bị đóng gói
vào app — ai tải app từ Play cũng đọc được. Khi đó xoá `.env` khỏi mục
`assets` trong `pubspec.yaml`.

---

## 6. Xử lý lỗi thường gặp

| Lỗi | Nguyên nhân | Cách sửa |
|---|---|---|
| `Missing android/key.properties` | Chưa tạo file | Xem mục 1.2 |
| `keystore file not found` | `\\` bị sửa thành `\` | Sửa lại thành `\\` |
| `Wrong password` | Sai mật khẩu trong `key.properties` | Nhập lại, phân biệt hoa/thường |
| `C:‎/src/flutter` not found | `flutter.sdk` sai | Kiểm tra `android/local.properties` |
| Build chậm 10+ phút lần đầu | Gradle tải dependencies | Bình thường, các lần sau nhanh hơn |
| `failed to strip debug symbols` | Thiếu NDK licenses | `flutter doctor --android-licenses` (không chặn build APK) |
| App mở ra trắng, không đăng nhập được | Sai `API_BASE_URL` | Kiểm tra lại mục 5.4 |
| Ảnh upload hỏng | Thiếu `CLOUDINARY_CLOUD_NAME` | Thêm lại tham số |
| `flutter clean` xoá mất file | Đã build xong, chạy clean | Copy file ra chỗ khác trước |

### Sửa sau khi đã build

Thay đổi code hoặc config → build lại từ Bước 1 (không cần `flutter clean`
nếu chỉ đổi code Dart). Đổi cấu hình hệ thống → nên `flutter clean`.

---

## 7. Cài lên máy thật

Chi tiết đầy đủ ở `docs/Install_APK_Guide.md`. Tóm tắt:

**Cách nhanh nhất — không cần USB:**
1. Copy `app-release.apk` sang điện thoại
2. Mở app **Tệp**, bấm vào file `.apk`
3. Cho phép cài từ nguồn đó → **Cài đặt**

**Có USB + ADB:**
```powershell
adb install -r "build\app\outputs\flutter-apk\app-release.apk"
```

⚠ **APK này trỏ production, dữ liệu thật.** Tài khoản `user / 123456` sẽ bị
thay đổi nếu bạn xoá món đồ hoặc bộ phối. Dùng tài khoản phụ nếu muốn giữ
nguyên dữ liệu mẫu.

⚠ Nếu máy đã cài bản từ Google Play: phải **gỡ bản cũ trước**, vì chữ ký
khác nhau sẽ gây lỗi "xung đột".

---

## 8. Checklist test sau khi cài

Chạy theo thứ tự. Đây là bản release thật, nên mọi thứ đều gọi production.

- [ ] App mở được, không crash, giao diện tiếng Việt
- [ ] **Đăng nhập `user` / `123456`** — xác nhận kết nối production
- [ ] **Đăng nhập Google** — bước này quyết định xem có cần đăng ký Android
      OAuth client với SHA-1 trên Google Cloud Console hay không
- [ ] Tủ đồ: món đồ hiển thị ảnh đúng, không phải ô trống
- [ ] **Thêm 1 món đồ** từ thư viện → tách nền thành công (kiểm tra Cloudinary)
- [ ] Phối đồ AI: tạo được gợi ý
- [ ] Studio thủ công: kéo thả, lưu được bộ phối
- [ ] Cộng đồng: xem được bài đăng
- [ ] Chi tiết bộ phối: ảnh bìa chiếm phần lớn, thanh nút dính đáy
- [ ] Hồ sơ: số dư, lịch sử ví, xem gói đều mở được
- [ ] Chính sách bảo mật mở được
- [ ] **Không** có mục thanh toán trong app (đúng chính sách Play)

### Chẩn đoán khi app trỏ sai môi trường

| Hiện tượng | Nguyên nhân |
|---|---|
| Báo lỗi mạng, không đăng nhập được | Sai `API_BASE_URL`, hoặc máy không có Internet |
| Mọi ảnh tủ đồ lỗi | Thiếu `CLOUDINARY_CLOUD_NAME` |
| Upload ảnh không tách nền | Backend trả signature sai |
| Trang trắng sau khi vào tủ đồ | API lỗi 500 — kiểm tra `api.closy.hycat.online` |

---

## Sau khi test OK

1. Chụp ảnh theo `docs/Store_Screenshots_Guide.md`
2. Build AAB và upload Play:
   ```powershell
   flutter build appbundle --release --no-tree-shake-icons `
     --dart-define=API_BASE_URL=https://api.closy.hycat.online/api/v1 `
     --dart-define=API_BASE_URL_ANDROID=https://api.closy.hycat.online/api/v1 `
     --dart-define=CLOUDINARY_CLOUD_NAME=dzvwkngxu `
     --dart-define=GOOGLE_CLIENT_ID=368645245473-5ovjq88e58p97u81asjssbt2bt8bnpt9.apps.googleusercontent.com `
     --dart-define=ENABLE_PAID_FEATURES=false
   ```
3. Cài bản từ Play Internal testing và chụp ảnh lại — **đây mới là bản submit**

Nội dung chữ cho Store listing: `docs/Store_Listing.md`
