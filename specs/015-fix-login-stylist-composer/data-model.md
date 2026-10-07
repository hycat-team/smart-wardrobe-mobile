# Data Model: 015-fix-login-stylist-composer

Ba mô hình dữ liệu thay đổi. Tất cả thuộc phạm vi ứng dụng; máy chủ giữ nguyên.

---

## 1. Trạng thái phiên đăng nhập

Nguồn: [spec.md](./spec.md) FR-001, FR-026…FR-028 · Quyết định R1, R2

### Trước

```
isLoading        bool   (chỉ dùng cho nút đăng nhập)
isAuthenticated  bool   (mặc định false)
user             UserModel?
errorMessage     String?
successMessage   String?
```

### Sau

Thêm **hai** trường, đều có mặc định:

| Trường | Kiểu | Mặc định | Ý nghĩa |
|---|---|---|---|
| `isCheckingAuth` | `bool` | `true` | Đang kiểm tra phiên. Cũng là cờ quyết định có áp dụng ngưỡng 1 giây của splash hay không. |
| `authCheckFailed` | `bool` | `false` | Kiểm tra lỗi tạm thời (mạng / máy chủ) nhưng token **chưa** bị từ chối. Phiên được giữ, người dùng ở lại splash chờ bấm "Thử lại". |

Các trường còn lại giữ nguyên tên và mặc định.

> **Bắt buộc** (hiến pháp II): trường mới **phải có giá trị mặc định** để chống
> `TypeError: Null is not a subtype of bool` khi hot reload web vài giữa chừng.

### Chuyển trạng thái — bốn trạng thái (FR-001)

```
                  khởi động app
                        │
                        ▼
              ┌──────────────────────┐
              │  isCheckingAuth=true │   ① ĐANG KIỂM TRA
              │  authCheckFailed=f   │   (chưa biết)
              │  isAuthenticated=?   │
              └──────────┬───────────┘
                         │
        ┌────────────────┼──────────────────┐
        │                │                  │
  có token +        có token +         không có token
  GET /me OK        lỗi TẠM THỜI      hoặc token bị từ chối
        │                │                  │
        ▼                ▼                  ▼
   ② ĐÃ ĐĂNG NHẬP   ③ LỖI TẠM THỜI    ④ CHƯA ĐĂNG NHẬP

isCheckingAuth    isCheckingAuth    isCheckingAuth =false
 =false           =false            authCheckFailed =false
authCheckFailed   authCheckFailed   isAuthenticated=false
 =false           =TRUE             → màn đăng nhập
isAuthenticated   isAuthenticated
 =true            =true  GIỮ PHIÊN
                  + ở lại splash
                  + nút "Thử lại"

   ③ ──bấm "Thử lại"──▶ quay về ①
   ③ ──máy chủ từ chối token──▶ ④
   ① ──không có token──▶ ④
```

Quy tắc rẽ nhánh (R1) — dựa trên **mã trạng thái HTTP**, không so chuỗi thông báo:

| Tình huống | Hành động |
|---|---|
| `DioException` **không có** `response` (lỗi mạng, timeout, hủy kết nối) | **Giữ phiên** → trạng thái ③. `authCheckFailed = true` |
| `response.statusCode` là 401 / 403 | **Xoá phiên** → trạng thái ④. Dọn bộ nhớ |
| `response.statusCode` là 5xx | **Giữ phiên** → trạng thái ③ |
| Không phải `DioException` | **Giữ phiên** → trạng thái ③ + ghi log (không đoán) |

### Ràng buộc

- `isCheckingAuth` phải về `false` trong **`finally`**, không phải chỉ khi thành công
  (FR-002) — nếu không, một lỗi bất ngờ sẽ kẹt người dùng ở splash vĩnh viễn.
- `AppRouterNotifier` phải phát tín hiệu khi **bất kỳ** cờ nào trong
  `isCheckingAuth` / `authCheckFailed` / `isAuthenticated` đổi. Nếu chỉ so
  `isAuthenticated`, splash biến mất nhưng router không được đánh giá lại.
- Ngưỡng 1 giây của splash **chỉ áp dụng ở trạng thái ①**. Ở trạng thái ③ splash ở lại
  chờ người dùng bấm "Thử lại", không tự ẩn (SC-002).
- **Không có cơ chế tự thử lại theo thời gian** ở bất kỳ trạng thái nào (FR-035).
  Chỉ lời gọi tường minh từ nút "Thử lại" mới được phép phát sinh yêu cầu.

### Chỉ hiện splash khi khởi động ứng dụng, không hiện khi đổi phiên (FR-003, SC-011)

Đăng xuất và chuyển tài khoản Google đều gọi `bumpAppSession()` + tăng
`sessionProvider`, khiến `main.dart` đổi `ValueKey` của `ProviderScope` → **mọi provider
bị dispose và tạo lại** → `AuthNotifier` mới → `isCheckingAuth` trở về mặc định `true`.
Nếu không xử lý, splash sẽ nháy giữa phiên mỗi lần đổi tài khoản.

Yêu cầu hành vi: `isCheckingAuth` chỉ bắt đầu ở `true` **ở lần kiểm tra phiên đầu tiên
của tiến trình**. Từ lần thứ hai trở đi (do đổi phiên) nó phải bắt đầu ở `false`, và
`authCheckFailed` bắt đầu ở `false`.

| Sự kiện | `isCheckingAuth` ban đầu | Splash hiện? |
|---|---|---|
| Khởi động app / F5 (lần đầu tiên trong tiến trình) | `true` | ✅ Có |
| Đăng xuất giữa phiên | `false` | ❌ Không |
| Chuyển tài khoản Google giữa phiên | `false` | ❌ Không |
| Bấm "Thử lại" ở trạng thái ③ | `true` | ✅ Có (giữ nguyên splash) |

> Cơ chế cụ thể (cờ ở cấp thư viện hay cấp ứng dụng) là chi tiết triển khai — xem T008
> trong `tasks.md`. Ràng buộc cần giữ: phải **sống sót** việc dispose `ProviderScope`, nên
> không lưu trong một provider thường.

---

## 2. Gợi ý phối đồ từ stylist

Nguồn: FR-016…FR-020, FR-029…FR-032 · Quyết định R5, R6, R7, R8

### Dữ liệu máy chủ trả về (giữ nguyên, không sửa)

```
RecommendedOutfitRes
├── title            string
├── explanation      string
├── isFallback       bool     ← máy chủ tự sinh khi hết hạn mức
├── remainingQuota   int
└── items[]          RecommendedItemGroup          ← NHÓM theo vai trò
    ├── role         string   (top | bottom | fullbody | outerwear
    │                         | footwear | headwear | accessory | other)
    ├── primary      RecommendedItemRes
    │   ├── id           uuid
    │   ├── itemContext  string  (user_wardrobe | brand)
    │   ├── fashionItem  { id, category{name}, imageUrl, color, colorHex, style }
    │   └── brandItem    { ...cùng hình dạng... }
    └── alternatives[] RecommendedItemRes
```

### Mô hình trong ứng dụng sau khi sửa

Tái dùng nguyên vẹn bộ model đã có sẵn trong `outfit_studio/models/outfit_models.dart`
để đọc. Chỉ cần **một** bước làm phẳng cho tầng hiển thị.

> **Đính chính sau clarify (2026-10-02)**: bản ghi đầu tiên của mục này định nghĩa hai
> type mới `StylistOutfitSuggestion` / `StylistSuggestionItem`. Người dùng đã chốt
> **mở rộng model stylist sẵn có** thay vì tạo bộ model thứ hai — theo FR-034
> (cấm hai bộ mô hình song song mô tả cùng một kết quả).

**Dùng lại bộ model sẵn có của stylist**, mở rộng thêm ba trường (FR-033):

```
OutfitRecommendationModel            (đã có, thêm 2 trường)
├── id, title, occasion
├── explanation, weatherContext
├── tags
├── isFallback       bool    ← MỚI, từ máy chủ (FR-029)
├── remainingQuota   int     ← MỚI, từ máy chủ (FR-030)
└── items[]          OutfitRecommendationItem

OutfitRecommendationItem             (đã có, thêm 1 trường)
├── id               String   đã có, bắt buộc khác rỗng (FR-017)
├── title            String   đã có, bắt buộc khác rỗng (FR-017)
├── brand, category, color, price   đã có
├── imageUrl         String?  đã có, có thể null → hiện nhãn vai trò (FR-019)
└── role             String?  ← MỚI, nguyên chuỗi máy chủ trả về
    roleLabelVi      getter   ← MỚI, tra bảng ánh xạ đóng
```

Cờ `isFallback` và số `remainingQuota` nằm ở **cấp bộ gợi ý**, còn `role` nằm ở
**cấp món** — đúng vị trí máy chủ trả về. Không tạo type mới nào.

`roleLabelVi` là **getter** gọi tới bảng ánh xạ đóng dùng chung (xem bảng bên dưới) —
không phải một bảng riêng, để không sinh ra nguồn nhãn thứ hai.

### Quy tắc làm phẳng

1. Duyệt `items[]` theo thứ tự nhận.
2. Với mỗi nhóm: lấy `primary` trước, rồi `alternatives` theo thứ tự.
3. **Món thiếu cả `fashionItem` lẫn `brandItem`** → **bỏ qua hẳn**, không tạo thẻ rỗng
   (đây là nguyên nhân gốc: thẻ rỗng khiến ảnh "không xem được").
4. Món có `imageUrl` rỗng → **giữ lại** thẻ, `imageUrl = null`, UI hiện nhãn vai trò.
5. `title` lấy từ tên danh mục lồng trong; nếu thiếu thì dùng `roleLabelVi`.

### Bảng ánh xạ vai trò (đóng — 8 giá trị, xác minh từ `mapper/recommendation.go:32-46`)

| Vai trò BE | Nhãn tiếng Việt |
|---|---|
| `top` | Áo |
| `bottom` | Quần / Váy |
| `fullbody` | Váy liền / Đầm |
| `outerwear` | Áo khoác |
| `footwear` | Giày dép |
| `headwear` | Mũ / Nón |
| `accessory` | Phụ kiện |
| `other` | Món khác |
| *(không có trong bảng)* | **nguyên chuỗi gốc** (FR-032) |

> Bảng đang có ở `outfit_models.dart:127-143` **thiếu `headwear`** và rơi xuống
> `toUpperCase()` nên hiển thị chữ `OTHER` cho người dùng. Phải bổ sung.

### Trường loại bỏ

`ChatMessageModel.fromJson` **xoá** hai nhánh tra `outfitRecommendation` và
`suggestedItems`. Máy chủ `ChatMessageRes` chỉ có `{id, sender, content, createdAt}` —
không có hai trường đó (R8).

**Hệ quả cần chấp nhận**: lịch sử chat tải lại chỉ có văn bản; thẻ gợi ý chỉ sống trong
phiên đang mở. Đã ghi ở Edge Cases của spec.

### Điều kiện kích hoạt

```
gọi endpoint gợi ý  ⟺  có marker [ACTION:REDIRECT_OUTFIT]
                       ∨ câu hỏi khớp bộ khoá từ BE
```

Bộ khoá (sao chép từ `chat/helper.go:16`, khớp sau khi **bỏ dấu tiếng Việt** và **hạ chữ thường**):

```
tu do | ao | quan | vay | chan vay | dam | giay | ao-khoac | ao khoac
      | do cua | mac | phoi | style | gu | mac gi | goi y | bo do | do
```

Bỏ hẳn `contains('outfit')` của bản hiện tại — khớp cả từ tiếng Anh trong câu không
liên quan (R7).

---

## 3. Bố cục dải media ở màn Up bài

Nguồn: FR-012…FR-015 · Quyết định R10

Không có mô hình dữ liệu mới. Chỉ là thay đổi ràng buộc kích thước:

| Thành phần | Ràng buộc cũ | Ràng buộc mới |
|---|---|---|
| Nhãn "HÌNH ẢNH & VIDEO (n/10)" | chiều rộng tự nhiên, không co | co giãn được, cắt bằng dấu `…` khi hẹp |
| Cụm nút "Thêm ảnh" / "Thêm video" | xếp ngang cố định | tự xuống dòng khi không đủ chỗ |

Giữ nguyên: giới hạn 10 tệp, định dạng chấp nhận, giới hạn dung lượng, và trạng thái
khoá khi đã đủ 10 tệp (FR-015).