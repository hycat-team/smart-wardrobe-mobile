# Quickstart — Validate 005-studio-canvas-positions

**Prereqs**: app on emulator, test account, backend running (AI suggestion needs quota).

## QS-001 — Set AI 3 món cơ bản (US1)

1. Studio → tab AI → xin gợi ý (occasion casual) → `Nạp lên canvas`.
2. ✅ Pass: áo trên / quần giữa-dưới / giày dưới cùng, tách rời, gọn trong khung, không kéo tay.

## QS-002 — Set AI có áo khoác/mũ/phụ kiện (US1)

1. Xin gợi ý có outerwear/headwear (occasion party/work + ghi chú) → nạp canvas.
2. ✅ Pass: 0 món nằm chồng ở chính giữa; mỗi món có vị trí riêng nhìn rõ được.

## QS-003 — Mở lại outfit đã lưu (US2)

1. Dàn tay 3 món → lưu outfit → sang tab khác → `Tủ Outfit` → `Mở Trên Studio`.
2. ✅ Pass: bố cục trùng lúc lưu (vị trí + lớp); kéo 1 món → lưu → mở lại → giữ bố cục mới.

## QS-004 — Outfit 1 món + legacy (0,0) (US2)

1. Lưu outfit chỉ 1 món → mở lại → ✅ món ở giữa khung, không kẹt mép.
2. (Nếu có) Mở outfit cũ lưu trước bản fix → ✅ tự dàn lại theo vai trò, không chồng đống.

## QS-005 — Ghi đè + hồi quy

1. Canvas đang có đồ dở → nạp set AI → ✅ dialog hỏi Ghi đè/Giữ lại; Giữ lại → đồ cũ nguyên vẹn.
2. Kéo/phóng/đổi lớp/lưu/xóa món trên canvas vẫn đúng như cũ (20 lượt liên tiếp không lỗi).

## QS-006 — Khác kích thước màn hình

1. Mở cùng outfit trên emulator khác size (hoặc xoay màn hình nếu hỗ trợ) → ✅ mọi món trong khung nhìn.
