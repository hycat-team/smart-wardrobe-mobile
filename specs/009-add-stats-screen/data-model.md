# Data Model: Statistics Screen

**Feature**: specs/009-add-stats-screen
**Date**: 2026-09-19
**Note**: Mô hình chỉ số hiển thị ở màn Thống kê; nguồn dữ liệu từ dashboard API (xem `contracts/stats-data.md`).

## StatsBundle

Gói dữ liệu tổng hợp cho màn hình.

| Field | Kiểu | Ràng buộc |
|---|---|---|
| utilization | UtilizationMetric | bắt buộc |
| value | ValueMetric | bắt buộc |
| outfits | OutfitStat | bắt buộc |
| trend | List\<TimeTrendPoint\> | có thể rỗng (chưa đủ dữ liệu) |
| wearDataAvailable | bool | false → ẩn cost-per-wear + xu hướng (FR-014) |

**Validation**: `totalItems >= 0`; nếu `totalItems == 0` → trạng thái rỗng toàn màn.

## UtilizationMetric

| Field | Kiểu | Ràng buộc |
|---|---|---|
| totalItems | int | `>= 0` |
| unused30 | int | `<= totalItems` |
| unused60 | int | `<= totalItems` |
| unused90 | int | `<= totalItems` |
| utilizationRate | double | 0.0–1.0; `(totalItems - unused30) / totalItems`; `totalItems==0` → 0.0 (không chia 0) |

## ValueMetric

| Field | Kiểu | Ràng buộc |
|---|---|---|
| totalValueVnd | double | `>= 0`; chỉ cộng món có giá |
| byCategory | List\<CategoryValue\> | có thể rỗng |
| missingPriceCount | int | `>= 0`; số món thiếu giá (chú thích) |

### CategoryValue

| Field | Kiểu | Ràng buộc |
|---|---|---|
| categoryId | string | |
| categoryName | string | |
| valueVnd | double | `>= 0` |
| itemCount | int | `>= 0` |

## CostPerWear

| Field | Kiểu | Ràng buộc |
|---|---|---|
| itemId | string | |
| name | string | |
| purchasePriceVnd | double | `>= 0` |
| wearCount | int | `>= 0` |
| costPerWear | double? | `null` khi `wearCount == 0` (hiển thị "Chưa mặc"); ngược lại `purchasePriceVnd / wearCount` |

**State transitions**: không có; chỉ số dẫn xuất, tính lại mỗi lần tải.

## OutfitStat

| Field | Kiểu | Ràng buộc |
|---|---|---|
| totalOutfits | int | `>= 0` |
| usedOutfits | int | `<= totalOutfits` (nếu API cung cấp) |

## TimeTrendPoint

| Field | Kiểu | Ràng buộc |
|---|---|---|
| month | string | định dạng `YYYY-MM` |
| wearCount | int | `>= 0` |
| bucketStart | DateTime | tháng đầu của kỳ |

**Quy tắc**: tối đa 6 điểm gần nhất; nếu `< 2` điểm có dữ liệu → hiển thị "chưa đủ dữ liệu" (không vẽ biểu đồ).

## Trạng thái màn hình

`loading` → `data` (có thể `empty`) | `error`.
- `empty`: `totalItems == 0` → minh hoạ + hướng dẫn thêm món.
- `error`: thông báo thân thiện + nút "Thử lại".
- `wearDataAvailable == false`: ẩn cost-per-wear/xu hướng + ghi chú lý do.
