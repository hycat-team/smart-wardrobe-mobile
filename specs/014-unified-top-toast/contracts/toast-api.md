# Contract: ClosyToast Public API

## Methods

### `ClosyToast.show`

```dart
static void show(
  BuildContext? context, {
  required String message,
  ClosyToastType type = ClosyToastType.info,
  Duration duration = const Duration(seconds: 2),
})
```

- Nếu `context != null`, lấy `Overlay.of(context)`.
- Nếu `context == null` hoặc không có overlay lồng trong context, fallback về `rootNavigatorKey.currentState?.overlay`.
- Tự động huỷ toast cũ nếu đang hiển thị trước khi chèn toast mới.
- Tự động loại bỏ sau `duration` (mặc định 2 giây).

### Convenience Methods

```dart
static void error(BuildContext? context, String message, {Duration duration = const Duration(seconds: 2)})
static void success(BuildContext? context, String message, {Duration duration = const Duration(seconds: 2)})
static void warning(BuildContext? context, String message, {Duration duration = const Duration(seconds: 2)})
static void info(BuildContext? context, String message, {Duration duration = const Duration(seconds: 2)})
```
