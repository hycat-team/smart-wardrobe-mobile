# Tasks: Thống nhất thông báo toàn app thành Top Pop-up Toast 2 Giây

**Feature Branch**: `014-unified-top-toast`
**Spec**: [spec.md](./spec.md) | **Plan**: [plan.md](./plan.md)

## Phase 1: Foundational Setup

- [x] T001: Expose `rootNavigatorKey` trong `lib/core/router/app_router.dart` để hỗ trợ hiển thị overlay an toàn ngay cả khi không có `BuildContext` cục bộ
- [x] T002: Xây dựng widget và utility `ClosyToast` trong `lib/shared/widgets/closy_toast.dart` (hỗ trợ `ClosyToastType`, thời lượng 2 giây, animation trượt đỉnh màn hình, cử chỉ chạm/vuốt để tắt, bảng màu Quiet Luxury)

## Phase 2: User Story 1 - Thông báo hết lượt AI và lỗi tác vụ ở đỉnh màn hình (P1)

- [x] T003: [US1] Xóa bỏ khối Container màu đỏ tĩnh bên dưới nút "Tạo Set Đồ Với AI Ngay" trong `lib/features/outfit_studio/presentation/outfit_studio_screen.dart`
- [x] T004: [US1] Thêm `ref.listen` lắng nghe `errorMessage` từ `aiOutfitProvider` trong `outfit_studio_screen.dart` để kích hoạt `ClosyToast.error` xuất hiện ở đỉnh màn hình trong 2 giây

## Phase 3: User Story 2 & Verification - Kiểm thử tự động & Bàn giao (P2)

- [x] T005: [US2] Viết widget test cho `ClosyToast` trong `test/closy_toast_test.dart` (kiểm tra hiển thị ở đỉnh, nội dung thông báo, và cơ chế tự ẩn sau 2 giây)
- [x] T006: [Verification] Chạy `flutter test` và `flutter analyze` đảm bảo 0 issues
- [x] T007: [Documentation] Cập nhật nhật ký công việc `docs/work-log-2026-09-28.md`

## Dependencies & Execution Order

1. T001, T002 (Foundational) hoàn thành trước.
2. T003, T004 (Outfit Studio migration) hoàn thành sau khi có `ClosyToast`.
3. T005, T006, T007 (Kiểm thử, phân tích, tài liệu) nghiệm thu toàn bộ tính năng.
