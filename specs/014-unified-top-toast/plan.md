# Implementation Plan: Thống nhất thông báo toàn app thành Top Pop-up Toast 2 Giây

**Branch**: `014-unified-top-toast` | **Date**: 2026-09-28 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/014-unified-top-toast/spec.md`

## Summary

Xây dựng thành phần thông báo dạng Top Pop-up Toast (`ClosyToast`) độc lập, thanh lịch theo chuẩn Quiet Luxury, tự động hiển thị ở đỉnh màn hình (bên dưới Safe Area) trong đúng **2 giây** rồi tự động ẩn. Cho phép vuốt lên hoặc chạm để tắt sớm. Thay thế hoàn toàn khối lỗi đỏ tĩnh bên dưới nút "Tạo Set Đồ Với AI Ngay" trong Outfit Studio (nguyên nhân gây lỗi giao diện theo ảnh đính kèm của người dùng), đồng thời cung cấp hàm tiện ích toàn cục để thay thế các SnackBar rải rác.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x (`sdk: '>=3.0.0 <4.0.0'`)
**Primary Dependencies**: `flutter_riverpod ^2.5.1`, `go_router ^14.2.0`, `google_fonts`
**Storage**: N/A
**Testing**: `flutter test` (unit/widget test cho toast và outfit studio error listener)
**Target Platform**: Android, iOS, Web/Desktop
**Project Type**: Mobile Application
**Performance Goals**: Hiệu ứng chuyển động (slide/fade) đạt 60fps mượt mà, không giật lag; huỷ animation timer an toàn khi chuyển trang
**Constraints**: Thời gian hiển thị mặc định đúng 2.0s; tự động co giãn theo safe area top; không chồng chéo nhiều popup
**Scale/Scope**: Áp dụng cho thông báo quota AI trong Outfit Studio/Stylist và thay thế SnackBar phổ biến trong app

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **I. Spec-Driven & Verify-First**: Đầy đủ spec.md, plan.md, research.md, tasks.md, converge, kiểm thử và phân tích 0 issues.
- [x] **II. Feature-First Layered & Kỷ luật Riverpod**: Đặt toast widget trong `lib/shared/widgets/closy_toast.dart`, lắng nghe qua `ref.listen` trong presentation layer.
- [x] **III. Không Mock Khi Đã Có API**: Giữ nguyên API BE `/ai/outfit-recommendations`, chỉ chuẩn hoá cách hiển thị lỗi phía mobile client.
- [x] **IV. Hệ Thiết Kế Quiet Luxury**: Màu kem/ngà/burgundy mờ, border 1px tinh tế, font Be Vietnam Pro, cấm dùng màu đỏ chói `Colors.red`.
- [x] **V. Gotcha Windows & UTF-8**: Sử dụng file edit an toàn UTF-8, không mojibake.

## Project Structure

### Documentation (this feature)

```text
specs/014-unified-top-toast/
├── spec.md              # Feature specification
├── plan.md              # This file
├── research.md          # Technical research & decisions
├── data-model.md        # Toast models & state structure
├── quickstart.md        # Usage guide & code examples
├── contracts/
│   └── toast-api.md     # Public API contracts for ClosyToast
└── tasks.md             # Ordered actionable tasks
```

### Source Code (repository root)

```text
lib/
├── core/
│   └── router/
│       └── app_router.dart          # Export rootNavigatorKey cho global overlay fallback
├── shared/
│   └── widgets/
│       └── closy_toast.dart         # ClosyToast widget + ClosyToastType + ClosyToastManager
├── features/
│   └── outfit_studio/
│       └── presentation/
│           └── outfit_studio_screen.dart  # Bỏ khối đỏ tĩnh, ref.listen sang ClosyToast.show
test/
└── closy_toast_test.dart            # Widget tests cho Top Pop-up Toast 2s
```
