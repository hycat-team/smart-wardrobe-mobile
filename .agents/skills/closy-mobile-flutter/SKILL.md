---
name: closy-mobile-flutter
description: Closy Smart Wardrobe mobile conventions — Flutter 3.x + Riverpod + GoRouter + Dio, Quiet Luxury design tokens, API/SSE workflows, and mandatory gotchas from PROJECT_AGENT_GUIDE.md. Use for any mobile UI, feature, or bugfix work in smart-wardrobe-mobile.
---

# Closy Mobile Flutter Skill

Project: `smart-wardrobe-mobile` (Flutter 3.x, Dart 3.x, Riverpod 2.x, GoRouter 14.x).
Source of truth: `D:\Project\smart-wardrobe\PROJECT_AGENT_GUIDE.md` + `lib/`.

## 1. Stack — luôn dùng đúng

- State: `flutter_riverpod` (`StateNotifierProvider`, `FutureProvider`). Không dùng setState rải rác cho business logic.
- Routing: `go_router` + `ShellRoute` + `BottomNavigationBar` (xem `lib/core/router/`).
- Network: `Dio` + Bearer Interceptor, header bắt buộc `Accept-Encoding: identity` (chống nuốt lỗi Gzip backend — Gotcha 2 trong guide).
- Realtime: SSE streaming qua `http.Client`, xem `features/wardrobe` (upload + polling) và `features/stylist` (chat).
- Storage: `flutter_secure_storage` cho access token. Validate JWT đủ 3 phần `header.payload.signature` trước khi lưu.
- Test web: `flutter run -d chrome --web-port=8081`. CORS BE đã allow `localhost:8081`, `localhost:3000`.

## 2. Quiet Luxury tokens (bắt buộc)

- Nền: `#FAFAFA` / `#F8F6F0` (Beige/Sand Tint). Text tối: `#111111`. Accent: `#D9C5B2`. Border: `#E5E2DE`.
- Typography: Serif (Playfair Display tương đương) cho tiêu đề + Sans (Be Vietnam Pro tương đương, qua `google_fonts`) cho body.
- Lưới tủ đồ: 2 cột, card bo mềm, ảnh tách nền Cloudinary (`t_bg_remove`).
- BottomSheet/menu trượt: luôn bọc `Column` trong `SingleChildScrollView` (chống tràn 47px RenderFlex — Gotcha 4).
- `ListTile` trong `Container` có màu nền: luôn bọc `Material(color: Colors.transparent, borderRadius:..., clipBehavior: Clip.antiAlias, child: ListTile(...))` (Gotcha 3).

## 3. API base & endpoints trọng yếu

- BE: `http://localhost:8080/api/v1`. Auth: `Authorization: Bearer <token>` hoặc `?token=` cho SSE.
- KHÔNG gọi `GET /wardrobe-items/me` (Gin nhầm `me` thành `:id`). Luôn `GET /me/wardrobe-items` (Gotcha 1).
- SSE: `${baseUrl}/wardrobe-items/tasks/$taskId/sse?token=$token` (Gotcha 2). Kèm Safety Polling `GET /me/wardrobe-items` mỗi 3s, tối đa 12 lần.
- Upload flow: `GET /wardrobe-items/upload-signature` → POST Cloudinary → `POST /wardrobe-items/batch-upload` → chèn Optimistic item `status: 3` lên đầu lưới → SSE/polling cập nhật.
- Subscription/PayOS: description `<= 25 ký tự`, format `CLOSY #<orderCode> <amount>`.

## 4. Encoding tiếng Việt trên Windows

- Không dùng `Set-Content` / redirect `>` PowerShell cho file có dấu (vỡ thành Windows-1252). Dùng Node `fs.writeFileSync(file, content, 'utf8')`.

## 5. Khi nào dùng skill khác (đã cài trong `.agents/skills/`)

- `imagegen-frontend-mobile`: vẽ mockup/flow màn hình mobile trước khi code. Chỉ sinh ảnh, không code.
- `ui-ux-pro-max`: quyết định layout, color, typography, touch target >= 44px, check a11y. Stack Flutter được hỗ trợ chính thức.
- `brandkit`, `design-taste-frontend`, `stitch-design-taste`, `minimalist-ui`, `high-end-visual-design`, `gpt-taste`: định hướng thẩm mỹ, giữ đồng nhất Quiet Luxury.
- `image-to-code`: chuyển mockup đã duyệt thành widget Flutter.
- `redesign-existing-projects`, `impeccable`, `baseline-ui`, `frontend-design`, `theme-factory`: redesign/polish màn hình có sẵn.
- `gemini-api-dev`: BE/Stylist dùng Gemini — mobile chỉ gọi qua BE endpoint, không nhúng key vào app.
- `security-best-practices`: review auth, token storage, input.
- `full-output-enforcement`: không rút gọn output khi sinh multi-file.
- `codegraph`: tra cứu cấu trúc `lib/core|features|shared` (Riverpod providers, Dio services, GoRouter). Chạy `codegraph init` + `codegraph sync` trong `smart-wardrobe-mobile/` để tạo index riêng, không copy db từ FE.
- `speckit-*` + `.specify/`: quy trình spec-driven (`specify → clarify → plan → tasks → implement`). Dùng cho tính năng mới (ví dụ `features/marketplace`).

## 6. Definition of Done cho mỗi task mobile

1. Chạy được `flutter analyze` sạch lỗi mới thêm.
2. Không vi phạm 6 Gotchas trong PROJECT_AGENT_GUIDE.md.
3. Màn hình mới tuân thủ tokens mục 2 + safe-area + bottom-nav hiện có.
4. Luồng upload/SSE (nếu chạm wardrobe/stylist) giữ Optimistic UI + SSE + polling dự phòng.
