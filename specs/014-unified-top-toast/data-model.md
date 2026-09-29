# Data Model: Closy Top Pop-up Toast

## 1. ClosyToastType Enum

```dart
enum ClosyToastType {
  error,
  warning,
  success,
  info,
}
```

## 2. ClosyToastConfig Model

```dart
class ClosyToastConfig {
  final String message;
  final ClosyToastType type;
  final Duration duration; // default: Duration(seconds: 2)
  final VoidCallback? onDismissed;

  const ClosyToastConfig({
    required this.message,
    this.type = ClosyToastType.info,
    this.duration = const Duration(seconds: 2),
    this.onDismissed,
  });
}
```

## 3. Style Resolution

Mỗi `ClosyToastType` ánh xạ tới các thuộc tính visual theo chuẩn Quiet Luxury:

- `backgroundColor`: Màu nền nhẹ nhàng, không chói gắt.
- `borderColor`: Viền bo 1px tinh tế.
- `iconColor`: Màu icon tương ứng trạng thái.
- `textColor`: Màu chữ dễ đọc, tương phản cao trên nền sáng.
- `icon`: Icon bo tròn tròn trịa (`Rounded`).
