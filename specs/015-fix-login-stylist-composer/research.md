# Phase 0 — Research: 015-fix-login-stylist-composer

**Ngày**: 2026-10-02 | **Spec**: [spec.md](./spec.md)

Mọi mục dưới đây đã được **xác minh trên mã nguồn thật** (app `smart-wardrobe-mobile` và
repo BE `smart-wardrobe-be`), không phải suy đoán.

---

## R1. Vì sao `checkAuthStatus` không phân biệt được lỗi mạng với token bị từ chối

**Question**: FR-026 yêu cầu phân biệt "lỗi tạm thời" với "token không hợp lệ". Hiện tại có làm được không?

**Finding**: **Không** — thông tin bị mất ngay từ tầng repository.

`auth_repository.dart:172-180`:
```dart
Future<UserModel> getCurrentUser() async {
  try {
    final response = await _apiClient.dio.get('/me');
    ...
  } on DioException catch (e) {
    throw Exception(_extractErrorMessage(e, 'Không thể tải thông tin cá nhân'));
  }
}
```

`DioException` bị **nuốt** và thay bằng `Exception` chuỗi tiếng Việt. Tới
`checkAuthStatus()` (`auth_provider.dart:74-78`) chỉ còn một `catch (_)` trần —
không còn mã trạng thái HTTP, không phân biệt được `401` với lỗi mạng.

Tệ hơn: `_extractErrorMessage` gộp cả lỗi mạng và lỗi HTTP vào cùng một nhánh
chuỗi, nên phân biệt bằng cách so khớp chuỗi cũng không đáng tin.

**Decision**: `getCurrentUser()` phải **giữ lại nguyên `DioException`** (rethrow, không
bọc), chỉ dịch thông điệp hiển thị ở tầng trên. `checkAuthStatus()` bắt `DioException`
và rẽ nhánh theo `e.response?.statusCode`.

**Rationale**: Đây là thay đổi nhỏ nhất mà vẫn làm FR-026/027/028 kiểm thử được.
Có sẵn cơ chế sẵn ở `api_client.dart:66-109` — interceptor 401 đã tự refresh token rồi mới
gọi `_triggerForcedLogout()`, nên đường "token thật sự hỏng" vốn đã có đường đi riêng.

**Alternatives considered**:
- *Thêm getter `statusCode` vào exception tuỳ biến* — nhiều bề mặt hơn mà không thêm giá trị gì so với rethrow.
- *So khớp chuỗi thông báo* — dễ vỡ, không kiểm thử được. Loại.

---

## R2. Cổng chặn đăng nhập lúc khởi động nằm ở đâu

**Question**: Splash nên chặn ở `main.dart` hay ở router?

**Finding**: Router đọc trạng thái đồng bộ và **không có trạng thái trung gian**.

`app_router.dart:85-88`:
```dart
initialLocation: '/login',
redirect: (context, state) {
  final authState = ref.read(authStateProvider);
  final isAuth = authState.isAuthenticated;
```

`AuthState` khởi tạo với `isAuthenticated: false` (`auth_provider.dart:20-26`) và
`AuthNotifier` gọi `checkAuthStatus()` kiểu fire-and-forget trong constructor
(`auth_provider.dart:59`). Ba hệ quả:

1. Không có cách nào biết "chưa biết" → phải thêm trạng thái mới.
2. `AppRouterNotifier` chỉ `notifyListeners()` khi `isAuthenticated` **đổi**
   (`app_router.dart:48`) — cờ mới không phát tín hiệu.
3. `refreshListenable` không phủ được lúc state mới đổi nếu không sửa (2).

**Decision**:
- Thêm cờ `isCheckingAuth` vào `AuthState`, mặc định `true`, tắt trong `finally` của
  `checkAuthStatus` (đảm bảo FR-002 kể cả khi throw).
- `AppRouterNotifier` so sánh **cả hai** cờ rồi mới `notifyListeners()`.
- `redirect` thoát sớm (không áp luật đá về `/login`) khi `isCheckingAuth`.
- `SmartWardrobeApp.build` (`main.dart:86`) hiển thị splash khi `isCheckingAuth`.

**Rationale**: Splash ở `MaterialApp.router` **trên** router thì router vẫn có thể tính
đích đến bình thường, và người dùng không thấy nháy `/login`. Không cần thêm route
mới nên không đụng cờ phát hành/deep-link.

**Alternatives considered**:
- *Thêm route `/splash` thật* — phải khai báo thêm vào `_isAuthPath`, dễ sót nhánh redirect. Loại.
- *Chặn bằng `FutureBuilder` quanh `runApp`* — không kiểm soát được lúc router dựng. Loại.

---

## R3. Ngưỡng chống nháy 1 giây (đã chốt ở clarify, cần số đo)

**Finding**: Chưa có số đo. `checkAuthStatus()` tốn 2 lượt I/O: đọc secure storage
rồi `GET /me`.

**Decision**: Tạo `Future.delayed` 1 giây có thể huỷ, đếm ngược **song song** với việc
kiểm tra phiên. Splash **luôn hiện** ở mọi lần khởi động; nếu kiểm tra phiên xong sớm
hơn thì ẩn sớm hơn, nhưng vẫn phải đã hiện ra.

> **Đính chính sau clarify (2026-10-02)**: bản ghi đầu tiên của R3 viết "splash
> **không** bị ép hiện nếu không cần". Điều đó **mâu thuẫn** với FR-003 và SC-002, và
> đã bị `/speckit-analyze` phát hiện. Người dùng đã chốt: splash luôn hiện.

**Rationale**: Chống nháy mà không thêm độ trễ cảm nhận được: nếu phiên xác nhận trong
200ms thì tổng thời gian chờ vẫn là 200ms chứ không phải 1 giây. Ngưỡng tối đa 1s là
**trần**, không phải độ trờ cố định.

**Alternatives considered**:
- *Chỉ hiện splash khi kiểm tra phiên chậm hơn 1s* — tránh thoáng qua, nhưng làm
  SC-002 khó kiểm thứ và thêm nhánh rẽ điều kiện. Đã bị loại.
- *Luôn hiện tối thiểu 1 giây* — thêm độ trờ vô ích. Đã bị loại.

> ⚠ Cần đo lại trên máy thật ở T041 (nguy cơ đã ghi trong spec).

---

## R4. `ClosyNetworkImage` vỡ ảnh không phải do URL

**Question**: Ảnh gợi ý "không xem được" — do URL sai hay do parse sai?

**Finding**: **Do parse sai**, nhưng còn một lớp lỗi thứ hai.

Tầng parse sai đã xác định: FE đọc `data['items']` như danh sách phẳng, BE trả danh
sách nhóm. Nhưng kể cả khi URL rỗng, `ClosyNetworkImage` cũng **không** báo lỗi mà lặng
lẽ rơi về biểu tượng (`closy_network_image.dart:85-87` `_activeUrl.isEmpty` →
`_buildFallback()`). Đó là lý do lỗi này bị báo "không xem được" chứ không phải "lỗi ảnh".

Lớp lỗi thứ hai: fallback ứng dụng nhúng sẵn 3 URL Unsplash
(`stylist_repository.dart:265,273,...`). Ở môi trường không có mạng ra ngoài hoặc bị
chặn, ảnh này cũng không tải được.

**Decision**: Sửa tầng parse (R5). Đồng thời `ClosyNetworkImage` không đổi — hành vi
im lặng hiện tại là chủ ý và đúng cho 20+ call site khác. Việc "món không có ảnh thì
hiện nhãn vai trò" làm ở tầng widget gợi ý, không sửa widget ảnh dùng chung.

**Alternatives considered**: *Thêm `onError` callback vào `ClosyNetworkImage`* — lan toả
26 call site, vi phạm phạm vi. Loại.

---

## R5. Hợp đồng gợi ý: dùng lại model đúng đã có

**Finding**: Repo đã có bộ model khớp **chính xác** hợp đồng BE, dùng cho màn AI
Outfit Studio:

`lib/features/outfit_studio/models/outfit_models.dart`
- `RecommendedOutfitRes` → `{title, explanation, items, isFallback, remainingQuota}`
- `RecommendedItemGroup` → `{role, primary, alternatives}`
- `RecommendedItemRes` → `{id, itemContext, fashionItem | brandItem}`
- `RecommendedFashionItemBrief` → `{id, category, imageUrl, color, colorHex, style}`

Đối chiếu BE `dto/recommendation.go:28-56` — khớp từng trường, kể cả
`imageUrl`, `isFallback`, `remainingQuota`.

Trong khi đó `stylist_models.dart` có một bộ model **song song, sai hợp đồng** chỉ dùng
cho stylist.

**Decision**: `stylist_repository.getOutfitRecommendation()` chuyển sang parse bằng
`RecommendedOutfitRes`, rồi **làm phẳng** sang model hiển thị của stylist
(`primary` + `alternatives` → một danh sách phẳng có `imageUrl` thật).

**Rationale**: Làm phẳng giữ nguyên `_buildLookbookCarousel` (`stylist_screen.dart:646`)
và dữ liệu `suggestedItems` mà provider đang gán — thay đổi nhỏ nhất đạt SC-005.
Không cần sửa UI cho tới khi thêm nhãn vai trò.

**Alternatives considered**:
- *Xoá bộ model cũ, dùng thẳng cấu trúc nhóm trong UI* — sửa nhiều widget, rủi ro cao hơn, không thêm giá trị v1. Loại.
- *Chỉ vá `imageUrl`* — vẫn giữ cấu trúc sai, khó bảo trì. Loại (đã bị user loại ở clarify).

---

## R6. Vai trò: bảng đóng, và bảng FE đang **thiếu mục**

**Finding**: Từ điển vai trò đầy đủ của BE (`mapper/recommendation.go:32-46`):

| slug danh mục | vai trò BE |
|---|---|
| `ao` | `top` |
| `quan`, `chan-vay` | `bottom` |
| `dam` | `fullbody` |
| `ao-khoac` | `outerwear` |
| `giay` | `footwear` |
| `mu` | `headwear` |
| `phu-kien` | `accessory` |
| *(khác)* | `other` |

Bảng đang có ở FE (`outfit_models.dart:127-143`) **thiếu `headwear`**, và rơi xuống
`role.toUpperCase()` → hiển thị chữ `OTHER` cho người dùng.

**Decision**: Ánh xạ đóng 8 giá trị trên sang tiếng Việt trong ứng dụng; lạ thì hiển
thị nguyên chuỗi gốc (FR-032). Bổ sung `headwear` và `other`.

**Rationale**: Trả lời đúng cho câu hỏi clarify Q3, và tránh phụ thuộc việc BE có
trường nhãn riêng — **đã kiểm tra, BE không có** (`RecommendedItemGroup` chỉ có
`Role string`, không có trường nhãn).

---

## R7. Điều kiện kích hoạt gợi ý — phát hiện lớn nhất

**Question**: Thay heuristic `contains('phối') || contains('outfit')` bằng gì?

**Finding**: Prompt của BE (`chat/helper.go:33-46`) **đảo ngược** logic mà ứng dụng đang
hiểu:

```go
if len(brandItems) > 0 || len(fashionItemMap) > 0 {
    builder.WriteString("- Do not append '[ACTION:REDIRECT_OUTFIT]'.\n")
} else {
    builder.WriteString("- append '[ACTION:REDIRECT_OUTFIT]' at the very end.\n")
}
```

Nghĩa là:
- **Tủ đồ CÓ món** → AI trả lời **trực tiếp trong văn bản**, ghi tên món in đậm, và
  **cố ý không** phát marker.
- **Tủ đồ RỖNG** → mới phát `[ACTION:REDIRECT_OUTFIT]` để mời sang endpoint gợi ý.

Marker **có thật** và BE có phát ra — xác nhận ở `fashion_ai_handler.go` và
`chat/helper.go`, không phải bịa của ứng dụng.

BE còn có sẵn bộ khoá nhận diện (`chat/helper.go:16`):
```
tu do|ao|quan|vay|chan vay|dam|giay|ao-khoac|ao khoac|do cua|mac|phoi|style|gu|mac gi|goi y|bo do|do
```
sau khi bỏ dấu tiếng Việt và hạ chữ thường, và có xét cả 2 tin nhắn gần nhất.

**Vấn đề của hiện trạng**: `stylist_provider.dart:250` kích hoạt gọi endpoint khi
prompt có chữ `phối` — **kể cả khi tủ đồ đã có món và BE đã tự trả lời đầy đủ**. Kết
quả: nội dung bị lặp và gợi ý không khớp tủ đồ → đúng cảm giác "AI không chính xác".

**Decision**: Hai điều kiện song song —
1. Marker `[ACTION:REDIRECT_OUTFIT]` do BE phát → luôn gọi endpoint.
2. Không có marker nhưng câu khớp bộ khoá BE (dựng lại cùng cách: bỏ dấu, hạ chữ
   thường) → vẫn gọi endpoint, để giữ tính năng thẻ ảnh khi tủ đồ có món.

**Rationale**: Bỏ nhánh (2) sẽ **xóa hẳn** thẻ ảnh với mọi người dùng có tủ đồ — đúng
một thứ người dùng đang yêu cầu. Thay vì giữ chữ `phối` thiểu, dựng lại bộ khoá theo
đúng bộ BE dùng để tránh lệch; và bỏ phần `contains('outfit')` vốn khớp cả từ tiếng
Anh trong câu hỏi không liên quan.

**Alternatives considered**:
- *Chỉ dựa vào marker* — loại bỏ thẻ ảnh khi tủ đồ có món. Loại, vi phạm SC-005 nếu hiểu theo nghĩa người dùng.
- *Giữ `contains('phối')`* — quá hẹp, ví dụ "mặc gì cho đi làm", "áo gì đẹp", "mix đồ". Loại.

---

## R8. `ChatMessageModel` đọc trường BE không hồi

**Finding**: `dto/chat.go:32-37` — `ChatMessageRes` chỉ có 4 trường:
`{id, sender, content, createdAt}`. Không có `outfitRecommendation`, không có
`suggestedItems`.

`stylist_models.dart:161-175` vẫn đọc cả hai → luôn `null` / rỗng. Nói cách khác phần
gợi ý trong lịch sử chat **không bao giờ** khôi phục được, dù có thể từng hiện.

**Decision**: Bỏ hai nhánh tra cứu đó khỏi `fromJson`. Ghi rõ trong data-model rằng lịch
sử tải lại **chỉ có văn bản**; thẻ gợi ý chỉ tồn tại trong phiên đang mở.

**Rationale**: Tuân thủ FR-024. Giữ lại nhánh chết chỉ tạo cảm giác "tính năng lỗi".

**Hệ quả cần chấp nhận**: Người dùng tải lại trang web sẽ không thấy thẻ gời ở tin nhắn
cũ. Đây là giới hạn của máy chủ, đã đưa vào Edge Cases của spec.

---

## R9. Bỏ `catch (_) {}` — nguyên nhân lỗi bị giấu

**Finding**: `stylist_provider.dart:252` và `:268` dùng `catch (_) {}` trần. Không có
log. Người dùng và người phát triển đều không thấy lỗi.

**Decision**: Bắt và ghi log có tiền tố nhận dạng (theo đúng quy ước sẵn có
`[StylistRepository]` / `[StylistNotifier]` trong cùng feature), kèm nội dung lỗi.

**Rationale**: FR-022/FR-023 yêu cầu thông báo thay vì thay nội dung sai; FR-025 yêu
cầu chẩn đoán được. Hai nhánh này là chỗ duy nhất nuốt lỗi trong luồng gợi ý.

**Rủi ro đã nêu ở spec**: lỗi trước đây bị che sẽ lộ ra. Đây là hành vi đúng.

---

## R10. Tràn viền Up bài — đã khớp số đo runtime

**Finding**: `post_composer_screen.dart:425-458`. `Row` + `spaceBetween` chứa một
`Text` không có ràng buộc co giãn và một `Row` lồng chứa hai `TextButton.icon`. Tổng bề
rộng cố định vượt khung ở viewport hẹp.

Đối chiếu log runtime thu được khi chạy web:
```
A RenderFlex overflowed by 66 pixels on the bottom.
A RenderFlex overflowed by 67 pixels on the right.
```
Khớp với ảnh người dùng gửi. Chỉ sửa đúng một chỗ (scope đã chốt ở clarify).

**Decision**: Nhãn → `Flexible` + `ellipsis`; cụm nút `Row` → `Wrap` để tự xuống dòng.
Không thay `ListView`, không thu nhỏ font.

**Alternatives considered**:
- *Thu nhỏ font khi hẹp* — phá nhất quán thị giác Quiet Luxury. Loại.
- *Chỉ bọc `Expanded`* — hai nút vẫn tràn ngang. Loại.

---

## Kết luận Technical Context

Không còn `NEEDS CLARIFICATION`. Các quyết định còn mở cho tầng triển khai:
vị trí đặt widget splash dùng chung, và cách gom thẻ vai trò — đều là chi tiết cấu trúc,
không ảnh hưởng hợp đồng hay tiêu chí nghiệm thu.