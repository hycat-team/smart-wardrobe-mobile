# Contract — Tìm kiếm Community (thay đổi client)

**Feature**: `016-tester-feedback-fixes` · **Owner**: mobile client · **BE**: không sửa

## Phạm vi

Màn tìm kiếm Community (`lib/features/community/presentation/community_search_screen.dart`)
gỡ hàng lọc **loại bài** (`Tất cả bài / Bộ phối / Ảnh/Video`). Client không còn gửi bộ lọc
loại bài; kết quả gồm mọi loại.

## Hàng lọc còn lại (không đổi)

Hàng segmented chọn **phạm vi**: `Tất cả` (`all`) · `Tác giả` (`users`) · `Bài viết` (`posts`).

## Request tới máy chủ (qua `CommunitySearchRepository.searchCommunity`)

```
GET  {baseUrl}/community/search
params:
  q           = <từ khoá>                 # bắt buộc khi có ngữ cảnh tìm
  type        = all | users | posts       # theo hàng segmented
  postType    = <KHÔNG gửi>               # <-- thay đổi: luôn bỏ qua (null)
  page, limit
```

- `postType` **MUST** được truyền `null`/bỏ hẳn; UI không còn khả năng đặt `outfit`/`media`.
- `loadMorePosts` cũng **MUST NOT** gửi `postType`.
- Máy chủ vẫn có thể hỗ trợ tham số này; việc bỏ là quyết định phía client.

## Tiêu chí kiểm chứng

1. Màn tìm kiếm ở tab `Bài viết` **không** hiển thị chip `Tất cả bài`/`Bộ phối`/`Ảnh/Video`.
2. Kết quả trả về gồm cả bài bộ phối lẫn bài ảnh/video.
3. Không phát sinh request chứa `postType` khi tìm kiếm.

## Test bị ảnh hưởng

`test/community_search_filter_test.dart` — các assert hàng 2 phải đổi thành assert **không
tồn tại** (`findsNothing`).
