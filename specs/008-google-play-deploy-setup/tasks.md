---
description: "Task list for Google Play Deploy Setup"
---

# Tasks: Google Play Deploy Setup

**Input**: Design documents from `/specs/008-google-play-deploy-setup/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/release-config.md, contracts/play-listing.md, quickstart.md

**Tests**: Không có yêu cầu TDD trong spec. Không sinh task test tự động; dùng validation thủ công theo `quickstart.md` + `flutter analyze`/`flutter test` baseline.

**Organization**: Task nhóm theo user story để có thể triển khai và kiểm thử độc lập.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Có thể chạy song song (file khác nhau, không phụ thuộc task chưa xong)
- **[Story]**: US1 / US2 / US3
- Đường dẫn file chính xác trong mô tả

## Path Conventions

Single Flutter project: `lib/`, `android/`, `docs/`, `specs/008-google-play-deploy-setup/`.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Chuẩn bị công cụ & tài liệu vận hành

- [X] T001 [P] Xác minh toolchain Flutter/JDK và đường dẫn `keytool` (`flutter doctor -v`), ghi lại JDK path + phiên bản Flutter vào `docs/Release_Play_Checklist.md` (chuẩn bị cho FR-003, R2)
- [X] T002 [P] Tạo `docs/Release_Play_Checklist.md` với 5 nhóm checklist: Security, Build, Store, Testing, Production (FR-019, R13)
- [X] T003 [P] Tạo nháp `docs/privacy-policy.md` phản ánh đúng hành vi dữ liệu: email, tên, hồ sơ, ảnh trang phục; backend + Cloudinary; mã hóa khi truyền; không location/analytics (FR-010, R8/R9)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Cấu hình nền tảng dùng chung cho mọi story

**⚠️ CRITICAL**: Hoàn tất trước khi bắt đầu user story

- [X] T004 [P] Thêm `android/key.properties`, `*.jks`, `*.keystore` vào `.gitignore` (FR-005, contract C5)
- [X] T005 [P] Tạo `lib/core/config/release_flags.dart` với `enablePaidFeatures = bool.fromEnvironment('ENABLE_PAID_FEATURES', defaultValue: false)` (FR-021, contract C8)
- [X] T006 Chốt app identity/version: xác nhận `applicationId = "com.smartwardrobe.smart_wardrobe"` trong `android/app/build.gradle.kts` và `version: 1.0.0+1` trong `pubspec.yaml`; ghi chú bất biến (FR-001/002, R1/R6)

**Checkpoint**: Nền tảng sẵn sàng — bắt đầu user story

---

## Phase 3: User Story 1 - Phát hành bản cài đặt được ký lên Internal Testing (Priority: P1) 🎯 MVP

**Goal**: Build AAB ký bằng upload key, API HTTPS, tắt cleartext, ẩn trả phí, cài được từ Internal Testing.

**Independent Test**: Cài `app-release.apk` trên 3 máy thật, chạy checklist chức năng; upload AAB lên Internal Testing và để tester cài từ Play.

### Implementation for User Story 1

- [ ] T007 [US1] Tạo upload keystore ngoài repo bằng `keytool` (`-keystore "$env:USERPROFILE\upload-keystore.jks" -alias upload -validity 10000`); backup tệp keystore và mật khẩu ở nơi an toàn (FR-003, R2)
- [ ] T008 [US1] Tạo `android/key.properties` (không commit) với `storePassword`, `keyPassword`, `keyAlias=upload`, `storeFile` tuyệt đối (FR-003, contract C1)
- [X] T009 [US1] Cấu hình release signing trong `android/app/build.gradle.kts`: đọc `key.properties`, `signingConfigs.release`, `buildTypes.release.signingConfig = signingConfigs.getByName("release")`, giữ debug nguyên (FR-004, contract C2)
- [X] T010 [P] [US1] Sửa `lib/core/constants/app_constants.dart`: ưu tiên `--dart-define API_BASE_URL`; fail-fast khi `kReleaseMode` và URL rỗng/chứa `[IP_ADDRESS]`; bỏ fallback `http://[IP_ADDRESS]/api/v1` cho release (FR-023, contract C3)
- [X] T011 [P] [US1] Bỏ `android:usesCleartextTraffic="true"` khỏi `android/app/src/main/AndroidManifest.xml`; thêm `android/app/src/debug/AndroidManifest.xml` cho phép cleartext chỉ ở debug (FR-024, contract C4)
- [X] T012 [US1] Gate trả phí khi `enablePaidFeatures == false`: ẩn mục Ví/Gói hội viên trong `lib/features/profile/presentation/profile_screen.dart` và `lib/features/profile/presentation/widgets/closy_wallet_card.dart`; chặn route `/profile/wallet`, `/profile/subscription`, `/profile/subscription/upgrade`, `/profile/subscription/waiting` trong `lib/core/router/app_router.dart`; bỏ qua deep-link PayOS trong `lib/core/deeplink/payment_deeplink_handler.dart` (FR-021, contract C8)
- [ ] T013 [US1] Build AAB theo contract C7 (`flutter clean`, `flutter pub get`, `flutter build appbundle --release` + `--dart-define` cho `API_BASE_URL`, `CLOUDINARY_CLOUD_NAME`, `ENABLE_PAID_FEATURES=false`); xác nhận `build/app/outputs/bundle/release/app-release.aab` tồn tại (FR-006)
- [ ] T014 [US1] Build `app-release.apk`, cài trên 3 máy Android thật và chạy smoke test: mở app, đăng nhập/đăng ký, API HTTPS, tải ảnh, camera, quyền runtime; xác nhận hạn mức miễn phí đủ cho các luồng chính, 0 điểm vào trả phí/deep-link thanh toán và 0 tham chiếu `[IP_ADDRESS]` (FR-007, SC-001/002/009)
- [ ] T015 [US1] Tạo app trên Google Play Console: `Smart Wardrobe`, default language Vietnamese, type App, pricing Free, package `com.smartwardrobe.smart_wardrobe` (FR-008, contract P1)
- [ ] T016 [US1] Upload `app-release.aab` lên kênh Internal Testing; thêm danh sách internal testers (FR-014)
- [ ] T017 [US1] Tester nội bộ opt-in, cài từ Play và xác nhận các luồng chính chạy đúng (FR-015, SC-005)
- [X] T018 [US1] Chạy `flutter analyze` (sạch) và `flutter test` (baseline) sau thay đổi release (FR-007)

**Checkpoint**: US1 hoàn chỉnh và kiểm thử độc lập (MVP)

---

## Phase 4: User Story 2 - Hoàn tất hồ sơ cửa hàng và khai báo bắt buộc (Priority: P2)

**Goal**: Hồ sơ cửa hàng + privacy + Data Safety + các khai báo đầy đủ, khớp hành vi thật.

**Independent Test**: Rà từng mục P2–P4 trong `contracts/play-listing.md`; gửi duyệt không bị từ chối vì thiếu/sai khai báo.

### Implementation for User Story 2

- [ ] T019 [P] [US2] Chuẩn bị ảnh cửa hàng: icon 512×512, feature graphic 1024×500, 4–8 ảnh chụp điện thoại (FR-009, contract P2)
- [ ] T020 [P] [US2] Thay icon Flutter mặc định bằng icon thương hiệu tại `android/app/src/main/res/mipmap-*/ic_launcher.png`; kiểm tra splash `android/app/src/main/res/drawable/launch_background.xml` (FR-009, R7)
- [ ] T021 [US2] Viết tiêu đề ≤ 30 ký tự, mô tả ngắn ≤ 80 ký tự, mô tả đầy đủ (không hứa tính năng trả phí đã ẩn); nhập vào Store listing (FR-009, contract P2)
- [ ] T022 [US2] Publish `docs/privacy-policy.md` tại URL công khai và gắn liên kết vào Store listing + Play Console (FR-010)
- [ ] T023 [US2] Hoàn tất Data Safety: email, tên, hồ sơ, ảnh; chia sẻ với backend + Cloudinary; mã hóa khi truyền = Có; KHÔNG khai location/analytics; có thể yêu cầu xóa (FR-011, contract P3)
- [ ] T024 [US2] Hoàn tất Content rating questionnaire, Target audience, Ads declaration (No ads nếu thực tế không có) (FR-012, contract P4)
- [ ] T025 [US2] Cấu hình App access: `Login required` + tài khoản test (email/mật khẩu) + hướng dẫn đường vào chức năng (FR-013, contract P4)
- [ ] T026 [US2] Gửi bản phát hành đi duyệt; xác nhận không bị từ chối vì thiếu/sai khai báo (SC-004)

**Checkpoint**: US1 và US2 cùng hoạt động độc lập

---

## Phase 5: User Story 3 - Từ Closed Testing tới Production Release (Priority: P3)

**Goal**: Đủ điều kiện 12 tester × 14 ngày, được cấp Production access, phát hành công khai.

**Independent Test**: Mời đủ tester opt-in, theo dõi 14 ngày, xin Production access, rollout production, xác nhận app hiển thị công khai.

### Implementation for User Story 3

- [ ] T027 [US3] Tạo kênh Closed Testing và mời 15–20 tester (FR-016, R10)
- [ ] T028 [US3] Theo dõi opt-in hằng ngày; duy trì ≥ 12 tester opt-in liên tục 14 ngày không gián đoạn (FR-016, SC-006)
- [ ] T029 [US3] Gửi yêu cầu Production access với mô tả trung thực quá trình Closed Testing và độ sẵn sàng (FR-017, R12)
- [ ] T030 [US3] Sau khi được duyệt, tạo Production release với `versionCode` tăng và bắt đầu rollout (FR-018, R12)
- [ ] T031 [US3] Theo dõi Google review và xác nhận app được publish công khai trên Google Play (SC-007)

**Checkpoint**: Cả 3 user story hoàn chỉnh

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Hoàn thiện vận hành, bảo mật, tài liệu

- [X] T032 [P] Hoàn thiện `docs/Release_Play_Checklist.md` và ghi quy tắc tăng `versionCode` mỗi lần upload (FR-002/019, SC-008)
- [X] T033 [P] Cập nhật `docs/Flutter_to_Google_Play_Deployment_Guide.md` với giá trị riêng của dự án: package, đường dẫn keystore, các `--dart-define` (FR-019)
- [X] T034 Xác minh không có secret trong git: `git check-ignore android/key.properties`, tìm `*.jks`/`*.keystore`, rà lịch sử (FR-005, SC-003)
- [ ] T035 Chạy đầy đủ QS-001→QS-006 trong `specs/008-google-play-deploy-setup/quickstart.md` và đối chiếu contract
- [X] T036 [P] Ghi cách xử lý lỗi release vào checklist: `keytool` không nhận diện, release không sign, `versionCode` bị từ chối, debug chạy/release lỗi, tester không đủ điều kiện (FR-020, R13)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: không phụ thuộc — bắt đầu ngay
- **Foundational (Phase 2)**: phụ thuộc Setup — CHẶN mọi user story
- **User Stories (Phase 3+)**: đều phụ thuộc Foundational
  - US1 → US2 → US3 theo ưu tiên (US2 có thể chạy song song sau khi app tạo ở US1)
  - US3 phụ thuộc US1 (có AAB) và US2 (hồ sơ/khai báo)
- **Polish (Phase 6)**: phụ thuộc các story mong muốn hoàn tất

### User Story Dependencies

- **US1 (P1)**: sau Foundational — không phụ thuộc story khác
- **US2 (P2)**: sau Foundational; thực tế cần app đã tạo ở US1 (T015) nhưng nội dung listing độc lập
- **US3 (P3)**: cần US1 (AAB + Internal Testing) và US2 (khai báo) trước khi xin Production

### Within Each User Story

- Config/signing trước build
- Build trước khi upload
- Upload trước khi tester xác nhận

### Parallel Opportunities

- T001–T003 song song (Setup)
- T004–T005 song song; T006 độc lập file
- Trong US1: T010, T011 song song; T012 độc lập
- Trong US2: T019, T020 song song; T023–T025 có thể song song theo mục Play Console
- Trong Polish: T032, T033, T036 song song

---

## Parallel Example: User Story 1

```bash
# Song song sau khi T009 xong:
Task: "T010 API_BASE_URL fail-fast trong lib/core/constants/app_constants.dart"
Task: "T011 Bỏ cleartext + thêm debug manifest trong android/app/src/main/AndroidManifest.xml"
```

## Parallel Example: User Story 2

```bash
Task: "T019 Chuẩn bị ảnh cửa hàng (icon/feature/screenshots)"
Task: "T020 Thay launcher icon trong android/app/src/main/res/mipmap-*"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Hoàn tất Phase 1 Setup
2. Hoàn tất Phase 2 Foundational (CHẶN mọi story)
3. Hoàn tất Phase 3 US1
4. **DỪNG và VALIDATE**: build AAB, cài thật, Internal Testing
5. Có thể demo bản cài từ Play

### Incremental Delivery

1. Setup + Foundational → nền tảng sẵn sàng
2. US1 → validate → Internal Testing (MVP!)
3. US2 → validate → hồ sơ/khai báo sẵn sàng
4. US3 → Closed Testing → Production access → Production release
5. Mỗi bước thêm giá trị, không phá bước trước

### Parallel Team Strategy

- Sau Foundational:
  - Dev A: US1 (config + build)
  - Dev B: US2 (assets + listing + privacy)
  - Dev C (sau US1): US3 (testers + tracking)
- Lưu ý: US3 chỉ bắt đầu khi US1 đã có AAB trên Internal Testing.

---

## Notes

- [P] = file khác nhau, không phụ thuộc
- `versionCode` phải tăng mỗi lần upload (T032)
- Không commit keystore/`key.properties` (T004, T034)
- Bản Play đầu tiên không thu tiền kỹ thuật số (T012)
- Dừng ở mỗi checkpoint để validate độc lập
