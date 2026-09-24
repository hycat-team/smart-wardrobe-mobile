# AGENTS.md — Smart Wardrobe Mobile (Closy)

> File vận hành bắt buộc cho mọi AI Agent làm việc trong repo `smart-wardrobe-mobile`.
> Đọc file này trước mọi task. Tuân thủ workflow bên dưới, không tự ý rút gọn.

## 1. Hồ sơ repo

- **App:** Smart Wardrobe / ClosY — Quiet Luxury AI Stylist + Digital Closet.
- **Framework:** Flutter 3.x / Dart 3.x (`sdk: '>=3.0.0 <4.0.0'`).
- **State:** `flutter_riverpod ^2.5.1` (`StateNotifierProvider`, `FutureProvider`, `StateProvider`). Không dùng `setState` cho business logic.
- **Routing:** `go_router ^14.2.0` + `ShellRoute` + BottomNav 5 tabs (`lib/core/router/app_router.dart`).
- **Network:** `dio ^5.4.3` + Bearer interceptor (`lib/core/network/`). Realtime SSE qua `http.Client`.
- **Storage:** `flutter_secure_storage` cho token. Validate JWT đủ 3 phần `header.payload.signature` trước khi lưu.
- **Fonts/Media:** `google_fonts` (Playfair Display + Be Vietnam Pro), `cached_network_image`, `image_picker`, `app_links`, `url_launcher`.
- **Kiến trúc:** Feature-First Layered: `lib/core/` (dùng chung) → `lib/features/<domain>/{data,models,presentation,providers}/` → `lib/shared/widgets/`.

```
lib/
├── core/{config,constants,network,router,services,session,storage,theme,deeplink}/
├── features/{auth,home,onboarding,wardrobe,outfit_studio,stylist,marketplace,profile}/
├── shared/widgets/   # closy_network_image.dart, scaffold_with_nav_bar.dart, stats_bar_chart.dart
└── main.dart         # ProviderScope + session-keyed rescope + PaymentDeepLinkObserver
```

## 2. Tài liệu bắt buộc đọc (theo thứ tự)

1. `D:\Project\smart-wardrobe\PROJECT_AGENT_GUIDE.md` — sự thật trung tâm monorepo (BE Go :8080, FE :3000, gotcha 1–6, API matrix, upload dual-sync).
2. `docs/AI_DEVELOPMENT_GUIDE.md` — chuẩn code mobile, palette, checklist bàn giao.
3. `.agents/skills/closy-mobile-flutter/SKILL.md` — tokens + API/SSE + Definition of Done mobile.
4. `docs/work-log-2026-09-19.md` — ngữ cảnh phiên gần nhất (spec 008 deploy Play, spec 009 stats, việc còn dở cần user).
5. Spec liên quan trong `specs/<nnn-ten-feature>/` (`spec.md`, `plan.md`, `tasks.md`, `research.md`, `quickstart.md`).

Không sửa BE/FE từ repo này. Không nhúng API key Gemini vào app — mobile chỉ gọi qua BE endpoint.

## 3. Lệnh chuẩn

```powershell
flutter pub get
flutter analyze                    # phải 0 issues trước khi bàn giao
flutter test
flutter run -d chrome --web-port=8081   # CORS BE đã allow 8081 + 3000; R = hot restart
flutter build apk --debug
flutter run --dart-define=ENABLE_PAID_FEATURES=true  # hiện Ví/Gói hội viên (mặc định release ẩn)
```

- Test account: `user / 123456`; brand/admin: `brand_admin` hoặc `admin / 123456`.
- BE local (mobile): `http://localhost:5000/api/v1` (web/desktop) hoặc `http://10.0.2.2:5000/api/v1` (Android emulator) — cấu hình qua `.env`/`--dart-define=API_BASE_URL`. Đối chiếu thêm PROJECT_AGENT_GUIDE §4 (ma trận endpoint, port Docker 8080→map).
- Giữ `kotlin.incremental=false` trong `android/gradle.properties` (lỗi KT-66598 trên Windows).

## 4. WORKFLOW BẮT BUỘC (Spec-Driven)

Mọi feature/fix > 1 file **phải** đi qua pipeline speckit. Không nhảy cóc sang code.

```
specify → clarify → plan → tasks → analyze → implement → verify
```

| Bước | Skill / output | Quy tắc |
|---|---|---|
| `specify` | `speckit-specify` → `specs/<nnn-slug>/spec.md` | Ghi user story (P1/P2/P3), FR, SC có số. Nếu app đã có màn tương tự (VD `/wardrobe/insights`), hỏi phạm vi trước khi tạo màn mới. |
| `clarify` | `speckit-clarify` → sửa `spec.md` | Hỏi tối đa 5 câu, chốt điểm mơ hồ (nguồn dữ liệu, entry point, phạm vi v1). Ghi quyết định vào spec. |
| `plan` | `speckit-plan` → `plan.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md` | Xác minh API thật trên BE repo trước khi chốt (VD `wearCount` hardcode 0 → fallback ẩn chỉ số). Không bịa endpoint. |
| `tasks` | `speckit-tasks` → `tasks.md` | Task phụ thuộc có thứ tự, chia Setup / Foundational / US1..n / Polish. Mỗi task trỏ file cụ thể. |
| `analyze` | `speckit-analyze` | Kiểm tra coverage FR↔task, mâu thuẫn (VD deep-link trong checklist khi cờ paid tắt). Sửa spec/plan/tasks trước khi code. |
| `implement` | `speckit-implement` | Làm theo thứ tự tasks, đánh dấu xong từng task. Viết work-log vào `docs/work-log-<yyyy-mm-dd>.md`. |
| `verify` | DoD §7 | `flutter analyze` sạch + test liên quan + QS pass trên máy thật (nếu UI). |

- Fix nhỏ 1 file: được bỏ qua specify, nhưng vẫn ghi 1 dòng vào work-log ngày.
- Không commit/push/PR trừ khi user yêu cầu rõ. File chưa commit thì liệt kê trong work-log.
- Secrets (`*.jks`, `*.keystore`, `key.properties`, `.env`) không bao giờ commit — đã chặn trong `.gitignore`.

## 5. Chuẩn code (tóm tắt, chi tiết xem AI_DEVELOPMENT_GUIDE §4)

- **No mock khi đã có API:** mọi nghiệp vụ đi `Repository → Dio (ApiClient) → BE`.
- **Null-safety state:** field mới trong State class phải có default hoặc getter nullable-safe (`_q` + `get q => _q ?? ''`) — chống `TypeError Null is not String` khi hot reload web.
- **`ref.watch`** trong `build`, **`ref.read(notifier)`** trong `onPressed/onTap`.
- **Ảnh mạng:** cấm `Image.network` cho list/grid. Bắt buộc `ClosyNetworkImage` + `memCacheWidth/Height` (~300). List cuộn dùng `AutomaticKeepAliveClientMixin`.
- **Quiet Luxury:** nền `#FAF8F5`, surface `#FFFFFF`, accent `#E6DEC9`/`#B8A99A`, chữ `#1A1A1A`, viền `#E8E3DC`. Cấm `Colors.red/blue` thuần. Title: Playfair Display; body/label/button: Be Vietnam Pro.
- **BottomSheet sticky:** `DraggableScrollableSheet` + `CustomScrollView` + `SliverPersistentHeader(pinned:true)` + `ClipRRect` chống lẹm góc.
- **BottomSheet nhỏ:** bọc `Column` trong `SingleChildScrollView` (chống tràn 47px).
- **`ListTile` trong `Container` màu nền:** bọc `Material(color: transparent, borderRadius, clipBehavior: Clip.antiAlias, child: ListTile(...))`.
- **Dio:** luôn gửi `Accept-Encoding: identity` (chống nuốt lỗi Gzip BE).
- **API tủ đồ:** chỉ `GET /me/wardrobe-items`, cấm `GET /wardrobe-items/me` (Gin nhầm `me` thành `:id`).
- **SSE:** `${baseUrl}/wardrobe-items/tasks/$taskId/sse?token=$token` + polling dự phòng `GET /me/wardrobe-items` mỗi 3s × 12. Upload flow: signature → Cloudinary (`t_bg_remove`) → batch-upload → optimistic item `status: 3` → SSE/polling cập nhật.
- **PayOS:** `description <= 25 ký tự`, format `CLOSY #<orderCode> <amount>`.
- **Form:** phải có loading indicator + lỗi rõ qua `SnackBar`/Dialog. Xong flow thì điều hướng GoRouter hợp lý (VD tạo outfit → `/outfits`).

## 6. Gotcha Windows (bắt buộc)

- **Mojibake tiếng Việt:** PowerShell 5.1 mặc định ANSI. Cấm `(Get-Content …) -replace … | Set-Content …` và redirect `>`. Chỉ dùng tool `edit`/`write`, hoặc `Get-Content -Encoding utf8 … | … | Set-Content -Encoding utf8`.
- Tool `bash` chạy PowerShell 5.1: nối lệnh phụ thuộc bằng `cmd1; if ($?) { cmd2 }`, không dùng `&&` hay `head`. Đổi thư mục bằng tham số `workdir`, không `cd` trong lệnh.

## 7. Definition of Done / Pre-flight

- [ ] `flutter analyze` — 0 issues mới.
- [ ] Không vi phạm 6 gotcha PROJECT_AGENT_GUIDE + chuẩn §5 ở trên.
- [ ] Tiếng Việt không mojibake; ảnh qua `ClosyNetworkImage`; form có loading + lỗi.
- [ ] Route/Deep-link/Release flag đúng (`ENABLE_PAID_FEATURES`, ẩn Ví + chặn 4 route + bỏ qua deep-link PayOS khi tắt).
- [ ] `flutter test` liên quan pass; integration fail phải chứng minh pre-existing (stash test) như mẫu spec 009.
- [ ] Cập nhật `docs/work-log-<date>.md` (spec nào, task nào xong/còn, file mới/sửa, việc cần user).

## 8. Điều phối skill (đã cài trong `.agents/skills/`)

- Mọi task mobile load `closy-mobile-flutter` trước.
- Vẽ mockup trước code: `imagegen-frontend-mobile` (chỉ sinh ảnh). Mockup→code: `image-to-code`.
- Layout/a11y/touch ≥44px: `ui-ux-pro-max`. Thẩm mỹ Quiet Luxury: `minimalist-ui`, `high-end-visual-design`, `brandkit`, `design-taste-frontend`, `stitch-design-taste`, `gpt-taste`.
- Polish màn có sẵn: `redesign-existing-projects`, `impeccable`, `baseline-ui`, `frontend-design`, `theme-factory`.
- Auth/token/input review: `security-best-practices`. Sinh multi-file không rút gọn: `full-output-enforcement`.
- Truy cấu cấu trúc lib (provider/service/route): `codegraph` — chạy `codegraph init` + `codegraph sync` tại repo này, không copy db từ FE.
- Gemini/BE: `gemini-api-dev` — mobile chỉ gọi qua BE, không nhúng key.
- Tính năng mới: pipeline `speckit-*` + `.specify/` (§4).
