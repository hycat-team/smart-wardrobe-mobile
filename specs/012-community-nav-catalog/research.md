# Phase 0 Research: Community Home, Bulk Add & System Catalog Admin

**Feature**: `012-community-nav-catalog` | **Date**: 2026-09-27

---

## R1 — Đổi điều hướng: Home → Community, swap với Wardrobe

- **Decision**: Sửa `ScaffoldWithNavBar` còn **5 tab** theo thứ tự **[Tủ đồ, Cộng đồng, Phối đồ AI, Stylist AI, Hồ sơ]** (bỏ Home). Trong `app_router.dart`: bỏ branch `/home` khỏi `StatefulShellRoute`, thêm `GoRoute('/home', redirect: '/community')` để deep-link cũ không lỗi; giữ `/community` + `/users/:username`.
- **Rationale**: Đúng yêu cầu; Home ẩn hoàn toàn nhưng route cũ vẫn an toàn; `initialLocation`/guard không đổi.
- **Alternatives considered**: Giữ Home làm route ẩn không redirect (deep-link sẽ 404) — loại; thêm Community thành tab 6 (quá tải nav) — loại.

## R2 — Nạp nhiều ảnh cùng lúc vào tủ đồ

- **Decision**: Dùng `ImagePicker.pickMultiImage(...)` (giới hạn theo ảnh hợp lệ) → với **mỗi ảnh**: signature (`/wardrobe-items/upload-signature`) → Cloudinary → `batchUploadWardrobeItems([...])`; thêm optimistic item + theo dõi SSE như hiện có. `UploadWardrobeState` mở rộng: `total`, `completed`, `failed`, `isBatch`. UI hiển thị tiến trình `x/N`; ảnh lỗi giữ lại để thử lại, không chặn ảnh khác.
- **Rationale**: Tái dùng `CloudinaryService` + `batch-upload` + optimistic/SSE sẵn có; `pickMultiImage` là API chuẩn của `image_picker`.
- **Alternatives considered**: Tách nhiều call `pickImage` liên tiếp (UX kém); upload tuần tự chặn UI (loại).

## R3 — Tủ đồ hệ thống thiếu ảnh

- **Decision**: Trong `system_catalog_provider`/`system_catalog_screen`, **lọc bỏ món có ảnh rỗng** (`displayImageUrl`/`imageUrl` empty) khỏi danh sách hiển thị và không cho thêm. Đồng thời ghi chú **BE cần bổ sung ảnh** cho 3 món mẫu (`ao/quan/giay`) — việc dữ liệu nằm phía BE.
- **Rationale**: Spec Q1=A (giữ tính năng); tránh thêm món trắng vào tủ.
- **Alternatives considered**: Bỏ hẳn tính năng (Q1=B — đã loại); hiển thị món thiếu ảnh kèm placeholder (vẫn gây nhầm) — loại.

## R4 — Fix Google login: nhiều tài khoản GG vào cùng 1 tài khoản

- **Decision**: Trước khi đăng nhập Google, **buộc chọn lại tài khoản + xoá phiên cục bộ**:
  1. Trong `google_sign_in_button.dart`: gọi `GoogleSignIn.instance.signOut()` (và cân nhắc `disconnect()`) **trước** `authenticate()`/luồng GIS để mở lại account chooser.
  2. Trong `AuthNotifier.loginWithGoogle`: **xoá state/token cũ** trước khi bắt đầu (tái dùng `logout()`/`clearAll`) để không tái dùng phiên tài khoản trước khi trao đổi thất bại.
  3. Sau khi có idToken mới → `POST /auth/google` → lưu token **ghi đè**; `getCurrentUser()` trả đúng user mới.
- **Rationale**: Triệu chứng "nhiều tài khoản GG vào cùng 1 tài khoản" khớp việc SDK tái dùng tài khoản Google đã cấp quyền (không hỏi lại) và/hoặc phiên cũ còn trong bộ nhớ. Buộc signOut + clear session đảm bảo mỗi lần đăng nhập là tài khoản được chọn.
- **Alternatives considered**: Chỉ dựa vào account chooser mặc định (không đủ — SDK có thể auto-chọn) ; xoá app data (không phải giải pháp).
- **Cần xác minh khi implement**: hành vi `signOut()` trên Web (GIS) và trên Android; nếu Web auto-fill tài khoản, thêm bước buộc hiển thị chọn tài khoản.

## R5 — Việt hoá toàn bộ UI

- **Decision**: Thay **chuỗi hiển thị** tiếng Anh → tiếng Việt trực tiếp trong code (không thêm framework i18n). Ưu tiên: `scaffold_with_nav_bar` (nhãn tab), `wardrobe_screen` (`Digital Closet`), `marketplace_screen` (`Search...`, `Retry`), và rà các màn khác. Giữ nguyên tên riêng/thương hiệu/model.
- **Rationale**: App đơn ngôn ngữ (tiếng Việt); thêm i18n framework là overkill cho v1.
- **Alternatives considered**: `intl`/`flutter_localizations` + ARB (nặng, chưa cần) — loại v1; để sau nếu cần đa ngôn ngữ.

## R6 — Router/guard & hồi quy

- **Decision**: `/home` → redirect `/community`; tab mặc định sau đăng nhập = `/community`; giữ `pendingRedirect`, guard auth, các route paid/privacy như cũ. `isPublicCommunityPage` vẫn đúng. Bỏ `HomeScreen` khỏi nav (giữ file nếu còn dùng, hoặc xoá nếu không tham chiếu).
- **Rationale**: Không phá deep-link/guard.
- **Alternatives considered**: Xoá hẳn route `/home` (deep-link cũ sẽ lỗi) — loại.

---

**Output**: Tất cả `NEEDS CLARIFICATION` đã giải quyết; sẵn sàng Phase 1.

---

## Inventory (T001/T002/T003/T004)

### Tab hiện tại → mục tiêu (nav bar)

| Index | Hiện tại (EN) | Mục tiêu (VI) | Icon |
|---|---|---|---|
| 0 | Home | **Tủ đồ** (Wardrobe branch) | `checkroom` |
| 1 | Wardrobe | **Cộng đồng** (Community branch) | `public` |
| 2 | AI Outfit (center hero) | **Phối đồ AI** | `auto_awesome` |
| 3 | AI Chat | **Stylist AI** | `chat_bubble` |
| 4 | Profile | **Hồ sơ** | `person` |

- Route: `/home` có branch riêng → **bỏ branch**, thêm `GoRoute('/home', redirect → '/community')`.
- `kPostLoginRoute`: `/home` → **`/community`**.
- `/community` trước đây là route top-level → **chuyển thành branch 1** của `StatefulShellRoute`; các route con (`/community/posts/:publicId`, `/community/create`, `/community/search`) vẫn top-level.
- Guard: `isPublicCommunityPage` đã bao `'/community'` → guest xem được feed qua tab.

### Chuỗi EN cần Việt hoá (hiển thị cho người dùng)

- `scaffold_with_nav_bar.dart`: `Home`, `Wardrobe`, `AI Outfit`, `AI Chat`, `Profile` → đã đổi ở T005.
- `wardrobe_screen.dart`: `Digital Closet` → "Tủ đồ số"; các nhãn filter/`Retry` tiếng Anh.
- `marketplace_screen.dart`: `Search...`, `Retry`.
- `auth/**`, `outfit_studio/**`, `stylist/**`, `profile/**`, `wardrobe/item_*`: rà `Text('...')`/`hintText`/`label` còn EN.
- **Giữ nguyên**: tên thương hiệu/model (ClosY, AI Stylist, PayOS, Cloudinary...).

### Xác nhận dependency (T002) — không thêm package

- `image_picker 1.2.3`: có `Future<List<XFile>> pickMultiImage({...})` ✔.
- `google_sign_in`: có `Future<void> signOut()` và `Future<void> disconnect()` ✔.

### Cơ chế phiên (T003)

- `lib/core/session/session_provider.dart`: `sessionProvider` (StateProvider<int>) sống ở root `ProviderScope`; `main.dart` rescope provider con theo `session-key`.
- `AuthNotifier.logout()`: gọi `_repository.logout()` rồi `sessionProvider.notifier).state++` **chỉ khi** `hadSession` → toàn bộ provider user (profile/wardrobe/subscription...) bị dispose & tạo lại.
- Áp dụng cho US5: trước `loginWithGoogle`, clear phiên cũ (logout/clear token + AuthState) để user B không kế thừa state của A.

