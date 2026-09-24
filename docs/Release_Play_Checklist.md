# Release Checklist — Smart Wardrobe (Google Play)

Tài liệu vận hành phát hành Android lên Google Play (spec 008).
Đánh dấu từng mục trước mỗi lần rollout.

## 0. Môi trường (ghi nhận một lần)

- Flutter: 3.47.2 (stable, `C:\src\flutter`)
- JDK/keytool: `C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe`
  (JDK đi kèm Android Studio mà Flutter đang dùng — xem `flutter doctor -v`)
- Package: `com.smartwardrobe.smart_wardrobe` (đã chốt, không đổi sau publish)
- Keystore: `$env:USERPROFILE\upload-keystore.jks`, alias `upload`
- Play Console: tài khoản Personal mới → bắt buộc Closed Testing 12 tester × 14 ngày

## 1. Security

- [ ] Upload keystore đã tạo (`keytool -genkey ... -alias upload -validity 10000`)
- [ ] Keystore + store password + key password đã backup ở nơi an toàn
- [ ] `android/key.properties` tồn tại cục bộ (không commit) với đủ 4 khóa:
  `storePassword`, `keyPassword`, `keyAlias=upload`, `storeFile` (đường dẫn tuyệt đối)
- [ ] `.gitignore` chặn `android/key.properties`, `*.jks`, `*.keystore`
- [ ] `git status` / lịch sử git không lộ secret

## 2. Build

- [ ] `pubspec.yaml`: `version: <versionName>+<versionCode>`, `versionCode` lớn hơn mọi bản đã upload
- [ ] `flutter clean` → `flutter pub get`
- [ ] Build đúng lệnh (contract C7):
  ```powershell
  flutter build appbundle --release `
    --no-tree-shake-icons `
    --dart-define=API_BASE_URL=https://<prod>/api/v1 `
    --dart-define=CLOUDINARY_CLOUD_NAME=<name> `
    --dart-define=ENABLE_PAID_FEATURES=false
  ```
  *(Thêm `--no-tree-shake-icons` để tránh lỗi Windows Application Control chặn `font-subset.exe`)*
- [ ] `build/app/outputs/bundle/release/app-release.aab` tồn tại, ký bằng upload key
- [ ] Release APK (`flutter build apk --release`) cài và smoke test trên máy thật:
  đăng nhập, API HTTPS, tải ảnh, camera, quyền runtime;
  hạn mức miễn phí đủ dùng; 0 điểm vào trả phí/deep-link thanh toán;
  0 tham chiếu `http://[IP_ADDRESS]`

## 3. Store (Play Console)

- [ ] App đã tạo đúng package, Free, Vietnamese
- [ ] Store listing: title ≤ 30, short desc ≤ 80, full desc, icon 512×512,
  feature graphic 1024×500, ≥ 2 screenshots
- [ ] Privacy Policy URL công khai, truy cập được
- [ ] Data Safety khớp hành vi thật (email, tên, hồ sơ, ảnh; mã hóa khi truyền;
  không location/analytics; có thể yêu cầu xóa)
- [ ] Content rating, Target audience, Ads declaration hoàn tất
- [ ] App access: `Login required` + tài khoản test + hướng dẫn

## 4. Testing

- [ ] AAB lên Internal Testing; tester nội bộ cài từ Play trong 1 ngày
- [ ] Closed Testing: mời 15–20 tester, đảm bảo opt-in
- [ ] Duy trì ≥ 12 tester opt-in liên tục 14 ngày (theo dõi hằng ngày)
- [ ] Apply Production access (trả lời trung thực), được duyệt

## 5. Production

- [ ] Tạo production release với `versionCode` mới, bắt đầu rollout
- [ ] Theo dõi Google review; xử lý từ chối (sửa khai báo/policy, tăng version, gửi lại)
- [ ] Xác nhận app hiển thị công khai, người dùng cài được

## Xử lý lỗi thường gặp

- `keytool` không nhận diện → dùng keytool trong JDK ở mục 0.
- Release không sign → kiểm tra `android/key.properties` và signing config
  trong `android/app/build.gradle.kts`.
- Upload AAB bị từ chối vì version → tăng `versionCode` (`+N`).
- Debug chạy, release lỗi → test đúng bản release (API, R8, quyền, ký, native).
- Tester không đủ điều kiện → kiểm tra opt-in, số lượng, 14 ngày liên tục.
