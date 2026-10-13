# Contract — Hiển thị tin nhắn Stylist AI dạng Markdown

**Feature**: `016-tester-feedback-fixes` · **Owner**: mobile client · **BE**: không sửa

## Phạm vi

Màn Stylist (`lib/features/stylist/presentation/stylist_screen.dart`, `_buildMessageBubble`)
render nội dung tin nhắn Markdown thay vì `Text` thô.

## Hợp đồng hiển thị (FR-009)

Với mỗi tin nhắn `ChatMessageModel`:

- Nguồn chuỗi = `msg.cleanContent` (đã bỏ marker `[ACTION:REDIRECT_OUTFIT]`).
- Chuỗi MUST render qua Markdown renderer (`MarkdownBody` của `flutter_markdown_plus`).
- Cú pháp MUST hỗ trợ tối thiểu: **đậm**, *nghiêng*, tiêu đề, danh sách gạch đầu dòng/đánh số,
  liên kết, mã inline, khối mã.
- Áp dụng cho cả tin đang stream (`isStreaming == true`) và tin hoàn tất.
- Khi `cleanContent` rỗng và đang stream → hiển thị "Đang suy nghĩ..." (giữ hành vi cũ).
- Văn bản thuần / Markdown không hợp lệ MUST vẫn hiển thị an toàn (không ném lỗi).

## Style (Quiet Luxury)

- Body/label: **Be Vietnam Pro**; heading dùng **Playfair Display**.
- Màu chữ: user `#1A1A1A`; AI `AppColors.textPrimary`. Nền bong bóng giữ nguyên
  (`#E5D5C5` cho user, `AppColors.surface` cho AI).
- Liên kết dùng màu `AppColors.primary`; khối mã nền trung tính, không dùng `Colors.blue/red`.
- Không dùng `Image.network` cho ảnh trong Markdown list (không áp dụng ở chat).

## Ngoài phạm vi

- Không đổi nguồn nội dung từ BE; không parse `outfitRecommendation`/`suggestedItems` từ lịch
  sử (đã chốt ở spec 015 R8).
- Không thêm LaTeX/Mermaid (không cần cho chat Closy).

## Tiêu chí kiểm chứng

1. AI trả lời có `**đậm**`/danh sách → hiển thị đúng định dạng, **không** còn ký tự `**`, `#`, `-` thô.
2. Trong lúc stream, phần đã nhận vẫn hiển thị định dạng, không crash/nhấp nháy lỗi.
3. Văn bản thuần vẫn đọc bình thường.

## Test

`test/stylist_markdown_render_test.dart` (mới) — nội dung có cú pháp phải render, không lộ
ký tự thô.
