# Quickstart — Validate 008-google-play-deploy-setup

**Prereqs**: Flutter SDK + JDK (`flutter doctor -v` xanh), quyền truy cập Google Play Console (tài khoản Personal mới), backend production HTTPS, ít nhất 1 máy Android thật, tài khoản test trong app.

Đối chiếu các contract: `contracts/release-config.md`, `contracts/play-listing.md`.

## QS-001 — Build release ký đúng & chạy thật (US1, SC-001/002/009)

1. Tạo upload keystore; tạo `android/key.properties`; cấu hình Gradle signing Kotlin DSL.
2. Build theo C7 (`--dart-define=API_BASE_URL=https://...`, `ENABLE_PAID_FEATURES=false`).
3. ✅ `build/app/outputs/bundle/release/app-release.aab` tồn tại; `app-release.apk` cài được.
4. Trên 3 máy thật: app mở không crash; đăng nhập, tải ảnh, camera chạy đúng; kết nối API HTTPS; hạn mức miễn phí đủ cho các luồng chính.
5. ✅ 0 lần dùng `http://[IP_ADDRESS]`; không có cleartext trong release; 0 điểm vào Ví/Gói hội viên.
6. `flutter analyze` sạch; `flutter test` như baseline.

## QS-002 — Internal Testing cài từ Play (US1, SC-005)

1. Tạo app trên Play Console (đúng package, Free, Vietnamese).
2. Upload AAB lên Internal Testing; mời tester nội bộ.
3. ✅ Tester opt-in và cài app từ Play trong vòng 1 ngày; chạy lại checklist chức năng trên bản cài từ Play.

## QS-003 — Store listing & khai báo đầy đủ (US2, SC-004)

1. Hoàn tất P2–P4 trong `contracts/play-listing.md`.
2. ✅ 100% trường bắt buộc hợp lệ; Data Safety khớp hành vi thật; app access có tài khoản test; privacy policy URL mở được.
3. Gửi duyệt → ✅ không bị từ chối vì thiếu/sai khai báo.

## QS-004 — Closed Testing 12 × 14 (US3, SC-006)

1. Mở Closed Testing; mời 15–20 tester; đảm bảo họ opt-in.
2. Theo dõi hằng ngày (data-model `TestTrack`).
3. ✅ ≥ 12 tester opt-in liên tục ≥ 14 ngày, không gián đoạn.

## QS-005 — Production access & release (US3, SC-007)

1. Apply Production access với mô tả trung thực.
2. Được duyệt → tạo production release với AAB mới (versionCode tăng), rollout.
3. ✅ Google duyệt; người dùng thật tìm thấy và cài được app từ Play.

## QS-006 — Hồi quy bảo mật & version (SC-003/008)

1. `git check-ignore android/key.properties` và tìm `*.jks`/`*.keystore` → ✅ không file nào bị track; lịch sử git không có secret.
2. Mỗi lần upload sau: ✅ `versionCode` tăng, không tái sử dụng số cũ.
3. ✅ Checklist release 5 nhóm (Security/Build/Store/Testing/Production) được ký duyệt trước khi rollout.
