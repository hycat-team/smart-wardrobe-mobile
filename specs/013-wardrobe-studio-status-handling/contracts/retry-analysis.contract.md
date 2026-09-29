# Contract: retry-analysis (mobile)

Nguồn: BE `023-analyze-status-handling/frontend-guide.md` §3 + `contracts/api-contracts.md`. Mobile tuân thủ, không sửa BE.

## Endpoint

`POST /api/v1/wardrobe-items/{id}/retry-analysis`

## Request

| Field | Type | Bắt buộc | Ghi chú |
|---|---|---|---|
| `categoryId` | `string (uuid)` | **Có**, khi item `needsReview` | Danh mục đã chọn; thiếu ⇒ BE 400 |
| `categoryId` | `string (uuid)` | Không, khi `failed` lỗi tạm thời | Body có thể rỗng |

Cấm: `POST /wardrobe-items/{id}/confirm-review` (đã gỡ, 404).

## Response thành công

```json
{
  "success": true,
  "message": "Yêu cầu phân tích lại trang phục đã được gửi thành công",
  "data": { "id": "uuid", "status": 3, "isLocked": false, "taskId": "uuid",
    "fashionItem": { "id": "uuid", "category": { "id": "uuid", "name": "Áo", "slug": "ao" },
      "imageUrl": "...", "reviewReason": null } }
}
```

`data.status = 3` (processing) + `taskId` mới → mobile subscribe SSE như luồng upload.

## Lỗi (message BE hiển thị trực tiếp)

| HTTP | Khi nào | Mobile làm gì |
|---|---|---|
| 400 | `needsReview` thiếu/sai `categoryId` | Báo "vui lòng chọn danh mục", giữ màn review |
| 400 | Retry khi `processing`/đã dùng được | Chặn client-side trước (không gọi) |
| 400 | `multiple_items_detected` / `full_body_outfit_detected` | Không gọi retry (ẩn nút); hướng dẫn ảnh khác |
| 404 | Gọi `confirm-review` cũ | Không bao giờ gọi |

## SSE sau retry

Payload `{ itemId, status, total, index, data, error }`; `error` là mã khi `failed`.
`needs_review` ⇒ `data.fashionItem.reviewReason = uncertain_category`.
