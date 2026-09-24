# Contract: Release Configuration

**Feature**: specs/008-google-play-deploy-setup
**Date**: 2026-09-19
**Type**: Build/release configuration contract (Android Flutter)
**Consumers**: `/speckit-tasks`, người chịu trách nhiệm release, CI (nếu thêm sau)

Mọi bản phát hành Play phải thỏa các hợp đồng dưới đây. Vi phạm = build không hợp lệ để publish.

## C1 — `android/key.properties` (không commit)

```properties
storePassword=<...>
keyPassword=<...>
keyAlias=upload
storeFile=C:\\Users\\<user>\\upload-keystore.jks
```

- File tồn tại cục bộ trên máy build; KHÔNG có trong git.
- `storeFile` là đường dẫn tuyệt đối tới keystore ngoài repo.

## C2 — Gradle signing (`android/app/build.gradle.kts`)

- Đọc `rootProject.file("key.properties")` bằng `java.util.Properties` khi file tồn tại.
- `signingConfigs { create("release") { ... } }` với 4 giá trị từ C1.
- `buildTypes.release.signingConfig = signingConfigs.getByName("release")`.
- `buildTypes.debug` giữ nguyên (không đổi hành vi debug).
- Build phải thành công khi `key.properties` tồn tại; release KHÔNG được fallback về debug signing.

## C3 — Build-time config (`--dart-define`)

| Key | Release | Debug/local |
|---|---|---|
| `API_BASE_URL` | HTTPS thật, bắt buộc | có thể HTTP/localhost |
| `CLOUDINARY_CLOUD_NAME` | giá trị thật | `demo` chấp nhận |
| `ENABLE_PAID_FEATURES` | `false` | `true` (để dev test) |

Quy tắc fail-fast (`app_constants.dart`):
- Nếu `kReleaseMode` và (`API_BASE_URL` rỗng HOẶC chứa `[IP_ADDRESS]`) → ném lỗi rõ ràng, không fallback im lặng.
- Bản release không bao giờ dùng `http://[IP_ADDRESS]/api/v1`.

## C4 — Manifest contract

- `src/main/AndroidManifest.xml`: KHÔNG có `android:usesCleartextTraffic="true"`.
- `src/debug/AndroidManifest.xml`: cho phép cleartext (chỉ debug/local).
- Deep-link scheme `smartwardrobe://` (subscription/wallet) giữ nguyên trong manifest, nhưng xử lý bị vô hiệu khi `ENABLE_PAID_FEATURES=false`.

## C5 — Repository hygiene (`.gitignore`)

Bắt buộc chứa:
```gitignore
android/key.properties
*.jks
*.keystore
```
`git status`/`git check-ignore` xác nhận keystore + key.properties không được track.

## C6 — Version contract

- `pubspec.yaml`: `version: <versionName>+<versionCode>`.
- Bản đầu: `1.0.0+1`. Mỗi upload mới: `versionCode` lớn hơn mọi bản đã upload.

## C7 — Build command contract

```powershell
flutter clean
flutter pub get
flutter build appbundle --release `
  --dart-define=API_BASE_URL=https://<prod>/api/v1 `
  --dart-define=CLOUDINARY_CLOUD_NAME=<name> `
  --dart-define=ENABLE_PAID_FEATURES=false
```

Kết quả bắt buộc: `build/app/outputs/bundle/release/app-release.aab` tồn tại, được ký upload key.

## C8 — Paid-feature gate contract

- Cờ `ENABLE_PAID_FEATURES` là compile-time (`bool.fromEnvironment`), mặc định `false`.
- Khi `false`: không có điểm vào UI nào dẫn tới `/profile/wallet`, `/profile/subscription*`; deep-link PayOS bị bỏ qua; không gọi API tạo link thanh toán.
- Khi `true` (dev): hành vi cũ giữ nguyên.
