import 'dart:math' as math;
import '../models/outfit_models.dart';

/// Bố cục canvas Studio thuần logic (không Flutter, không I/O) — US 005.
///
/// Tọa độ là độ lệch (logical px) so với tâm canvas; khung render
/// `200*scale` nên nửa cạnh = `100*scale`.
///
/// 005-studio-canvas-positions: research R2 (normalize), R3 (slot),
/// R4 (clamp + de-overlap).

/// Vai trò mặc đồ chuẩn. Mọi chuỗi role/slug thô đều được chuẩn hóa về đây.
enum CanvasRole {
  top,
  bottom,
  fullbody,
  outerwear,
  footwear,
  headwear,
  accessory,
  unknown,
}

/// Chuẩn hóa role thô (EN chuẩn, slug Việt, chuỗi rỗng) về [CanvasRole].
///
/// [categorySlug]/[categoryName] dùng làm tiebreaker khi role trống/lạ
/// (cùng bảng fragment như drawer filter + addItemFromWardrobe).
CanvasRole normalizeRole(String? rawRole, {String? categorySlug, String? categoryName}) {
  final r = (rawRole ?? '').toLowerCase().trim();
  const canonical = {
    'top': CanvasRole.top,
    'bottom': CanvasRole.bottom,
    'fullbody': CanvasRole.fullbody,
    'outerwear': CanvasRole.outerwear,
    'footwear': CanvasRole.footwear,
    'headwear': CanvasRole.headwear,
    'accessory': CanvasRole.accessory,
  };
  if (canonical.containsKey(r)) return canonical[r]!;

  final hay = '$r ${categorySlug?.toLowerCase() ?? ''} ${categoryName?.toLowerCase() ?? ''}';
  bool has(List<String> fragments) => fragments.any(hay.contains);

  // Thứ tự quan trọng: kiểm tra cụ thể trước, chung sau
  // (vd 'ao-khoac' chứa 'ao' nên outerwear phải trước top).
  if (has(const ['outerwear', 'khoac', 'coat', 'blazer', 'jacket'])) {
    return CanvasRole.outerwear;
  }
  if (has(const ['headwear', 'cap', 'hat', 'beanie', 'bucket', 'non', 'mu-'])) {
    return CanvasRole.headwear;
  }
  if (has(const ['footwear', 'giay', 'shoe', 'sneaker', 'sandal', 'boot', 'dep'])) {
    return CanvasRole.footwear;
  }
  if (has(const ['fullbody', 'dam', 'vay', 'dress', 'jumpsuit', 'lien'])) {
    return CanvasRole.fullbody;
  }
  if (has(const ['bottom', 'quan', 'pant', 'jean', 'short', 'skirt'])) {
    return CanvasRole.bottom;
  }
  if (has(const ['top', 'ao', 'shirt', 'tee', 'blouse', 'polo', 'hoodie', 'len'])) {
    return CanvasRole.top;
  }
  if (has(const ['accessory', 'phu-kien', 'phukien', 'tui', 'kinh', 'that-lung', 'khan', 'trang-suc'])) {
    return CanvasRole.accessory;
  }
  return CanvasRole.unknown;
}

/// Ô vị trí mặc định cho 1 role. [occurrence] = lần xuất hiện thứ mấy
/// của cùng role trong set (0-based) — món trùng role tự lệch cascade.
({double x, double y, int layer}) roleSlot(CanvasRole role, int occurrence) {
  double x;
  double y;
  int layer;
  switch (role) {
    case CanvasRole.top:
      x = 0; y = -120; layer = 2;
      break;
    case CanvasRole.bottom:
      x = 0; y = 80; layer = 1;
      break;
    case CanvasRole.fullbody:
      x = 0; y = -20; layer = 2;
      break;
    case CanvasRole.footwear:
      x = 0; y = 220; layer = 1;
      break;
    case CanvasRole.outerwear:
      x = 120; y = -110; layer = 3;
      break;
    case CanvasRole.headwear:
      x = -110; y = -170; layer = 4;
      break;
    case CanvasRole.accessory:
      x = -130; y = -90; layer = 4;
      break;
    case CanvasRole.unknown:
      const fallbacks = [(130.0, 0.0), (-130.0, 60.0), (130.0, 160.0), (-140.0, -40.0)];
      final pick = fallbacks[occurrence % fallbacks.length];
      x = pick.$1; y = pick.$2; layer = 5;
      break;
  }
  if (occurrence > 0 && role != CanvasRole.unknown) {
    // Món cùng vai trò thứ 2+ lệch cascade để không đè nhau.
    x += 60.0 * occurrence;
    y += 40.0 * occurrence;
  }
  return (x: x, y: y, layer: layer);
}

/// Hậu xử lý bố cục sau khi đặt vị trí ban đầu (clamp + tách chồng lấn).
///
/// - 1 món duy nhất → ra chính giữa canvas.
/// - Mọi tâm bị kẹp trong khung trừ lề 8px (tính theo `100*scale`).
/// - Hai tâm gần nhau < 80px → dịch món sau ra (+40,+30), tối đa 5 lần,
///   mỗi lần kẹp lại vào khung.
/// Trả về list mới (không mutate input).
List<CanvasItem> layoutCanvasItems(
  List<CanvasItem> items, {
  required double canvasWidth,
  required double canvasHeight,
}) {
  if (items.isEmpty) return items;
  var placed = items.map((it) => it.copyWith()).toList();

  if (placed.length == 1) {
    placed[0] = placed[0].copyWith(positionX: 0, positionY: 0);
    return placed;
  }

  for (var i = 0; i < placed.length; i++) {
    placed[i] = _clamp(placed[i], canvasWidth, canvasHeight);
  }

  const minDistance = 80.0;
  for (var i = 0; i < placed.length; i++) {
    for (var j = i + 1; j < placed.length; j++) {
      var tries = 0;
      while (tries < 5 && _distance(placed[i], placed[j]) < minDistance) {
        placed[j] = _clamp(
          placed[j].copyWith(
            positionX: placed[j].positionX + 40,
            positionY: placed[j].positionY + 30,
          ),
          canvasWidth,
          canvasHeight,
        );
        tries++;
      }
    }
  }
  return placed;
}

CanvasItem _clamp(CanvasItem item, double w, double h) {
  final half = 100.0 * item.scale;
  const margin = 8.0;
  final maxX = math.max(0.0, w / 2 - half - margin);
  final maxY = math.max(0.0, h / 2 - half - margin);
  return item.copyWith(
    positionX: item.positionX.clamp(-maxX, maxX),
    positionY: item.positionY.clamp(-maxY, maxY),
  );
}

double _distance(CanvasItem a, CanvasItem b) {
  final dx = a.positionX - b.positionX;
  final dy = a.positionY - b.positionY;
  return math.sqrt(dx * dx + dy * dy);
}
