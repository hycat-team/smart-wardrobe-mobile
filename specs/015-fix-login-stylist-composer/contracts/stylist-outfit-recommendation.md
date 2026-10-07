# Contract: Hợp đồng đọc dữ liệu gợi ý phối đồ

**Phạm vi**: hợp đồng mà ứng dụng **đọc**. Máy chủ **không** được sửa (hiến pháp VI).

---

## 1. Nguồn: `POST /ai/outfit-recommendations`

### Yêu cầu

```json
{ "prompt": "gợi ý phối đồ cho đi làm", "occasion": "casual" }
```

- `occasion` tuỳ chọn.
- Thời gian chờ dài: máy chủ có thể gọi mô hình ngôn ngữ. Ứng dụng đặt
  connect 120s / receive 120s.

### Phản hồi

```json
{
  "data": {
    "title": "Bộ phối công sở tối giản",
    "explanation": "Áo sơ mi trắng kết hợp quần âu...",
    "isFallback": false,
    "remainingQuota": 4,
    "items": [
      {
        "role": "top",
        "primary": {
          "id": "…uuid…",
          "itemContext": "user_wardrobe",
          "fashionItem": {
            "id": "…uuid…",
            "category": { "id": "…", "name": "Áo sơ mi", "slug": "ao-so-mi" },
            "imageUrl": "https://res.cloudinary.com/…/upload/t_bg_remove/…jpg",
            "color": "Trắng",
            "colorHex": "#FFFFFF",
            "style": "formal"
          }
        },
        "alternatives": [
          { "id": "…", "itemContext": "user_wardrobe",
            "fashionItem": { "imageUrl": "https://…", "color": "Be" } }
        ]
      },
      {
        "role": "footwear",
        "primary": {
          "id": "…",
          "itemContext": "brand",
          "brandItem": { "imageUrl": "https://…", "color": "Đen", "brandName": "…",
                         "price": 2_400_000 }
        }
      }
    ]
  }
}
```

### Ba điểm dễ sai đã ghi nhận

1. **`items` là danh sách NHÓM theo vai trò**, không phải danh sách phẳng món đồ.
   Mỗi nhóm có `primary` + `alternatives`, và món nằm ở `fashionItem` hoặc `brandItem`.
2. **`imageUrl` không nằm ở cấp nhóm hay cấp món**, mà nằm sâu trong
   `fashionItem.imageUrl` / `brandItem.imageUrl`.
3. **`brandItem` thay thế `fashionItem`**, không phải thêm bên cạnh. Món chỉ có một
   trong hai.

> Bản ứng dụng hiện tại đọc `data.items[i].imageUrl` — ở cấp sai, nên luôn rỗng.
> Đây là nguyên nhân gốc của "gợi ý ra hình ảnh không xem được".

### Ngữ nghĩa hai cờ

| Cờ | Ý nghĩa | Hành vi ứng dụng |
|---|---|---|
| `isFallback: false` | Gợi ý thật từ mô hình + tủ đồ | Hiển thị như gợi ý chuẩn |
| `isFallback: true` | Máy chủ tự sinh (thường khi **hết hạn mức**) | Hiển thị **kèm nhãn "gợi ý dự phòng"** (FR-029) |
| `remainingQuota: 0` | Đã cạn | Hiện số hạn mức còn lại + hướng dẫn (FR-030) |

Phân biệt bắt buộc với **danh sách tự chế của ứng dụng** (dữ liệu Unsplash nhúng sẵn) —
loại này sẽ bị **gỡ khỏi luồng**, không phải "đánh dấu dự phòng" (FR-023).

---

## 2. Nguồn: `POST /ai/chat/sessions/{id}/messages` (stream SSE)

### Phản hồi

Máy chủ trả về `ChatMessageRes` — **chỉ 4 trường**:

```json
{
  "id": "…uuid…",
  "sender": "ASSISTANT",
  "content": "…văn bản, có thể chứa [ACTION:REDIRECT_OUTFIT]…",
  "createdAt": "2026-10-02T09:00:00Z"
}
```

**Không có** `outfitRecommendation`. **Không có** `suggestedItems`.
→ Ứng dụng không được tra hai trường đó (FR-024, R8).

### Marker điều hướng

`[ACTION:REDIRECT_OUTFIT]` — dạng hợp lệ, do máy chủ chủ động phát, không phải
ký hiệu bịa. Quy tắc phát, trích nguyên văn từ prompt máy chủ
(`chat/helper.go:33-46`):

| Tình trạng tủ đồ + món thương hiệu | Hành vi máy chủ |
|---|---|
| **Có** món | AI trả lời trực tiếp trong văn bản, tên món in đậm, và **KHÔNG** phát marker |
| **Rỗng** | AI yêu cầu ứng dụng gọi endpoint gợi ý qua marker |

Hệ quả thiết kế: marker **không** xuất hiện với người dùng có tủ đồ. Ứng dụng vẫn
gọi endpoint khi câu hỏi khớp bộ khoá để vẫn hiện thẻ ảnh (xem R7).

Marker phải được **loại khỏi văn bản hiển thị** cho người dùng.

---

## 3. Hợp đồng trạng thái phiên

Không có endpoint mới. Hợp đồng nằm ở hành vi quan sát được.

### `GET /me`

| Mã | Ý nghĩa | Hành vi ứng dụng |
|---|---|---|
| `200` | Token hợp lệ | Vào app, giữ phiên |
| `401` / `403` | Token không còn hợp lệ | **Xoá phiên**, hiện màn đăng nhập (FR-028) |
| `5xx` | Lỗi máy chủ | **Giữ phiên**, báo tạm thời (FR-027) |
| *(không phản hồi)* | Lỗi mạng / timeout | **Giữ phiên**, báo tạm thời (FR-027) |

> Cơ chế làm mới token đã có sẵn trong bộ chặn của ứng dụng: gặp `401` sẽ thử làm mới
> một lần, chỉ đăng xuất tự động khi làm mới **thất bại**. Vì vậy nhánh "token hợp lệ"
> ở trên là sau khi đã làm mới.

Ràng buộc bắt buộc: phải lấy mã trạng thái từ đối tượng lỗi gốc. Bọc lỗi thành chuỗi
thông báo sẽ phá vỡ hợp đồng này (R1).

---

## 4. Hợp đồng hiển thị dải media (màn Up bài)

Không có hợp đồng API. Hợp đồng là bố cục:

| Thuộc tính | Yêu cầu |
|---|---|
| Nhãn đếm số tệp | luôn hiển thị đủ, không bao giờ bị cắt mất |
| Nút "Thêm ảnh" | bấm được ở mọi bề rộng cửa sổ |
| Nút "Thêm video" | bấm được ở mọi bề rộng cửa sổ |
| Khi đã đủ 10 tệp | cả hai nút khoá, bộ đếm hiện `(10/10)` |
| Bề rộng ≥ 300px | không tràn viền ở bất kỳ bề rộng nào (FR-012) |