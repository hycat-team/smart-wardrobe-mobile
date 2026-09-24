# Contract: Statistics Data & UI

**Feature**: specs/009-add-stats-screen
**Date**: 2026-09-19
**Type**: Data/API contract + UI state contract
**Consumers**: `/speckit-tasks`, mobile dev, backend (khi bổ sung trường)

## D1 — Endpoint (kỳ vọng, cần xác minh ở A0/FR-014)

Tái dùng namespace dashboard hiện có. Đề xuất một trong hai:

```text
GET /me/dashboard/wardrobe-statistics
```

hoặc mở rộng `/me/dashboard/wardrobe-insights`.

### Trường bắt buộc tối thiểu (chắc chắn có)

| Trường | Kiểu | Dùng cho |
|---|---|---|
| totalItems | int | UtilizationMetric |
| totalWardrobeValueVnd | number | ValueMetric |
| underutilizedItems[].lastWornDaysAgo | int | mốc 30/60/90 |
| categories[].{categoryId,categoryName,itemCount,valueVnd} | — | phân bổ/giá trị |
| outfits.totalOutfits | int | OutfitStat |

### Trường CẦN xác minh/bổ sung (nếu thiếu → fallback)

| Trường | Kiểu | Dùng cho | Nếu thiếu |
|---|---|---|---|
| wearCount | int | CostPerWear | Ẩn cost-per-wear |
| wearHistory[].{month,wearCount} | — | TimeTrendPoint | Ẩn biểu đồ xu hướng |
| purchasePriceVnd | number | CostPerWear | Ẩn cost-per-wear cho món đó |

**Quy tắc fallback**: nếu thiếu trường bắt buộc cho một chỉ số, KHÔNG hiển thị số ước lượng thay thế; hiển thị ghi chú "Chưa có dữ liệu" và ẩn chỉ số đó.

## D2 — Công thức chỉ số (chuẩn hoá, testable)

```text
utilizationRate = totalItems == 0 ? 0 : (totalItems - unused30) / totalItems
unused30/60/90  = count(items where lastWornDaysAgo >= 30/60/90)
costPerWear     = wearCount == 0 ? null : purchasePriceVnd / wearCount
trend           = group wearHistory by month, lấy 6 tháng gần nhất
```

## D3 — UI state contract

| Trạng thái | Điều kiện | Hiển thị |
|---|---|---|
| Loading | đang tải | spinner màu chủ đạo |
| Empty | `totalItems == 0` | minh hoạ + hướng dẫn thêm món |
| Error | gọi API lỗi | thông báo thân thiện + nút "Thử lại" |
| Partial | `wearDataAvailable == false` | ẩn cost-per-wear/xu hướng + ghi chú |
| Data | có dữ liệu | 4 section theo thứ tự a→d |
| Refreshing | kéo làm mới | `RefreshIndicator` |

## D4 — Bố cục màn hình (thứ tự section)

1. Tổng quan: tổng món, tỷ lệ sử dụng (hero card).
2. Mức độ sử dụng: món ít mặc 30/60/90 ngày.
3. Giá trị: tổng giá trị, giá trị theo danh mục, cost-per-wear.
4. Outfit: tổng/đã dùng.
5. Xu hướng: biểu đồ cột theo tháng 6 tháng.

## D5 — Ràng buộc phi chức năng

- Không thêm dependency runtime; biểu đồ dùng `CustomPainter`.
- Chỉ hiển thị dữ liệu của người dùng đang đăng nhập.
- Đọc rõ ở cả chế độ sáng/tối; nội dung tiếng Việt.
- Màn `/wardrobe/insights` cũ không bị ảnh hưởng (không sửa hành vi).
