# Cấu hình Google OAuth cho APK Closy (Android)

> Hướng dẫn **đầy đủ, từng bước** để đăng nhập bằng Google hoạt động trên bản
> APK (`online.hycat.closy`) — cả bản cài tay lẫn bản lên Google Play.
>
> Liên quan: [`google-login-frontend-guide.md`](./google-login-frontend-guide.md)
> (hợp đồng API), [`Release_Play_Checklist.md`](./Release_Play_Checklist.md) §2
> (lệnh build).

---

## 0. Hiểu nhanh: cần 2 loại OAuth client, không phải 1

Đây là nguồn gây nhầm lẫn nhiều nhất. Google Sign-In trên Android cần **cả hai**:

| Loại client | Dùng để làm gì | Cấu hình ở đâu trong code |
|---|---|---|
| **Web (Server) client** | Làm `serverClientId` → Credential Manager dùng nó để **cấp `idToken`** | `AppConstants.googleClientId` (`--dart-define=GOOGLE_CLIENT_ID`) + fallback `res/values/strings.xml` |
| **Android client** | Xác thực **chính app đang chạy** qua cặp `package name` + `SHA-1` của chứng thư ký | **Không nằm trong code** — khai trong Google Cloud Console |

Luồng thật trên máy:

```
Bấm nút → Credential Manager → Google Play services đối chiếu
   (package = online.hycat.closy, SHA-1 = <của keystore đã ký APK>)
   ↓ nếu khớp
Google cấp idToken ký bằng Web client ID
   ↓
app POST idToken → BE /auth/google → accessToken Closy
```

→ Nếu **thiếu hoặc sai Android client**, bước đối chiếu fail → Google Play services
trả `12500 / UNREGISTERED_ON_API_CONSOLE` → app **bấm nút xong không có gì xảy ra**.

---

## 1. Thông tin cần có trước khi bắt đầu

| Mục | Giá trị repo này |
|---|---|
| Google Cloud Project ID | `368645245473` |
| Package name (Android) | `online.hycat.closy` |
| SHA-1 — keystore **upload** (bản release/Play) | `BE:C4:0C:45:A0:C7:64:48:C9:40:19:99:6C:25:F0:F1:9C:E9:90:CC` |
| SHA-1 — keystore **debug** (bản `flutter run`) | `BC:30:C3:BB:88:62:0C:44:61:B3:33:7E:9B:7A:66:02:27:E1:66:78` |
| Web client ID (production) | `368645245473-5ovjq88e58p97u81asjssbt2bt8bnpt9.apps.googleusercontent.com` |
| Web client ID (dev, localhost) | `368645245473-u71cfbe461nl51us9dmlta6vfgcdun8a.apps.googleusercontent.com` |
| Web client ID (api-v2) | `368645245473-egk412r1rhc7s0iloms9e4mjh7bptsj3.apps.googleusercontent.com` |

> SHA-1 ở trên **đã verify** từ `android/key.properties` và
> `%USERPROFILE%\.android\debug.keystore` trên máy build. Vẫn nên tự chạy lệnh
> dưới để chắc chắn trước khi khai.

---

## 2. Tạo Android OAuth client

> **Tạo 1 cái là đủ** cho APK release. Một OAuth client gắn với **đúng một cặp**
> `package name + SHA-1`, nên mỗi keystore dùng để ký app cần một client riêng —
> nhưng bạn chỉ cần loại release. Mục 2.3 nói rõ khi nào cần thêm.

Console: <https://console.cloud.google.com/apis/credentials?project=368645245473>

1. Chọn project **`368645245473`** ở góc trên cùng.
2. **Credentials** → **Create Credentials** → **OAuth client ID**.
3. Loại: **Android**.
4. Điền:
   - **Name**: `Closy Android` (tên tự do, chỉ để đọc)
   - **Package name**: `online.hycat.closy` — **gõ tay, copy y hệt**
     (`applicationId` trong `android/app/build.gradle.kts:37`)
   - **SHA-1 fingerprint**: SHA-1 của **upload keystore**
     (`BE:C4:0C:45:A0:C7:64:48:C9:40:19:99:6C:25:F0:F1:9C:E9:90:CC`).
5. **Create**.

### 2.1 Khi nào cần tạo thêm client

| Tình huống | Cần thêm client với SHA-1 |
|---|---|
| Chỉ phát hành APK release / AAB cài tay | ❌ **không** — 1 cái ở trên là đủ |
| Dev cần `flutter run` (debug) test Google login | ✅ SHA-1 debug keystore `BC:30:C3:BB:...:78` |
| Đã bật **Play App Signing**, test bản cài từ Play | ✅ SHA-1 *App signing key* (xem phần cảnh báo bên dưới) |

Cách test Google login **không cần** client debug: build bản release trỏ
localhost rồi cài tay.

```powershell
flutter build apk --release --no-tree-shake-icons `
  --dart-define=API_BASE_URL=http://10.0.2.2:5000/api/v1 `
  --dart-define=API_BASE_URL_ANDROID=http://10.0.2.2:5000/api/v1 `
  --dart-define=CLOUDINARY_CLOUD_NAME=dzvwkngxu `
  --dart-define=GOOGLE_CLIENT_ID=368645245473-u71cfbe461nl51us9dmlta6vfgcdun8a.apps.googleusercontent.com
```

### 2.2 Lấy SHA-1 từ chính máy (chắc chắn nhất)

```powershell
$env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'

# SHA-1 upload keystore (bản release)
$kp = Get-Content android\key.properties -Encoding utf8
$sf = (($kp | Select-String '^storeFile=').Line -split '=',2)[1].Trim() -replace '\\\\','\'
$sp = (($kp | Select-String '^storePassword=(.*)$').Matches.Groups[1].Value)
& "$env:JAVA_HOME\bin\keytool.exe" -list -v -keystore $sf -storepass $sp |
  Select-String 'SHA1:|Owner:'

# SHA-1 debug keystore
& "$env:JAVA_HOME\bin\keytool.exe" -list -v `
  -keystore "$env:USERPROFILE\.android\debug.keystore" `
  -storepass android -alias androiddebugkey |
  Select-String 'SHA1:|Owner:'
```

⚠ **Đừng lấy SHA-1 từ Play Console.** Play Console hiện *nhiều* dòng
(*App signing key*, *Upload key certificate*, và các khoá cũ) — chỉ một dòng
đúng là dòng ký **app đang chạy trên máy**:

| Nguồn trong Play Console | Ký cái gì | Dùng cho OAuth? |
|---|---|---|
| **App signing key** (thẻ "In use", cột *Classical key*) | app sau khi bật Play App Signing | ✅ **đúng dòng này** nếu đã bật Play App Signing |
| Previous app signing keys | khoá **đã bị thay** | ❌ vô dụng |
| Upload key certificate | chỉ AAB bạn upload | ✅ cho APK cài tay (chính là SHA-1 ở §2) |

Rủi ro nhất khi **đã bật Play App Signing**: app trên Play được ký bằng
*app signing key*, khác SHA-1 upload key → client khai bằng SHA-1 upload key sẽ
**fail trên bản Play nhưng vẫn chạy trên APK cài tay**. Khi gặp tình huống này,
tạo thêm 1 client với SHA-1 *App signing key* (lấy trong Play Console → Setup →
App signing). Script `tool\capture_google_login_log.ps1` in sẵn DN + SHA-1 của
app đang cài kèm cảnh báo nếu đang dùng shared key.

---

## 3. Web client ID — đã có sẵn trong code, không cần làm gì thêm

Ứng dụng đọc client ID theo thứ tự
(`lib/core/constants/app_constants.dart:70`):

1. `--dart-define=GOOGLE_CLIENT_ID` (dùng khi build release)
2. Theo host của `API_BASE_URL` → `api-v2` / `api` / dev
3. `.env` (chỉ khi dev, **không** đóng gói vào bản build)

Có **fallback tĩnh** trong
`android/app/src/main/res/values/strings.xml` (`default_web_client_id`) —
`google_sign_in_android` 7.x đọc resource này khi `serverClientId` không được
truyền qua `initialize()`. Nhờ vậy APK build thiếu `--dart-define=GOOGLE_CLIENT_ID`
vẫn đăng nhập được thay vì chết im lặng ở `MISSING_SERVER_CLIENT_ID`.

⚠ Đổi môi trường → sửa **cả hai** chỗ rồi build lại.

---

## 4. Build & kiểm tra

```powershell
flutter build apk --release --no-tree-shake-icons `
  --dart-define=API_BASE_URL=https://api.closy.hycat.online/api/v1 `
  --dart-define=API_BASE_URL_ANDROID=https://api.closy.hycat.online/api/v1 `
  --dart-define=CLOUDINARY_CLOUD_NAME=dzvwkngxu `
  --dart-define=GOOGLE_CLIENT_ID=368645245473-5ovjq88e58p97u81asjssbt2bt8bnpt9.apps.googleusercontent.com `
  --dart-define=ENABLE_PAID_FEATURES=false
```

Self-check trước khi cài máy thật:

```powershell
powershell -ExecutionPolicy Bypass -File tool\verify_release.ps1
# mục 4: [ OK ] Production Google client ID embedded / [ OK ] Dev client ID absent
```

Cài và test:

```powershell
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

---

## 5. Bảng lỗi — tra đúng triệu chứng

| Triệu chứng | Nguyên nhân thật | Cách sửa |
|---|---|---|
| Bấm nút → **account chooser hiện, chọn xong không có gì xảy ra**, không báo lỗi, logcat có `UNREGISTERED_ON_API_CONSOLE` | Android OAuth client không khớp `package` hoặc `SHA-1` | Tạo lại Android client §2 với đúng cặp. Xem `build\play-login.log` |
| Nút đứng loading vĩnh viễn, không có log | `serverClientId` rỗng → `MISSING_SERVER_CLIENT_ID` (SDK await callback không bao giờ được gọi) | Truyền `--dart-define=GOOGLE_CLIENT_ID` hoặc sửa `res/values/strings.xml`. App đã có timeout 2 phút nên sẽ báo lỗi thay vì treo |
| Chọn xong báo `serverClientId must be provided on Android` | `AppConstants.googleClientId` trả `''` | Kiểm tra `--dart-define` đã truyền chưa, build lại |
| Báo **"Token Google không hợp lệ" / 400 từ BE** | Client ID **không khớp môi trường BE** — BE allow-list `GOOGLE_CLIENT_IDS` riêng từng env | `idToken` phải ký bằng Web client ID của đúng môi trường `API_BASE_URL`. Bảng §1 |
| Báo 403 `access_denied` / tài khoản chưa xác thực | Email Google chưa verify, hoặc app chưa publish (Google chỉ cấp `idToken` cho app đã verify) | Verify tài khoản; app internal testing thì test bằng tài khoản trong danh sách tester |
| Chạy debug OK, bản Play fail | Play App Signing dùng khoá khác upload key | Lấy SHA-1 *App signing key* từ Play Console rồi tạo thêm 1 Android client §2 |
| Chạy APK cài tay OK, chạy `flutter run` fail | 2 bản khác SHA-1 | Khai **cả hai** SHA-1 (2 Android client riêng) trong cùng project |

### Script bắt log khi fail

```powershell
powershell -ExecutionPolicy Bypass -File tool\capture_google_login_log.ps1 -Seconds 90
```

Trong lúc script chạy: mở app → bấm "Tiếp tục với Google" → chọn tài khoản →
đợi ~10 giây. Script lọc đúng các dòng liên quan và in DN + SHA-1 của chứng thư
đang ký app trên máy.

---

## 6. Checklist bàn giao

**Google Cloud Console**
- [ ] Android client: `online.hycat.closy` + SHA-1 upload keystore ← **đủ dùng cho APK release**
- [ ] *(chỉ khi dev `flutter run`)* Android client + SHA-1 debug keystore
- [ ] *(chỉ khi đã bật Play App Signing)* Android client + SHA-1 *App signing key*
- [ ] Web client production có `https://closy.hycat.online` trong **Authorized JavaScript origins**

**Trong repo**
- [ ] `android/app/src/main/res/values/strings.xml` — `default_web_client_id` khớp môi trường
- [ ] Build có `--dart-define=GOOGLE_CLIENT_ID` (Web client ID của môi trường đích)
- [ ] `tool\verify_release.ps1` → `RESULT: PASS`

**Trên máy thật**
- [ ] `adb install -r` xong, app mở được
- [ ] Bấm nút Google → chọn tài khoản → vào thẳng app, đúng tài khoản Closy
- [ ] `curl`/`/me` trả đúng profile (token thật, không phải `web_session_active`)
- [ ] Lặp lại 1 lần trên bản cài từ Play