# Flutter → Google Play Deployment Guide

**Mục tiêu:** Deploy ứng dụng Flutter lên Google Play Store  
**Đối tượng:** Flutter Developer / FYP Team  
**Platform:** Android + Google Play Console  
**Trạng thái:** Deployment Checklist

---

## 1. Tổng quan quy trình

```text
Flutter Project
      ↓
1. Chuẩn bị package name + version
      ↓
2. Tạo upload keystore
      ↓
3. Cấu hình Android signing
      ↓
4. Build Android App Bundle (.aab)
      ↓
5. Tạo app trên Google Play Console
      ↓
6. Upload AAB → Internal testing
      ↓
7. Kiểm tra app thực tế
      ↓
8. Closed testing
      ↓
9. Nếu là Personal account mới:
   12 testers × 14 ngày liên tục
      ↓
10. Apply Production access
      ↓
11. Production release
      ↓
12. Google review
      ↓
13. App được phát hành trên Google Play
```

> **Khuyến nghị:** Không upload Production ngay. Hãy đi theo Internal Testing → Closed Testing → Production.

---

# 2. Chuẩn bị Flutter Project

Mở terminal tại thư mục project:

```powershell
cd D:\Project\your-flutter-project
```

Kiểm tra Flutter:

```powershell
flutter doctor
```

Cài dependencies:

```powershell
flutter pub get
```

Test app:

```powershell
flutter run
```

Trước khi deploy, cần kiểm tra tối thiểu:

- [ ] Login / Register
- [ ] API production
- [ ] Upload image
- [ ] Camera
- [ ] Runtime permissions
- [ ] Google Maps nếu có
- [ ] Firebase nếu có
- [ ] Notification nếu có
- [ ] Deep link nếu có
- [ ] App icon
- [ ] Splash screen
- [ ] UI trên nhiều kích thước màn hình

---

# 3. Chốt Application ID

Mở một trong các file:

```text
android/app/build.gradle.kts
```

hoặc:

```text
android/app/build.gradle
```

Tìm:

```kotlin
defaultConfig {
    applicationId = "..."
}
```

Ví dụ:

```kotlin
defaultConfig {
    applicationId = "com.veggieconnect.app"
}
```

## Lưu ý quan trọng

`applicationId` là identifier của Android application.

Nên dùng package production ngay từ đầu, ví dụ:

```text
com.veggieconnect.app
```

Không nên để:

```text
com.example.veggieconnect
```

Nếu app đã được publish trên Google Play thì không thể đổi application ID của app đó thành một app ID khác.

---

# 4. Cấu hình Version

Mở:

```text
pubspec.yaml
```

Tìm:

```yaml
version: 1.0.0+1
```

Cấu trúc:

```text
1.0.0+1
│ │ │ │
│ │ │ └── versionCode
│ └────── versionName
```

Bản đầu:

```yaml
version: 1.0.0+1
```

Bản update:

```yaml
version: 1.0.1+2
```

Update lớn:

```yaml
version: 1.1.0+3
```

## Quy tắc

Mỗi lần upload release mới, `versionCode` phải tăng.

Ví dụ:

```text
1.0.0+1
1.0.1+2
1.0.2+3
1.1.0+4
```

---

# 5. Tạo Upload Keystore

Google Play sử dụng signing key để xác thực bản build.

Mô hình:

```text
Developer
    │
    │ Upload key
    ↓
Google Play
    │
    │ App signing
    ↓
End User
```

## Windows

Mở PowerShell:

```powershell
keytool -genkey -v `
  -keystore "$env:USERPROFILE\upload-keystore.jks" `
  -storetype JKS `
  -keyalg RSA `
  -keysize 2048 `
  -validity 10000 `
  -alias upload
```

Nếu `keytool` không được nhận diện:

```powershell
flutter doctor -v
```

Tìm đường dẫn Java/JDK mà Flutter đang sử dụng và sử dụng `keytool` từ JDK đó.

---

# 6. Lưu thông tin Keystore

Khi tạo keystore, command sẽ hỏi:

```text
Enter keystore password:
Re-enter new password:

What is your first and last name?
What is the name of your organizational unit?
What is the name of your organization?
What is the name of your City or Locality?
...
```

Cần lưu lại an toàn:

```text
Keystore file
Keystore password
Key password
Key alias
```

Ví dụ:

```text
File:
upload-keystore.jks

Alias:
upload

Store password:
********

Key password:
********
```

## Cảnh báo

Không commit các file sau lên GitHub:

```text
*.jks
*.keystore
key.properties
```

Hãy backup keystore và password ở nơi an toàn.

Nếu mất signing credentials, quá trình update app về sau có thể gặp vấn đề.

---

# 7. Tạo `key.properties`

Tạo file:

```text
android/key.properties
```

Ví dụ:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=C:\\Users\\YOUR_USERNAME\\upload-keystore.jks
```

Ví dụ Windows:

```properties
storePassword=YOUR_REAL_PASSWORD
keyPassword=YOUR_REAL_PASSWORD
keyAlias=upload
storeFile=C:\\Users\\YourUser\\upload-keystore.jks
```

> Không commit file này vào Git.

---

# 8. Cấu hình `.gitignore`

Mở:

```text
.gitignore
```

Thêm:

```gitignore
android/key.properties
*.jks
*.keystore
```

Kiểm tra Git:

```powershell
git status
```

Đảm bảo không thấy:

```text
android/key.properties
upload-keystore.jks
```

---

# 9. Cấu hình Gradle Signing

Flutter project mới có thể sử dụng:

```text
android/app/build.gradle.kts
```

Project cũ có thể sử dụng:

```text
android/app/build.gradle
```

Nếu sử dụng Kotlin DSL, cần load `key.properties` và cấu hình `signingConfigs` để release build sử dụng upload key.

Ví dụ phần đọc properties:

```kotlin
import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
```

Sau đó cấu hình release signing tương ứng với cấu trúc Gradle của project.

> **Không copy nguyên một cấu hình Gradle từ project khác nếu chưa kiểm tra project đang dùng Groovy hay Kotlin DSL.**

Checklist:

```text
[ ] key.properties tồn tại
[ ] Gradle đọc được key.properties
[ ] release dùng signing config
[ ] debug không bị ảnh hưởng
[ ] .gitignore đã bảo vệ credentials
```

---

# 10. Clean Project

Chạy:

```powershell
flutter clean
```

Sau đó:

```powershell
flutter pub get
```

Test lại:

```powershell
flutter run
```

---

# 11. Build Android App Bundle

Google Play nên sử dụng Android App Bundle (`.aab`).

Build:

```powershell
flutter build appbundle --release
```

Nếu thành công, file thường nằm tại:

```text
build/app/outputs/bundle/release/app-release.aab
```

Kiểm tra:

```powershell
dir build\app\outputs\bundle\release\
```

Kết quả mong muốn:

```text
app-release.aab
```

## Không upload APK cho release chính

```text
APK  → dùng để test / sideload
AAB  → dùng để phân phối trên Google Play
```

---

# 12. Test Release Build

Có thể build APK release để test trên thiết bị:

```powershell
flutter build apk --release
```

Sau đó cài lên Android device và kiểm tra:

```text
[ ] App mở được
[ ] Login hoạt động
[ ] API hoạt động
[ ] Upload hoạt động
[ ] Camera hoạt động
[ ] Permission hoạt động
[ ] Maps hoạt động
[ ] Notification hoạt động
[ ] Không crash
[ ] UI không lỗi
```

---

# 13. Tạo Application trên Google Play Console

Truy cập:

https://play.google.com/console/

Chọn:

```text
All apps
    ↓
Create app
```

Điền:

### App name

Ví dụ:

```text
VeggieConnect
```

### Default language

Ví dụ:

```text
Vietnamese
```

### App or Game

```text
App
```

### Free or Paid

Nếu app miễn phí:

```text
Free
```

Sau đó tạo app.

---

# 14. Hoàn thành App Setup

Google Play Console sẽ hiển thị các task cần hoàn thành.

Các phần thường cần xử lý:

```text
App access
Ads
Content rating
Target audience
Data safety
Privacy policy
Store listing
```

Checklist:

```text
[ ] App name
[ ] Short description
[ ] Full description
[ ] App icon
[ ] Screenshots
[ ] Feature graphic nếu được yêu cầu
[ ] Privacy policy
[ ] App access
[ ] Ads declaration
[ ] Target audience
[ ] Content rating
[ ] Data safety
```

---

# 15. Privacy Policy

Nếu app thu thập hoặc xử lý dữ liệu người dùng, cần chuẩn bị Privacy Policy phù hợp.

Ví dụ các dữ liệu cần xem xét:

```text
Account information
Email
Profile information
Images
Location
Device information
Analytics
Crash data
Third-party services
```

Privacy Policy phải phản ánh đúng hành vi thực tế của app.

Không nên khai báo:

```text
App không thu thập dữ liệu
```

nếu backend/app thực tế có lưu dữ liệu người dùng.

---

# 16. Data Safety

Trong Play Console, khai báo Data Safety dựa trên hành vi thực tế của app.

Cần xác định:

```text
What data is collected?
What data is shared?
Why is data collected?
Is data required or optional?
Is data encrypted in transit?
Can users request deletion?
```

Ví dụ app có:

```text
Email
Name
Profile
Images
Location
```

thì phải khai báo tương ứng theo cách app thực sự xử lý các dữ liệu đó.

---

# 17. App Access

Nếu app yêu cầu đăng nhập:

```text
Login required
```

Google reviewer cần có cách truy cập chức năng cần review.

Có thể cần cung cấp:

```text
Test account
Username/email
Password
Additional instructions
```

Không nên để reviewer gặp:

```text
Login required
↓
Không có account
↓
Không thể test app
```

---

# 18. Internal Testing

Sau khi tạo app:

```text
Test and release
    ↓
Testing
    ↓
Internal testing
```

Chọn:

```text
Create new release
```

Upload:

```text
app-release.aab
```

Sau đó:

```text
Review release
    ↓
Start rollout to Internal testing
```

---

# 19. Thêm Internal Testers

Có thể thêm team:

```text
Developer
Frontend
Backend
Tester
Mentor
```

Ví dụ:

```text
member01@gmail.com
member02@gmail.com
member03@gmail.com
```

Mục tiêu của Internal Testing:

```text
AAB
 ↓
Google Play
 ↓
Testers
 ↓
Real Android devices
```

Test:

```text
[ ] Installation
[ ] Login
[ ] API
[ ] Image upload
[ ] Camera
[ ] Permission
[ ] Maps
[ ] Notification
[ ] Crash
[ ] Performance
```

---

# 20. Closed Testing

Sau Internal Testing:

```text
Test and release
    ↓
Testing
    ↓
Closed testing
```

Tạo Closed Testing track.

Thêm tester vào danh sách.

---

# 21. Quy định 12 Testers × 14 Ngày

Nếu Developer Account là **Personal account được tạo sau ngày 13/11/2023**, Google yêu cầu đáp ứng điều kiện closed testing trước khi xin Production access.

Điều kiện:

```text
At least 12 testers
        +
Continuously opted-in
        +
At least 14 days
```

Flow:

```text
Closed Testing
       ↓
≥ 12 testers
       ↓
Testers opt-in
       ↓
14 consecutive days
       ↓
Apply for Production access
```

## Khuyến nghị

Không nên chỉ mời đúng 12 người.

Nên chuẩn bị khoảng:

```text
15–20 testers
```

để giảm rủi ro khi một tester rời khỏi test.

---

# 22. Tester phải Opt-in

Không chỉ gửi email cho tester.

Tester cần:

```text
Receive invitation
       ↓
Open opt-in link
       ↓
Join closed test
       ↓
Remain opted-in
```

Nếu tester opt-out trước khi đủ thời gian liên tục, điều kiện testing có thể không còn được đáp ứng.

---

# 23. Apply Production Access

Sau khi đáp ứng điều kiện Closed Testing:

```text
Play Console
    ↓
Apply for production access
```

Google có thể hỏi về:

```text
Closed testing
App
Testing process
Production readiness
```

Trả lời dựa trên tình trạng thực tế của app.

Không khai báo các chức năng hoặc quá trình testing không thực sự tồn tại.

---

# 24. Production Release

Sau khi được cấp Production access:

```text
Test and release
    ↓
Production
    ↓
Create new release
```

Upload:

```text
app-release.aab
```

Sau đó:

```text
Review release
    ↓
Start rollout to production
```

Google sẽ review app.

Nếu được chấp thuận:

```text
VeggieConnect
     ↓
Google Play
     ↓
Users can install
```

---

# 25. Release Checklist

## Flutter

```text
[ ] Application ID production
[ ] Version name
[ ] Version code
[ ] App icon
[ ] Splash screen
[ ] Production API
[ ] Release build
[ ] Permissions
[ ] Camera
[ ] Image upload
[ ] Maps
[ ] Notification
[ ] Deep links
```

## Security

```text
[ ] Upload keystore created
[ ] Keystore backed up
[ ] Password backed up
[ ] key.properties created
[ ] key.properties in .gitignore
[ ] *.jks in .gitignore
[ ] No secrets committed to Git
```

## Build

```text
[ ] flutter clean
[ ] flutter pub get
[ ] flutter build appbundle --release
[ ] app-release.aab exists
[ ] Release build tested
```

## Google Play

```text
[ ] App created
[ ] Store listing completed
[ ] Privacy Policy
[ ] Data Safety
[ ] Content rating
[ ] Target audience
[ ] App access
[ ] Ads declaration
[ ] Screenshots
[ ] App icon
```

## Testing

```text
[ ] Internal testing
[ ] Internal testers installed app
[ ] Closed testing
[ ] 12+ testers if applicable
[ ] 14 consecutive days if applicable
[ ] Production access approved
```

## Production

```text
[ ] Production release created
[ ] AAB uploaded
[ ] Release reviewed
[ ] Rollout started
[ ] Google review passed
[ ] App published
```

---

# 26. Quy trình Deploy chuẩn cho FYP

Đối với project FYP như VeggieConnect, có thể chia thành:

```text
PHASE 1
Flutter Development
        ↓
PHASE 2
Release Configuration
        ↓
PHASE 3
Signing
        ↓
PHASE 4
Build AAB
        ↓
PHASE 5
Google Play Internal Testing
        ↓
PHASE 6
Closed Testing
        ↓
PHASE 7
Production Access
        ↓
PHASE 8
Production Release
```

## Timeline nên chuẩn bị

Không nên đợi đến ngày demo mới bắt đầu đăng ký testing.

Đặc biệt nếu account Personal mới có yêu cầu:

```text
12 testers
+
14 consecutive days
```

hãy bắt đầu Closed Testing sớm.

---

# 27. Các lỗi thường gặp

## Lỗi 1 — `keytool is not recognized`

Kiểm tra:

```powershell
flutter doctor -v
```

Sau đó sử dụng `keytool` từ JDK mà Flutter/Android Studio đang sử dụng.

---

## Lỗi 2 — Release build không sign

Kiểm tra:

```text
android/key.properties
```

và:

```text
android/app/build.gradle.kts
```

Kiểm tra:

```text
storePassword
keyPassword
keyAlias
storeFile
```

---

## Lỗi 3 — Upload AAB bị reject vì version

Tăng:

```yaml
version: 1.0.1+2
```

Ví dụ nếu version trước là:

```yaml
version: 1.0.0+1
```

thì release mới phải có `versionCode` lớn hơn:

```yaml
version: 1.0.1+2
```

---

## Lỗi 4 — App chạy Debug nhưng Release lỗi

Luôn test:

```powershell
flutter build apk --release
```

hoặc:

```powershell
flutter build appbundle --release
```

vì Release build có thể khác Debug về:

```text
API configuration
ProGuard/R8
Permissions
Environment
Signing
Native Android configuration
```

---

## Lỗi 5 — Tester không đủ điều kiện

Kiểm tra:

```text
Tester đã opt-in chưa?
Tester có còn opt-in không?
Đủ số lượng chưa?
Đã đủ 14 ngày liên tục chưa?
```

---

# 28. Tài liệu chính thức

Flutter Android deployment:

https://docs.flutter.dev/deployment/android

Google Play Console:

https://play.google.com/console/

Google Play testing:

https://support.google.com/googleplay/android-developer/

Production access requirements:

https://support.google.com/googleplay/android-developer/answer/14151465

---

# 29. Recommended Workflow cho Team

Nếu team có nhiều developer:

```text
Developer
    ↓
Git branch
    ↓
PR
    ↓
dev
    ↓
QA
    ↓
release branch
    ↓
Build AAB
    ↓
Internal Testing
    ↓
Closed Testing
    ↓
Production
```

Signing credentials nên chỉ được quản lý bởi người chịu trách nhiệm release.

Không gửi:

```text
upload-keystore.jks
key.properties
password
```

qua GitHub hoặc chat nhóm công khai.

---

# 30. Final Deployment Flow

```text
                    FLUTTER APP
                         │
                         ▼
               Application ID
                         │
                         ▼
                    Versioning
                         │
                         ▼
                  Upload Keystore
                         │
                         ▼
                 Gradle Signing
                         │
                         ▼
              flutter build appbundle
                         │
                         ▼
                  app-release.aab
                         │
                         ▼
                GOOGLE PLAY CONSOLE
                         │
              ┌──────────┴──────────┐
              ▼                     ▼
       Store Listing          App Configuration
              │                     │
              └──────────┬──────────┘
                         ▼
                 Internal Testing
                         │
                         ▼
                  Closed Testing
                         │
                         ▼
              12+ Testers / 14 Days
                (if applicable)
                         │
                         ▼
              Production Access
                         │
                         ▼
                Production Release
                         │
                         ▼
                  Google Review
                         │
                         ▼
                    LIVE ON
                  GOOGLE PLAY
```

---

## Important

Các yêu cầu của Google Play có thể thay đổi theo thời điểm, loại tài khoản và trạng thái developer account. Trước khi release chính thức, luôn kiểm tra lại yêu cầu đang hiển thị trực tiếp trong Play Console.

**Mục tiêu triển khai:** ưu tiên hoàn thành Internal Testing trước, sau đó mới bắt đầu Closed Testing và Production.

---

# Phụ lục: Giá trị riêng của Smart Wardrobe (spec 008)

- Package / applicationId: `com.smartwardrobe.smart_wardrobe` (đã chốt)
- Version đầu: `1.0.0+1` (`pubspec.yaml`); mỗi lần upload tăng `versionCode`
- Keystore: `$env:USERPROFILE\upload-keystore.jks`, alias `upload`
- `android/key.properties`: `storePassword`, `keyPassword`, `keyAlias=upload`, `storeFile` (tuyệt đối)
- JDK/keytool: `C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe`
- Lệnh build release:
  ```powershell
  flutter build appbundle --release `
    --dart-define=API_BASE_URL=https://<prod>/api/v1 `
    --dart-define=CLOUDINARY_CLOUD_NAME=<name> `
    --dart-define=ENABLE_PAID_FEATURES=false
  ```
- Cờ trả phí: `ENABLE_PAID_FEATURES` (mặc định `false` → ẩn Ví/Gói hội viên);
  dev muốn test thanh toán thì build với `--dart-define=ENABLE_PAID_FEATURES=true`
- Tài khoản Play: Personal mới → Closed Testing 12 tester × 14 ngày
- Checklist vận hành chi tiết: xem `docs/Release_Play_Checklist.md`
