import 'dart:math' as math;
import '../models/outfit_models.dart';

/// Vai trò mặc đồ chuẩn (FashionRole). Chuỗi thô/slug đều được chuẩn hóa về đây.
enum CanvasRole {
  top,
  bottom,
  fullbody,
  outerwear,
  footwear,
  headwear,
  accessory,
  other,
  unknown,
}

/// Vai trò "độc quyền" — mỗi loại chỉ giữ tối đa một món trên canvas.
/// `headwear`/`accessory`/`other`/`unknown` nằm ngoài tập này (cho phép nhiều món).
const Set<CanvasRole> exclusiveRoles = {
  CanvasRole.top,
  CanvasRole.bottom,
  CanvasRole.fullbody,
  CanvasRole.outerwear,
  CanvasRole.footwear,
};

/// true nếu [role] chỉ nên có một món trên canvas.
bool isExclusiveRole(CanvasRole role) => exclusiveRoles.contains(role);

/// Dạng cấu trúc phối trang phục.
enum OutfitCompositionType {
  separatePieces,
  fullbody,
  incomplete,
}

/// Tọa độ và thuộc tính đặt chỗ mặc định cho một vai trò.
class RolePlacement {
  final double x;
  final double y;
  final double scale;
  final int zIndex;

  const RolePlacement({
    required this.x,
    required this.y,
    required this.scale,
    required this.zIndex,
  });
}

/// Tỉ lệ khung bao (bounding box) theo chiều rộng và chiều cao cho từng vai trò.
class RoleBoundingBox {
  final double widthRatio;
  final double heightRatio;

  const RoleBoundingBox({
    required this.widthRatio,
    required this.heightRatio,
  });
}

/// Bố cục giải phẫu chuẩn cho trang phục dạng rời (top + bottom + footwear).
/// Gốc tọa độ (0, 0) tại tâm canvas.
const roleCoordinatesSeparate = <CanvasRole, RolePlacement>{
  CanvasRole.headwear: RolePlacement(x: 0, y: -495, scale: 114, zIndex: 8),
  CanvasRole.top: RolePlacement(x: 0, y: -210, scale: 168, zIndex: 5),
  CanvasRole.outerwear: RolePlacement(x: -25, y: -210, scale: 158, zIndex: 7),
  CanvasRole.bottom: RolePlacement(x: 0, y: 165, scale: 168, zIndex: 4),
  CanvasRole.footwear: RolePlacement(x: 0, y: 452, scale: 120, zIndex: 3),
  CanvasRole.accessory: RolePlacement(x: -240, y: -285, scale: 74, zIndex: 9),
  CanvasRole.other: RolePlacement(x: 250, y: 270, scale: 56, zIndex: 2),
  CanvasRole.fullbody: RolePlacement(x: 0, y: -20, scale: 177, zIndex: 5),
  CanvasRole.unknown: RolePlacement(x: 250, y: 270, scale: 56, zIndex: 2),
};

/// Bố cục giải phẫu chuẩn cho trang phục dạng liền thân (fullbody + footwear).
const roleCoordinatesFullbody = <CanvasRole, RolePlacement>{
  CanvasRole.headwear: RolePlacement(x: 0, y: -495, scale: 114, zIndex: 8),
  CanvasRole.fullbody: RolePlacement(x: 0, y: -20, scale: 177, zIndex: 5),
  CanvasRole.outerwear: RolePlacement(x: -25, y: -195, scale: 158, zIndex: 7),
  CanvasRole.top: RolePlacement(x: 0, y: -210, scale: 168, zIndex: 5),
  CanvasRole.bottom: RolePlacement(x: 0, y: 165, scale: 168, zIndex: 4),
  CanvasRole.footwear: RolePlacement(x: 0, y: 452, scale: 120, zIndex: 3),
  CanvasRole.accessory: RolePlacement(x: -240, y: -278, scale: 74, zIndex: 9),
  CanvasRole.other: RolePlacement(x: 250, y: 255, scale: 56, zIndex: 2),
  CanvasRole.unknown: RolePlacement(x: 250, y: 255, scale: 56, zIndex: 2),
};

/// Tọa độ bổ sung dành cho phụ kiện thứ 2 trở lên (phân bổ so le sang cánh phải).
const secondaryAccessoryCoordinates = <RolePlacement>[
  RolePlacement(x: 240, y: -210, scale: 74, zIndex: 9), // Phụ kiện 2: cánh phải trên
  RolePlacement(x: 240, y: -150, scale: 74, zIndex: 9), // Phụ kiện 3: cánh phải dưới
  RolePlacement(x: -240, y: -170, scale: 74, zIndex: 9), // Phụ kiện 4: cánh trái trên
];

/// Lấy vị trí cho phụ kiện thứ N (0-based: 0 là phụ kiện chính).
RolePlacement getAccessoryPlacement(int accessoryIndex, {bool hasFullbody = false}) {
  if (accessoryIndex == 0) {
    return hasFullbody
        ? roleCoordinatesFullbody[CanvasRole.accessory]!
        : roleCoordinatesSeparate[CanvasRole.accessory]!;
  }
  final secIndex = accessoryIndex - 1;
  if (secIndex < secondaryAccessoryCoordinates.length) {
    return secondaryAccessoryCoordinates[secIndex];
  }
  return RolePlacement(
    x: 240,
    y: 80 + (secIndex - 1) * 60.0,
    scale: 74,
    zIndex: 9,
  );
}

/// Tỉ lệ khung bao (bounding box) theo từng vai trò trang phục.
const roleBoundingBoxRatios = <CanvasRole, RoleBoundingBox>{
  CanvasRole.headwear: RoleBoundingBox(widthRatio: 1.8, heightRatio: 1.4),
  CanvasRole.top: RoleBoundingBox(widthRatio: 2.1, heightRatio: 2.1),
  CanvasRole.outerwear: RoleBoundingBox(widthRatio: 2.3, heightRatio: 2.3),
  CanvasRole.bottom: RoleBoundingBox(widthRatio: 1.9, heightRatio: 2.3),
  CanvasRole.fullbody: RoleBoundingBox(widthRatio: 2.1, heightRatio: 3.2),
  CanvasRole.footwear: RoleBoundingBox(widthRatio: 1.8, heightRatio: 1.3),
  CanvasRole.accessory: RoleBoundingBox(widthRatio: 1.6, heightRatio: 1.6),
  CanvasRole.other: RoleBoundingBox(widthRatio: 2.0, heightRatio: 2.0),
  CanvasRole.unknown: RoleBoundingBox(widthRatio: 2.0, heightRatio: 2.0),
};

/// Chuẩn hóa vai trò từ chuỗi thô, slug hoặc tên danh mục.
CanvasRole normalizeRole(String? rawRole, {String? categorySlug, String? categoryName}) {
  final roleStr = (rawRole ?? '').toLowerCase().trim();

  // 1. Kiểm tra chuỗi vai trò chính xác
  if (roleStr == 'headwear' ||
      roleStr == 'mu' ||
      roleStr == 'non' ||
      roleStr.contains('mũ') ||
      roleStr.contains('nón') ||
      roleStr.contains('hat') ||
      roleStr.contains('cap') ||
      roleStr.contains('beanie') ||
      roleStr.contains('bucket')) {
    return CanvasRole.headwear;
  }

  if (roleStr == 'fullbody' ||
      roleStr == 'dam' ||
      roleStr.contains('đầm') ||
      roleStr.contains('liền') ||
      roleStr.contains('dress') ||
      roleStr.contains('jumpsuit')) {
    return CanvasRole.fullbody;
  }

  if (roleStr == 'outerwear' ||
      roleStr.contains('khoác') ||
      roleStr.contains('jacket') ||
      roleStr.contains('blazer') ||
      roleStr.contains('coat') ||
      roleStr.contains('cardigan')) {
    return CanvasRole.outerwear;
  }

  if (roleStr == 'top' ||
      roleStr.contains('áo') ||
      roleStr.contains('top') ||
      roleStr.contains('shirt') ||
      roleStr.contains('tee') ||
      roleStr.contains('blouse') ||
      roleStr.contains('polo') ||
      roleStr.contains('hoodie')) {
    return CanvasRole.top;
  }

  if (roleStr == 'bottom' ||
      roleStr.contains('quần') ||
      roleStr.contains('váy') ||
      roleStr.contains('pants') ||
      roleStr.contains('skirt') ||
      roleStr.contains('jean') ||
      roleStr.contains('short')) {
    return CanvasRole.bottom;
  }

  if (roleStr == 'footwear' ||
      roleStr.contains('giày') ||
      roleStr.contains('dép') ||
      roleStr.contains('shoes') ||
      roleStr.contains('footwear') ||
      roleStr.contains('sneaker') ||
      roleStr.contains('sandal') ||
      roleStr.contains('boot') ||
      roleStr.contains('dep')) {
    return CanvasRole.footwear;
  }

  if (roleStr == 'accessory' ||
      roleStr.contains('phụ kiện') ||
      roleStr.contains('phu-kien') ||
      roleStr.contains('túi') ||
      roleStr.contains('tui') ||
      roleStr.contains('bag') ||
      roleStr.contains('accessory') ||
      roleStr.contains('kính') ||
      roleStr.contains('kinh') ||
      roleStr.contains('glasses') ||
      roleStr.contains('that-lung') ||
      roleStr.contains('thắt lưng') ||
      roleStr.contains('khan') ||
      roleStr.contains('khăn') ||
      roleStr.contains('trang-suc') ||
      roleStr.contains('trang sức') ||
      roleStr.contains('trang suc')) {
    return CanvasRole.accessory;
  }

  if (roleStr == 'other') {
    return CanvasRole.other;
  }

  // 2. Fallback dựa vào categorySlug hoặc categoryName
  final slug = (categorySlug ?? '').toLowerCase().trim();
  final name = (categoryName ?? '').toLowerCase().trim();
  final combined = '$slug $name';

  if (combined.contains('mu') ||
      combined.contains('mũ') ||
      combined.contains('non') ||
      combined.contains('nón') ||
      combined.contains('hat') ||
      combined.contains('cap')) {
    return CanvasRole.headwear;
  }
  if (combined.contains('dam') ||
      combined.contains('đầm') ||
      combined.contains('dress') ||
      combined.contains('jumpsuit') ||
      combined.contains('vay-lien')) {
    return CanvasRole.fullbody;
  }
  if (combined.contains('ao-khoac') ||
      combined.contains('khoác') ||
      combined.contains('jacket') ||
      combined.contains('blazer') ||
      combined.contains('coat') ||
      combined.contains('cardigan')) {
    return CanvasRole.outerwear;
  }
  if (combined.contains('ao') ||
      combined.contains('áo') ||
      combined.startsWith('ao-') ||
      combined.contains('top') ||
      combined.contains('shirt')) {
    return CanvasRole.top;
  }
  if (combined.contains('quan') ||
      combined.contains('quần') ||
      combined.contains('chan-vay') ||
      combined.contains('váy') ||
      combined.contains('bottom') ||
      combined.contains('skirt') ||
      combined.contains('pants')) {
    return CanvasRole.bottom;
  }
  if (combined.contains('giay') ||
      combined.contains('giày') ||
      combined.startsWith('giay-') ||
      combined.contains('shoes') ||
      combined.contains('footwear') ||
      combined.contains('sneaker') ||
      combined.contains('sandal') ||
      combined.contains('dép') ||
      combined.contains('dep')) {
    return CanvasRole.footwear;
  }
  if (combined.contains('phu-kien') ||
      combined.contains('phụ kiện') ||
      combined.startsWith('phu-kien-') ||
      combined.contains('bag') ||
      combined.contains('accessory') ||
      combined.contains('tui') ||
      combined.contains('túi') ||
      combined.contains('kinh') ||
      combined.contains('kính')) {
    return CanvasRole.accessory;
  }

  return CanvasRole.unknown;
}

/// Xác định dạng phối đồ của danh sách các vai trò.
OutfitCompositionType detectCompositionType(Iterable<CanvasRole> roles) {
  final roleList = roles.toList();
  if (roleList.contains(CanvasRole.fullbody)) {
    return OutfitCompositionType.fullbody;
  }
  if (roleList.contains(CanvasRole.top) || roleList.contains(CanvasRole.bottom)) {
    return OutfitCompositionType.separatePieces;
  }
  return OutfitCompositionType.incomplete;
}

/// Khôi phục vị trí chuẩn hóa khi mở outfit đã lưu từ backend (sửa lỗi dữ liệu cũ legacy).
({double x, double y, int layerOrder}) restoreCanvasPlacement({
  required CanvasRole role,
  double? positionX,
  double? positionY,
  int? layerOrder,
  OutfitCompositionType compositionType = OutfitCompositionType.separatePieces,
}) {
  final coordinateMap = compositionType == OutfitCompositionType.fullbody
      ? roleCoordinatesFullbody
      : roleCoordinatesSeparate;
  final defaultCoord = coordinateMap[role] ?? coordinateMap[CanvasRole.other]!;

  double x = (positionX != null && !positionX.isNaN) ? positionX : defaultCoord.x;
  double y = (positionY != null && !positionY.isNaN) ? positionY : defaultCoord.y;
  int zIndex = (layerOrder != null && layerOrder > 0) ? layerOrder : defaultCoord.zIndex;

  // 1. Khắc phục lỗi Math.abs() của dữ liệu cũ (thân trên Y luôn âm)
  if ((role == CanvasRole.top ||
          role == CanvasRole.headwear ||
          role == CanvasRole.outerwear ||
          role == CanvasRole.fullbody) &&
      y > 0) {
    y = -y;
  }

  // 2. Khắc phục x = 1 hoặc -1 do Math.max(1, 0)
  if (x.abs() == 1 && defaultCoord.x == 0) {
    x = 0;
  }

  // 3. Khắc phục x = 25 cho outerwear (chuẩn là -25)
  if (role == CanvasRole.outerwear && x == 25) {
    x = -25;
  }

  // 4. Nâng vị trí giày dép lên 295 nếu lưu ở tọa độ cũ 305
  if (role == CanvasRole.footwear && y == 305) {
    y = 295;
  }

  // 5. Nếu tọa độ quá gần 0 (missing hoặc chưa bố cục)
  if (x.abs() < 2 && y.abs() < 2 && (defaultCoord.x != 0 || defaultCoord.y != 0)) {
    x = defaultCoord.x;
    y = defaultCoord.y;
    zIndex = defaultCoord.zIndex;
  }

  return (x: x, y: y, layerOrder: zIndex);
}

/// Hậu xử lý bố cục sau khi đặt vị trí ban đầu (tách chồng lấn + vừa khung + căn tâm).
List<CanvasItem> layoutCanvasItems(
  List<CanvasItem> items, {
  required double canvasWidth,
  required double canvasHeight,
}) {
  if (items.isEmpty) return items;
  var placed = items.map((it) => it.copyWith()).toList();

  // 1. Nếu chỉ có đúng 1 món -> đặt ngay tâm
  if (placed.length == 1) {
    placed[0] = placed[0].copyWith(positionX: 0, positionY: 0);
    return placed;
  }

  // 2. Tách chồng lấn: nếu 2 tâm quá gần nhau (< 80px), dịch nhẹ món sau ra
  const minDistance = 80.0;
  for (var i = 0; i < placed.length; i++) {
    for (var j = i + 1; j < placed.length; j++) {
      var tries = 0;
      while (tries < 5 && _distance(placed[i], placed[j]) < minDistance) {
        placed[j] = placed[j].copyWith(
          positionX: placed[j].positionX + 40,
          positionY: placed[j].positionY + 30,
        );
        tries++;
      }
    }
  }

  // 3. Tính toán Bounding Box bao toàn bộ các món trên canvas
  double minX = double.infinity;
  double maxX = -double.infinity;
  double minY = double.infinity;
  double maxY = -double.infinity;

  const double itemScaleMultiplier = 1.25;

  for (final item in placed) {
    final w = item.baseScale * item.boxRatioW * item.scale * itemScaleMultiplier;
    final h = item.baseScale * item.boxRatioH * item.scale * itemScaleMultiplier;
    final left = item.positionX - (w / 2);
    final right = item.positionX + (w / 2);
    final top = item.positionY - (h / 2);
    final bottom = item.positionY + (h / 2);

    if (left < minX) minX = left;
    if (right > maxX) maxX = right;
    if (top < minY) minY = top;
    if (bottom > maxY) maxY = bottom;
  }

  final bboxW = math.max(1.0, maxX - minX);
  final bboxH = math.max(1.0, maxY - minY);

  // 4. Vừa-khung (Fit to canvas) với lề an toàn 20px và khoảng đệm thanh tủ đồ ở đáy (45px)
  const margin = 20.0;
  const bottomReserve = 45.0;
  final availW = math.max(100.0, canvasWidth - (margin * 2));
  final availH = math.max(100.0, canvasHeight - margin - bottomReserve);

  double fitK = 1.0;
  if (bboxW > availW || bboxH > availH) {
    fitK = math.min(availW / bboxW, availH / bboxH);
    fitK = fitK.clamp(0.2, 1.0);
  }

  // 5. Tịnh tiến đưa tâm cụm đồ về chính giữa vùng khả dụng (phía trên thanh tủ đồ)
  final centerBboxX = ((minX + maxX) / 2) * fitK;
  final centerBboxY = (((minY + maxY) / 2) * fitK) + (bottomReserve / 2);

  for (var i = 0; i < placed.length; i++) {
    final item = placed[i];
    final scaledX = (item.positionX * fitK) - centerBboxX;
    final scaledY = (item.positionY * fitK) - centerBboxY;
    final scaledItemScale = item.scale * fitK;

    placed[i] = clampCanvasItem(
      item.copyWith(
        positionX: scaledX,
        positionY: scaledY,
        scale: scaledItemScale,
      ),
      canvasWidth,
      canvasHeight,
    );
  }

  return placed;
}

/// Kẹp một món vào biên canvas (tâm tọa độ canvas là gốc 0,0).
///
/// Nếu món ở scale hiện tại lớn hơn vùng khả dụng, [scale] được giảm trước
/// (sàn 0.15) rồi mới kẹp vị trí. Dùng đúng công thức kích thước của render:
/// `baseScale * boxRatio * scale * 1.25`.
CanvasItem clampCanvasItem(CanvasItem item, double canvasWidth, double canvasHeight) {
  const double itemScaleMultiplier = 1.25;
  const double margin = 8.0;

  final double baseScale = item.baseScale > 0 ? item.baseScale : 100.0;
  final double ratioW = item.boxRatioW > 0 ? item.boxRatioW : 2.0;
  final double ratioH = item.boxRatioH > 0 ? item.boxRatioH : 2.0;

  final double availW = math.max(0.0, canvasWidth - (margin * 2));
  final double availH = math.max(0.0, canvasHeight - (margin * 2));

  double scale = item.scale;
  double itemW = baseScale * ratioW * scale * itemScaleMultiplier;
  double itemH = baseScale * ratioH * scale * itemScaleMultiplier;

  if (itemW > availW || itemH > availH) {
    final double unitW = baseScale * ratioW * itemScaleMultiplier;
    final double unitH = baseScale * ratioH * itemScaleMultiplier;
    double targetScale = scale;
    if (unitW > 0 && itemW > availW) {
      targetScale = math.min(targetScale, availW / unitW);
    }
    if (unitH > 0 && itemH > availH) {
      targetScale = math.min(targetScale, availH / unitH);
    }
    scale = targetScale.clamp(0.15, 3.0);
    itemW = baseScale * ratioW * scale * itemScaleMultiplier;
    itemH = baseScale * ratioH * scale * itemScaleMultiplier;
  }

  final double maxX = math.max(0.0, (canvasWidth - itemW) / 2 - margin);
  final double maxY = math.max(0.0, (canvasHeight - itemH) / 2 - margin);
  return item.copyWith(
    positionX: item.positionX.clamp(-maxX, maxX),
    positionY: item.positionY.clamp(-maxY, maxY),
    scale: scale,
  );
}

/// Áo khoác đặt đối diện phụ kiện, chồng lên lớp nền (`top`/`fullbody`) ≤ 40%.
///
/// Bản chỉnh 2026-10-13 (R4/INV-6): áo khoác luôn **rộng bằng áo** (cùng kích
/// thước) và chồng một phần nhưng **không quá 40%** bề rộng áo. Lớp nền giữ
/// nguyên vị trí (cột giữa); áo khoác đặt ở **phía đối diện phụ kiện** (nếu có),
/// nếu không thì chọn phía còn nhiều chỗ hơn. Trên khung hẹp, cả hai được thu
/// cùng tỉ lệ (giữ bằng nhau) để vẫn thoả ≤ 40%. Trả về nguyên trạng nếu thiếu
/// áo khoác hoặc thiếu lớp nền.
List<CanvasItem> layoutOuterwearOverBase(
  List<CanvasItem> items, {
  required double canvasWidth,
  required double canvasHeight,
}) {
  const double margin = 8.0;
  const double itemScaleMultiplier = 1.25;
  const double overlapFraction = 0.40;
  const double minScale = 0.15;

  final int outerwearIndex =
      items.indexWhere((it) => it.role == CanvasRole.outerwear.name);
  final int baseIndex = items.indexWhere(
    (it) => it.role == CanvasRole.top.name || it.role == CanvasRole.fullbody.name,
  );
  if (outerwearIndex < 0 || baseIndex < 0) return items;

  final CanvasItem base = items[baseIndex];
  final CanvasItem ow = items[outerwearIndex];
  double coeff(CanvasItem it) => it.baseScale * it.boxRatioW * itemScaleMultiplier;
  final double baseCoeff = coeff(base);
  final double owCoeff = coeff(ow);

  final double minX = -canvasWidth / 2 + margin;
  final double maxX = canvasWidth / 2 - margin;
  final double baseX = base.positionX;

  // Với áo khoác rộng bằng áo và chồng `overlapFraction` bề rộng áo:
  //   phải: baseX + (1.1)*baseW ≤ maxX  → baseW ≤ (maxX - baseX) / 1.1
  final double denom = 1.0 + 0.5 - overlapFraction; // 1.1
  final double roomRightBaseW = (maxX - baseX) / denom;
  final double roomLeftBaseW = (baseX - minX) / denom;

  // Áo khoác luôn ĐỐI DIỆN phụ kiện.
  final accessories = items.where((it) => it.role == CanvasRole.accessory.name);
  final bool hasLeftAcc = accessories.any((it) => it.positionX < 0);
  final bool hasRightAcc = accessories.any((it) => it.positionX > 0);
  final bool useRight;
  if (hasLeftAcc && !hasRightAcc) {
    useRight = true;
  } else if (hasRightAcc && !hasLeftAcc) {
    useRight = false;
  } else {
    useRight = roomRightBaseW >= roomLeftBaseW;
  }

  final double baseWnat = baseCoeff * base.scale;
  final double allowedBaseW = math.max(
    0.0,
    math.min(baseWnat, useRight ? roomRightBaseW : roomLeftBaseW),
  );
  final double targetBaseScale = baseCoeff > 0 ? allowedBaseW / baseCoeff : base.scale;
  final double newBaseScale = base.scale < minScale
      ? base.scale
      : targetBaseScale.clamp(minScale, base.scale);
  final double newBaseW = baseCoeff * newBaseScale;

  // Áo khoác rộng bằng áo (cùng kích thước).
  final double newOwScale =
      owCoeff > 0 ? (newBaseW / owCoeff).clamp(minScale, 3.0) : ow.scale;
  final double newOwW = owCoeff * newOwScale;
  final double overlap = overlapFraction * newBaseW;

  final double baseL = baseX - newBaseW / 2;
  final double baseR = baseX + newBaseW / 2;
  final double owX = useRight
      ? (baseR - overlap) + newOwW / 2
      : (baseL + overlap) - newOwW / 2;

  final placed = List<CanvasItem>.from(items);
  placed[baseIndex] = base.copyWith(scale: newBaseScale);
  var outerwear = ow.copyWith(
    positionX: owX,
    positionY: base.positionY,
    scale: newOwScale,
  );
  if (outerwear.layerOrder <= base.layerOrder) {
    outerwear = outerwear.copyWith(layerOrder: base.layerOrder + 1);
  }
  placed[outerwearIndex] = outerwear;
  for (var i = 0; i < placed.length; i++) {
    placed[i] = clampCanvasItem(placed[i], canvasWidth, canvasHeight);
  }
  return placed;
}

/// Đưa phụ kiện **sát cột giữa** (quần áo/nón/giày) nhưng **không đè** lên cột.
///
/// Bản chỉnh 2026-10-13: cột giữa gồm `top/bottom/fullbody/headwear/footwear`.
/// Phụ kiện được đặt ở **phía đối diện áo khoác** (nếu không có áo khoác → bên
/// trái), nép sát mép cột một khoảng `gap` nhỏ, rồi kẹp vào khung. Trả về nguyên
/// trạng nếu không có phụ kiện hoặc không có cột.
List<CanvasItem> layoutAccessoriesHugColumn(
  List<CanvasItem> items, {
  required double canvasWidth,
  required double canvasHeight,
}) {
  const double itemScaleMultiplier = 1.25;
  const double gap = 4.0;
  const Set<String> columnRoleNames = {
    'top',
    'bottom',
    'fullbody',
    'headwear',
    'footwear',
  };

  double colLeft = double.infinity;
  double colRight = -double.infinity;
  for (final it in items) {
    if (!columnRoleNames.contains(it.role)) continue;
    final double w = it.baseScale * it.boxRatioW * it.scale * itemScaleMultiplier;
    if (it.positionX - w / 2 < colLeft) colLeft = it.positionX - w / 2;
    if (it.positionX + w / 2 > colRight) colRight = it.positionX + w / 2;
  }

  final accIndexes = <int>[
    for (var i = 0; i < items.length; i++)
      if (items[i].role == CanvasRole.accessory.name) i,
  ];
  if (accIndexes.isEmpty || colLeft == double.infinity) return items;

  final int owIndex = items.indexWhere((it) => it.role == CanvasRole.outerwear.name);
  final bool placeLeft = owIndex < 0 || items[owIndex].positionX >= 0;

  final placed = List<CanvasItem>.from(items);
  for (final i in accIndexes) {
    final it = placed[i];
    final double w = it.baseScale * it.boxRatioW * it.scale * itemScaleMultiplier;
    final double x =
        placeLeft ? colLeft - gap - w / 2 : colRight + gap + w / 2;
    placed[i] = it.copyWith(positionX: x);
  }
  for (var i = 0; i < placed.length; i++) {
    placed[i] = clampCanvasItem(placed[i], canvasWidth, canvasHeight);
  }
  return placed;
}

/// Dịch cả danh sách sang ngang để **tâm bbox trùng tâm canvas** — cột giữa
/// (áo/quần/nón/giày) nằm chính giữa màn hình dù áo khoác thò sang một bên.
/// Kẹp lại sau khi dịch để không tràn biên.
List<CanvasItem> centerItemsHorizontally(
  List<CanvasItem> items, {
  required double canvasWidth,
  required double canvasHeight,
}) {
  if (items.length <= 1) return items;
  const double itemScaleMultiplier = 1.25;
  double minX = double.infinity;
  double maxX = -double.infinity;
  for (final it in items) {
    final double w = it.baseScale * it.boxRatioW * it.scale * itemScaleMultiplier;
    if (it.positionX - w / 2 < minX) minX = it.positionX - w / 2;
    if (it.positionX + w / 2 > maxX) maxX = it.positionX + w / 2;
  }
  final double delta = (minX + maxX) / 2;
  if (delta.abs() < 0.5) return items;
  final shifted = [
    for (final it in items) it.copyWith(positionX: it.positionX - delta),
  ];
  for (var i = 0; i < shifted.length; i++) {
    shifted[i] = clampCanvasItem(shifted[i], canvasWidth, canvasHeight);
  }
  return shifted;
}

double _distance(CanvasItem a, CanvasItem b) {
  final dx = a.positionX - b.positionX;
  final dy = a.positionY - b.positionY;
  return math.sqrt(dx * dx + dy * dy);
}
