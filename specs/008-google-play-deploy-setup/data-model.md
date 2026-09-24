# Data Model: Google Play Deploy Setup

**Feature**: specs/008-google-play-deploy-setup
**Date**: 2026-09-19
**Note**: Không phải data model runtime của app; đây là mô hình các thực thể cấu hình/artefact release dùng cho kế hoạch và kiểm thử.

## ReleaseConfig

Cấu hình build phát hành (nguồn: `pubspec.yaml`, `android/app/build.gradle.kts`, `--dart-define`).

| Field | Kiểu | Nguồn | Ràng buộc |
|---|---|---|---|
| applicationId | string | build.gradle.kts | Chốt vĩnh viễn; không `com.example` (FR-001) |
| namespace | string | build.gradle.kts | Khớp package Kotlin |
| versionName | string | pubspec `version` | semver, ví dụ `1.0.0` |
| versionCode | int | pubspec `version` sau `+` | Tăng đơn điệu mỗi upload (FR-002) |
| apiBaseUrl | string | `--dart-define API_BASE_URL` | Bắt buộc HTTPS ở release, không `[IP_ADDRESS]` (FR-023) |
| cloudinaryCloudName | string | `--dart-define` / `.env` | Có giá trị thật ở release |
| enablePaidFeatures | bool | `--dart-define` | `false` ở bản Play đầu tiên (FR-021) |
| cleartextAllowed | bool | AndroidManifest (main/debug) | `false` ở release, `true` chỉ debug (FR-024) |

**Validation**: release build fail-fast nếu `apiBaseUrl` rỗng/chứa `[IP_ADDRESS]` hoặc nếu release còn bật cleartext.

## SigningCredential

| Field | Kiểu | Nguồn | Ràng buộc |
|---|---|---|---|
| storeFile | path | `android/key.properties` | Ngoài repo, tồn tại trên máy build (FR-003) |
| storePassword | secret | `android/key.properties` | Không commit (FR-005) |
| keyPassword | secret | `android/key.properties` | Không commit |
| keyAlias | string | `android/key.properties` | ví dụ `upload` |
| keystoreBackup | ngoài hệ thống | password manager / nơi an toàn | Có bản sao (FR-003, edge case mất khóa) |

**State transitions**: `chưa tạo → đã tạo → đã backup → dùng ký release` (không thể quay lui; mất khóa chặn update).

## ReleaseArtifact

| Field | Kiểu | Ghi chú |
|---|---|---|
| aabPath | path | `build/app/outputs/bundle/release/app-release.aab` (FR-006) |
| apkPath | path | `build/app/outputs/flutter-apk/app-release.apk` (smoke test) |
| versionCode | int | khớp ReleaseConfig |
| signed | bool | true nếu ký bằng upload key |
| installable | bool | cài/mở được trên máy thật (SC-001) |

## PlayApp

| Field | Kiểu | Ràng buộc |
|---|---|---|
| appName | string | `Smart Wardrobe` |
| packageName | string | khớp applicationId |
| defaultLanguage | string | Vietnamese (FR-008) |
| pricing | enum | `Free` (FR-008/FR-021) |
| type | enum | `App` |

## StoreListing

| Field | Ràng buộc |
|---|---|
| title | ≤ 30 ký tự |
| shortDescription | ≤ 80 ký tự |
| fullDescription | đầy đủ, phản ánh chức năng thật |
| icon512 | 512×512 PNG |
| featureGraphic | 1024×500 PNG |
| screenshots | ≥ 2 (khuyến nghị 4–8) ảnh điện thoại |
| privacyPolicyUrl | URL công khai, hoạt động (FR-009/010) |

## ComplianceDeclaration

| Field | Ràng buộc |
|---|---|
| dataSafety | khớp hành vi thật; có mã hóa khi truyền; không khai location/analytics nếu không có (FR-011) |
| contentRating | hoàn tất bảng câu hỏi |
| targetAudience | chọn đúng nhóm tuổi |
| adsDeclaration | khai đúng (không có ads nếu thực tế không) |
| appAccess | `Login required` + tài khoản test + hướng dẫn (FR-012/013) |

## TestTrack

| Field | Kiểu | Ràng buộc |
|---|---|---|
| type | enum | `internal` / `closed` / `production` |
| testers | list<email> | closed: 15–20 mời, ≥ 12 opt-in (FR-016) |
| optInStatus | map<email,bool> | theo dõi hằng ngày |
| startDate | date | mốc bắt đầu đếm 14 ngày |
| consecutiveDays | int | ≥ 14 liên tục không gián đoạn (SC-006) |

**State transitions**: `draft → internal (rollout) → closed (rollout) → production-access-requested → production-access-approved → production-rollout → published`. Rớt opt-in trong giai đoạn đếm có thể reset điều kiện.

## ReleaseChecklist

| Nhóm | Mục tiêu biểu | FR |
|---|---|---|
| Security | keystore tạo/backup, key.properties ngoài git, không secret trong git | FR-003/005 |
| Build | clean, pub get, build appbundle, AAB tồn tại, release test | FR-006/007 |
| Store | listing, privacy, data safety, content rating, target audience, app access, ads, screenshots, icon | FR-008→013 |
| Testing | internal, closed, 12+/14 ngày, production access | FR-014→017 |
| Production | release tạo, AAB upload, review, rollout, published | FR-018/019 |
