# Research: Google Play Deploy Setup

**Feature**: specs/008-google-play-deploy-setup
**Date**: 2026-09-19
**Scope**: Android/Google Play release configuration; no backend change.

## R1 — Application ID

**Decision**: Giữ `com.smartwardrobe.smart_wardrobe` (namespace + applicationId hiện tại), chốt vĩnh viễn trước lần publish đầu.
**Rationale**: Không phải `com.example`, hợp lệ làm ID production, tránh đổi namespace/MainActivity và rủi ro không đáng có. Sau khi publish không thể đổi ID.
**Alternatives**: Đổi thành `com.smartwardrobe.app` — bị loại vì lợi ích thẩm mỹ không bù rủi ro đổi package (đường dẫn Kotlin, plugin, deep-link).
**Verify**: Tạo app trên Play Console bằng đúng package này (Google sẽ khóa).

## R2 — Upload keystore & Gradle signing (Kotlin DSL)

**Decision**: Tạo upload key bằng `keytool` (JDK mà Flutter dùng, xem `flutter doctor -v`), lưu `$env:USERPROFILE\upload-keystore.jks`, alias `upload`, validity 10000. `android/key.properties` giữ `storePassword/keyPassword/keyAlias/storeFile`. `android/app/build.gradle.kts` đọc properties, thêm `signingConfigs.release`, `buildTypes.release.signingConfig = signingConfigs.release`; bật Play App Signing (Google giữ app signing key, ta giữ upload key).
**Rationale**: Project dùng Kotlin DSL; phải đọc `key.properties` và cấu hình đúng cú pháp Kotlin. Bật Play App Signing để Google quản lý app signing key, ta chỉ cần upload key.
**Alternatives**: Ký bằng debug key (hiện tại) — Play từ chối; Android Studio Generate Signed Bundle wizard — tương đương, nhưng cấu hình phải nằm trong repo để tái lập được.

## R3 — Credentials hygiene

**Decision**: Thêm `android/key.properties`, `*.jks`, `*.keystore` vào `.gitignore`; keystore để ngoài repo; backup mật khẩu ở nơi an toàn. Xác minh `git status` không lộ file.
**Rationale**: FR-005/SC-003; `.gitignore` hiện chưa chặn các file này.
**Alternatives**: Commit encrypted secrets — bị loại (thừa phức tạp cho FYP).

## R4 — API production & cleartext

**Decision**: Bản release truyền `--dart-define=API_BASE_URL=https://<prod>/api/v1` (và `CLOUDINARY_CLOUD_NAME` nếu cần). Trong `app_constants.dart`, khi release mà URL rỗng hoặc chứa `[IP_ADDRESS]` thì fail-fast (assert/throw rõ ràng). Bỏ `android:usesCleartextTraffic="true"` khỏi manifest chính; chỉ cho cleartext ở `src/debug/AndroidManifest.xml` (dev/local).
**Rationale**: FR-023/024/025; hiện fallback `http://[IP_ADDRESS]` + cleartext sẽ khiến app production không kết nối được và Data Safety khai sai.
**Alternatives**: `network_security_config` chặn theo domain — tương đương; chọn debug-manifest để đơn giản. Giữ `.env` cho dev nhưng release ưu tiên dart-define.
**Note**: `.env` là asset bắt buộc trong `pubspec.yaml` — build vẫn cần file này tồn tại; dùng `.env.example` copy khi CI/máy mới.

## R5 — Ẩn luồng trả phí kỹ thuật số (Play Billing policy)

**Decision**: Thêm cờ compile-time `ENABLE_PAID_FEATURES` (mặc định false ở release). Khi tắt: ẩn mục Gói hội viên/Ví trong `profile_screen.dart` và `closy_wallet_card.dart`; chặn các route `/profile/wallet`, `/profile/subscription`, `/profile/subscription/upgrade`, `/profile/subscription/waiting`; vô hiệu xử lý deep-link PayOS. App chạy bằng hạn mức miễn phí từ backend.
**Rationale**: FR-021/022; Google Play yêu cầu Google Play Billing cho hàng hóa kỹ thuật số, PayOS bên ngoài sẽ bị từ chối/gỡ. Bật lại sau chỉ cần đổi cờ + tích hợp Play Billing.
**Alternatives**: Xóa code thanh toán — bị loại (khó bật lại); giữ PayOS — rủi ro policy.
**Open dependency**: backend phải trả hạn mức miễn phí hợp lý khi không có subscription (giả định; xác minh ở QS-001).

## R6 — Versioning

**Decision**: Bản đầu `1.0.0+1` (giữ nguyên). Mỗi lần upload tăng `versionCode` (`+N`); `versionName` theo semver. Ghi quy tắc vào tài liệu release.
**Rationale**: FR-002/SC-008; Play từ chối versionCode trùng.

## R7 — Store listing assets & icon

**Decision**: Cần icon 512×512, feature graphic 1024×500, tối thiểu 2 (khuyến nghị 4–8) ảnh chụp điện thoại, mô tả ngắn ≤ 80 ký tự, mô tả đầy đủ. Thay icon Flutter mặc định bằng icon thương hiệu (có thể dùng `flutter_launcher_icons` dev-only, hoặc thay PNG thủ công); kiểm tra splash (`launch_background.xml`).
**Rationale**: FR-009; icon hiện là mặc định Flutter, không đạt chất lượng cửa hàng.
**Alternatives**: Bỏ qua icon tùy biến — bị loại (không chuyên nghiệp, ảnh hưởng duyệt/chuyển đổi).

## R8 — Privacy policy

**Decision**: Soạn `docs/privacy-policy.md` phản ánh đúng hành vi (tài khoản/email/tên/ảnh tủ đồ, backend + Cloudinary), host tại URL công khai do đội quản lý (ví dụ GitHub Pages hoặc web hiện có), dùng URL đó trong Store listing và Play Console.
**Rationale**: FR-010; bắt buộc để publish và để Data Safety nhất quán.

## R9 — Data Safety mapping (hành vi thật)

**Decision**: Khai báo dựa trên code thực tế:
- Thu thập: email, tên, thông tin hồ sơ, ảnh (ảnh trang phục tải lên), nội dung người dùng.
- Chia sẻ: ảnh lưu trữ qua Cloudinary (bên thứ ba xử lý hạ tầng lưu ảnh); backend của đội.
- Mã hóa khi truyền: Có (sau R4).
- Không có SDK analytics/crash bên thứ ba trong `pubspec.yaml` → không khai analytics/crash.
- Không có quyền vị trí trong manifest → **không** khai vị trí.
- Có thể yêu cầu xóa: theo chính sách/backend.
**Rationale**: FR-011; khai sai là nguyên nhân từ chối phổ biến.
**Verify**: Đối chiếu lại với backend thực tế trước khi nộp.

## R10 — Test tracks & điều kiện 12×14

**Decision**: Tài khoản Personal tạo sau 13/11/2023 → bắt buộc Closed Testing ≥ 12 tester opt-in liên tục 14 ngày. Mời 15–20 tester, bắt đầu sớm; theo dõi opt-in hằng ngày.
**Rationale**: FR-016/SC-006; rủi ro tester rớt làm reset thời gian.
**Alternatives**: Chờ tới sát demo — bị loại.

## R11 — App access cho reviewer

**Decision**: Cung cấp tài khoản test (email/mật khẩu) + hướng dẫn trong mục App access; đảm bảo reviewer vào được các chức năng cốt lõi ở chế độ miễn phí.
**Rationale**: FR-013; app yêu cầu đăng nhập, thiếu tài khoản test sẽ bị từ chối.

## R12 — Production access & rollout

**Decision**: Apply Production access với mô tả trung thực quá trình Closed Testing; sau khi được duyệt, tạo production release cùng AAB, rollout theo dõi Google review; chuẩn bị phương án xử lý nếu bị từ chối (sửa khai báo/policy, tăng versionCode, gửi lại).
**Rationale**: FR-017/018/020/SC-007.

## R13 — Release checklist & lỗi thường gặp

**Decision**: Duy trì checklist 5 nhóm (Security/Build/Store/Testing/Production) trong tài liệu release; xử lý lỗi: keytool không nhận, release không sign, versionCode trùng, debug chạy/release lỗi, tester không đủ điều kiện.
**Rationale**: FR-019/020; theo guide `docs/Flutter_to_Google_Play_Deployment_Guide.md`.
