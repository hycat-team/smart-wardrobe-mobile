# Phase 1 Data Model: Community Home, Bulk Add & System Catalog Admin

**Feature**: `012-community-nav-catalog` | **Date**: 2026-09-27

Không tạo entity/bảng mới ở BE. Dưới đây là cấu trúc dữ liệu/state phía app bị ảnh hưởng.

## 1. Điều hướng — NavTab (cấu hình trình bày)

| # | Slug route | Nhãn hiển thị | Icon |
|---|---|---|---|
| 0 | `/wardrobe` | Tủ đồ | `Icons.checkroom_*` |
| 1 | `/community` | Cộng đồng | `Icons.public` / `Icons.public_outlined` |
| 2 | `/studio` | Phối đồ AI | `Icons.auto_awesome_*` (hero) |
| 3 | `/stylist` | Stylist AI | `Icons.chat_bubble_*` |
| 4 | `/profile` | Hồ sơ | `Icons.person_*` |

- **Bỏ** tab Home; route `/home` → redirect `/community`. `initialLocation`/tab mặc định sau login = `/community`.

## 2. UploadWardrobeState (mở rộng cho nạp nhiều)

| Field | Type | Ghi chú |
|---|---|---|
| `isUploading` | `bool` | còn ảnh đang tải |
| `isAnalyzing` | `bool` | đang chờ AI (giữ nguyên) |
| `progress` | `double` | tiến trình tổng (0..1) |
| `batchTotal` | `int` | tổng số ảnh chọn |
| `batchCompleted` | `int` | số ảnh đã đăng thành công |
| `failedFiles` | `List<XFile>` | ảnh lỗi để thử lại |
| `isSuccess` | `bool` | tất cả thành công |
| `errorMessage` | `String?` | lỗi (một phần/toàn bộ) |

- **Quy tắc**: mỗi ảnh xử lý độc lập; lỗi 1 ảnh không chặn ảnh khác; tiến trình = `batchCompleted/batchTotal`; giới hạn theo hạn mức gói còn lại.

## 3. SystemCatalogItem (áp quy tắc hiển thị)

| Field liên quan | Ý nghĩa | Quy tắc |
|---|---|---|
| `imageUrl` (từ `fashionItem.displayImageUrl`/`imageUrl`) | ảnh món mẫu | **Ẩn/không cho thêm** nếu rỗng |
| `category`, `id` | danh mục, id | giữ nguyên |
| `price?` | giá gợi ý | giữ nguyên |

- **Quy tắc**: `isSelectable = imageUrl != null && imageUrl.isNotEmpty`. Món không hợp lệ bị lọc khỏi grid và khỏi `selectedIds`.
- **Ghi chú BE**: 3 món `ao/quan/giay` hiện thiếu ảnh → cần dữ liệu BE bổ sung để thêm được.

## 4. Phiên đăng nhập Google (quy tắc định danh)

- Mỗi lần bắt đầu đăng nhập Google: **clear phiên cục bộ** (token/user/state) + **signOut Google SDK** → chọn tài khoản → idToken → `POST /auth/google` → lưu token (ghi đè).
- Bất biến: `sessionProvider` bump khi đổi/đăng xuất để dispose scope tài khoản cũ; dữ liệu (tủ đồ/hồ sơ) phải khớp user mới.

## 5. Chuỗi hiển thị cần Việt hoá (inventory — trích)

| Vị trí | Hiện tại (EN) | Sau (VI) |
|---|---|---|
| Bottom nav | Home / Wardrobe / AI Outfit / AI Chat / Profile | Tủ đồ / Cộng đồng / Phối đồ AI / Stylist AI / Hồ sơ |
| `wardrobe_screen` app bar | Digital Closet | Tủ đồ số |
| `marketplace_screen` | Search curate pieces, brands… / Retry | Tìm sản phẩm, thương hiệu… / Thử lại |
| (rà thêm) | empty/error/loading ở các màn | tiếng Việt |

- Giữ nguyên: tên thương hiệu/model (Closy, THE ROW, LEMAIRE…), URL, route, key.

## State transitions

```text
Nav: [Wardrobe, Community, Studio, Stylist, Profile]; /home -> /community.
Upload batch: idle -> picking(n) -> uploading (per-file, progress) -> done | partial(failedFiles)
Catalog: item hasImage ? selectable : hidden.
Google login: start -> clearSession+signOut -> chooseAccount -> exchange -> session(user mới)
```

**Output**: sẵn sàng cho `/speckit.tasks`.
