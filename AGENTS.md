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
6. `.specify/memory/constitution.md` — hiến pháp dự án (đã seed theo AGENTS.md/AI guide); mọi `/speckit.plan`/`analyze` phải tuân thủ.

Không sửa BE/FE từ repo này. Không nhúng API key Gemini vào app — mobile chỉ gọi qua BE endpoint.

### 2.1 Ảnh store KHÔNG được đặt trong `assets/`

Screenshot/icon/feature graphic chỉ dùng để upload lên Play Console, **không
dùng trong app**. Đặt vào `assets/` sẽ bị đóng gói vào **mọi** bản build
(8 ảnh screenshot tốn ~1 MB thừa mỗi lần phát hành).

Vị trí đúng: `store-assets/`
- `phone-screenshots/closy-screenshot-N.jpg` — ảnh đã chuẩn hoá cho Play.
- `play-icon-512.png`, `play-feature-graphic-1024x500.png` — tài nguyên bắt buộc.
- `raw/` — ảnh gốc chụp từ máy, giữ lại để sinh lại.

Sinh lại: `tool/prep_store_screenshots.ps1`, `tool/prep_store_graphics.ps1`.

**Quy tắc Play đã kiểm tra (screenshot điện thoại):** cạnh dài **không được
vượt 2× cạnh ngắn**. Ảnh 1080×2400 (tỉ lệ 2,22) sẽ bị **từ chối**. Script
đã cắt status bar + nới 2 bên để đạt đúng 2:1. Ngoài ra Play khuyến nghị
"không hiện thông báo của nhà cung cấp khác" trên status bar.


## 3. Lệnh chuẩn

> **Ưu tiên `make`** — `Makefile` ở root gom sẵn `--dart-define` cho từng môi
> trường, tránh quên biến (đặc biệt `--dart-define=API_BASE_URL`). `make help`
> liệt kê đích. Ba lệnh chính:
>
> | Lệnh | Việc |
> |---|---|
> | `make run` | web trên **Edge**, port 8081, mở sẵn trình duyệt |
> | `make dev` | chạy trên thiết bị thật / emulator (`DEVICE=android`) |
> | `make build` | APK + AAB **production** rồi `verify` — lệnh phát hành |
>
> Ghi đè biến: `make run WEB_PORT=9000 BROWSER=chrome`, hoặc
> `make apk DEV_API=http://10.0.2.2:5000/api/v1` (emulator).
>
> Lệnh `flutter` thô bên dưới vẫn dùng được — khi cần cờ chưa có target
> (VD `--dart-define=ENABLE_PAID_FEATURES=true`).

```powershell
flutter pub get
flutter analyze                    # phải 0 issues trước khi bàn giao
flutter test

# ⚠ `.env` KHÔNG còn nằm trong `assets` (gỡ ở §10 để không lộ cấu hình
# production trong .aab). Vì vậy mọi lệnh `flutter run` phải truyền
# --dart-define; nếu thiếu, app rơi về fallback localhost + cloud `demo`
# (ảnh upload sẽ hỏng).
$env:API = 'http://localhost:5000/api/v1'
$env:CLD = 'dzvwkngxu'

flutter run -d chrome --web-port=8081 `
  --dart-define=API_BASE_URL=$env:API `
  --dart-define=CLOUDINARY_CLOUD_NAME=$env:CLD   # CORS BE đã allow 8081 + 3000; R = hot restart

# Android emulator: API_BASE_URL_ANDROID trỏ 10.0.2.2 (alias host của máy host)
flutter run `
  --dart-define=API_BASE_URL=$env:API `
  --dart-define=API_BASE_URL_ANDROID=http://10.0.2.2:5000/api/v1 `
  --dart-define=CLOUDINARY_CLOUD_NAME=$env:CLD

flutter build apk --debug
flutter run --dart-define=ENABLE_PAID_FEATURES=true  # hiện Ví/Gói hội viên (mặc định release ẩn)
```

- Test account: `user / 123456`; brand/admin: `brand_admin` hoặc `admin / 123456`.
- BE local (mobile): `http://localhost:5000/api/v1` (web/desktop) hoặc `http://10.0.2.2:5000/api/v1` (Android emulator) — **luôn truyền qua `--dart-define`**, không còn đọc `.env`. Đối chiếu thêm PROJECT_AGENT_GUIDE §4 (ma trận endpoint, port Docker 8080→map).
- Giữ `kotlin.incremental=false` trong `android/gradle.properties` (lỗi KT-66598 trên Windows).
- Build phát hành Google Play: xem `docs/Release_Play_Checklist.md` mục 2 (cần `android/key.properties` + upload keystore).

## 4. WORKFLOW BẮT BUỘC (Spec-Driven — GitHub Spec Kit)

Mọi feature/fix > 1 file **phải** đi qua pipeline Spec Kit. Không nhảy cóc sang code.
Bộ lệnh/skills đã cài đặt:
- **Antigravity (AGY):** `.agents/skills/speckit-*/` (skills: `speckit-constitution`, `speckit-specify`, `speckit-clarify`, `speckit-plan`, `speckit-tasks`, `speckit-analyze`, `speckit-implement`, `speckit-converge`, `speckit-checklist`, `speckit-bug-assess`, `speckit-bug-fix`, `speckit-bug-test`). Antigravity tự động kích hoạt theo prompt hoặc gọi `/speckit-specify ...`.
- **opencode:** `.opencode/commands/speckit.*` — gọi trong chat (VD `/speckit.specify ...`).

```
/speckit.constitution (1 lần) → /speckit.specify → /speckit.clarify → /speckit.plan
→ /speckit.tasks → /speckit.analyze → /speckit.implement → /speckit.converge
```

| Bước | Lệnh (opencode / Antigravity) | Output / Quy tắc |
|---|---|---|
| `constitution` | `/speckit.constitution` hoặc `speckit-constitution` | `.specify/memory/constitution.md` — nguyên tắc dự án (đã seed theo AGENTS.md/AI guide). Chạy 1 lần, chỉ amend khi quy tắc đổi. |
| `specify` | `/speckit.specify` hoặc `speckit-specify` | `specs/<nnn-slug>/spec.md` — user story (P1/P2/P3), FR, SC có số. Nếu app đã có màn tương tự (VD `/wardrobe/insights`), hỏi phạm vi trước khi tạo màn mới. |
| `clarify` | `/speckit.clarify` hoặc `speckit-clarify` | Sửa `spec.md` — hỏi tối đa 5 câu, chốt điểm mơ hồ (nguồn dữ liệu, entry point, phạm vi v1). |
| `plan` | `/speckit.plan` hoặc `speckit-plan` | `plan.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md` — xác minh API thật trên BE repo trước khi chốt (VD `wearCount` hardcode 0 → fallback ẩn chỉ số). Không bịa endpoint. |
| `tasks` | `/speckit.tasks` hoặc `speckit-tasks` | `tasks.md` — task phụ thuộc có thứ tự (Setup / Foundational / US1..n / Polish), mỗi task trỏ file cụ thể. |
| `analyze` | `/speckit.analyze` hoặc `speckit-analyze` | Kiểm tra coverage FR↔task, mâu thuẫn (VD deep-link trong checklist khi cờ paid tắt). Sửa spec/plan/tasks trước khi code. |
| `implement` | `/speckit.implement` hoặc `speckit-implement` | Làm theo thứ tự tasks, đánh dấu xong từng task; viết work-log `docs/work-log-<yyyy-mm-dd>.md`. |
| `converge` | `/speckit.converge` hoặc `speckit-converge` | Rà khoảng trống còn lại so với spec; nếu thêm task thì lặp `implement → converge` tới khi "Converged". |
| `verify` | DoD §7 | `flutter analyze` 0 issues + test liên quan pass + QS trên máy thật (nếu UI). |

- **Cài đặt Spec Kit:**
  - Antigravity: `specify integration install agy --force --script ps` (tạo `.agents/skills/speckit-*/`).
  - opencode: `specify init . --integration opencode --here --force --ignore-agent-tools --script ps` (tạo `.opencode/commands/speckit.*`).
  - `.specify/` là **machine-local** (gitignored).
- Tuỳ chọn tăng chất lượng: `/speckit.checklist` hoặc `speckit-checklist` (sau plan), `/speckit.analyze` hoặc `speckit-analyze` (trước implement). Bug workflow: `specify extension add bug` → `speckit-bug-assess`, `speckit-bug-fix`, `speckit-bug-test`.
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
- **Makefile trên Windows:** make mặc định gán `SHELL = sh.exe` nhưng `sh.exe` **không có trên PATH** → make **không báo lỗi**, lặng lẽ fallback sang `cmd.exe`, mọi recipe hỏng (`echo "x"` in ra `"x"`, `if [ -f f ]` lỗi). `Makefile` đã tự dò `C:/Program*/Git/usr/bin/sh.exe`; **phải bọc dấu nháy kép** vì đường dẫn có khoảng trang, nếu không sẽ lỗi `CreateProcess(NULL, …)`. Dùng `.RECIPEPREFIX = >` thay TAB. Không sửa `SHELL` nếu chưa hiểu lý do.

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
- Tính năng mới: pipeline Spec Kit `speckit-*` (`speckit-specify` → `speckit-clarify` → `speckit-plan` → `speckit-tasks` → `speckit-analyze` → `speckit-implement` → `speckit-converge`).
- Bug workflow: `speckit-bug-assess`, `speckit-bug-fix`, `speckit-bug-test`.
