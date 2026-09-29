# Quickstart: ClosyToast Top Pop-up Notification

## Cách sử dụng

### 1. Hiển thị thông báo lỗi / hết lượt AI (2 giây)

```dart
ClosyToast.error(context, 'Bạn đã dùng hết lượt tạo trang phục bằng AI trong hôm nay.');
```

### 2. Hiển thị thông báo thành công (2 giây)

```dart
ClosyToast.success(context, 'Đã lưu trang phục thành công!');
```

### 3. Hiển thị cảnh báo hoặc thông tin chung

```dart
ClosyToast.warning(context, 'Vui lòng chọn ít nhất 1 món đồ');
ClosyToast.info(context, 'Đang cập nhật dữ liệu tủ đồ...');
```

### 4. Đóng toast thủ công

Toast tự động trượt lên và biến mất sau 2 giây. Người dùng cũng có thể:
- Nhấn trực tiếp vào toast để đóng tức thì.
- Vuốt lên (swipe up) để ẩn tức thì.
