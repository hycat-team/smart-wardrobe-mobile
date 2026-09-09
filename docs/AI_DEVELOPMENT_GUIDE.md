# SMART WARDROBE (CLOSY) - MOBILE ARCHITECTURE & AI DEVELOPMENT GUIDE

> **Dành cho AI Assistants & Kỹ sư tham gia dự án:**
> Tài liệu này mô tả toàn bộ cấu trúc dự án, quy tắc kiến trúc, quy chuẩn format code, cách kết nối API thật, và các bài học/lỗi quan trọng (gotchas) đã được giải quyết trong quá trình phát triển ứng dụng di động **Smart Wardrobe (Closy Mobile)**.
> **Bắt buộc đọc kỹ tài liệu này trước khi tạo mới hoặc sửa đổi mã nguồn.**

---

## 1. TỔNG QUAN HỆ SINH THÁI DỰ ÁN

Hệ thống **Smart Wardrobe (Closy)** gồm 3 phân hệ chính:
1. **`smart-wardrobe-mobile`** (Dự án này): Ứng dụng di động xây dựng bằng **Flutter (Dart)**, hỗ trợ cả Android, iOS và Web (Chrome Debug).
2. **`smart-wardrobe-fe`**: Ứng dụng web dành cho người dùng và thương hiệu đối tác, xây dựng bằng **Next.js (React / TypeScript / Tailwind CSS / Zustand / TanStack Query)**.
3. **Backend Services (Golang API)**:
   - Base URL mặc định: `http://localhost:5000/api/v1` (Web & Desktop) hoặc `http://10.0.2.2:5000/api/v1` (Android Emulator).
   - Hỗ trợ Authentication qua HTTP-only Cookie và **Bearer JWT Token**.
   - Cloudinary Media Storage phục vụ lưu trữ và cắt tách nền ảnh thời trang.

---

## 2. CÔNG NGHỆ & THƯ VIỆN CHÍNH (TECH STACK)

| Thành phần | Thư viện / Công nghệ | Vai trò / Lưu ý |
|---|---|---|
| **Framework** | Flutter SDK (Dart 3.x) | Hỗ trợ Mobile & Web |
| **State Management** | `flutter_riverpod: ^2.5.1` | `StateNotifierProvider`, `StateProvider`, `FutureProvider` |
| **Routing** | `go_router: ^14.2.0` | Quản lý điều hướng khai báo, ShellRoute, Auth Guard redirect |
| **Network Client** | `dio: ^5.4.3` + `cookie_jar` | Quản lý HTTP request, tự động đính kèm Bearer Token & Cookie |
| **Local Storage** | `flutter_secure_storage` + `shared_preferences` | Lưu trữ token, user session an toàn trên mọi nền tảng |
| **Typography** | `google_fonts: ^6.2.1` | Serif: `Playfair Display`, Sans: `Be Vietnam Pro` |
| **Image Loading** | `cached_network_image` + `ClosyNetworkImage` | Tối ưu bộ nhớ đệm, tự động downsample texture chống tràn VRAM |
| **Image Upload** | `image_picker` + Cloudinary REST API | Chụp ảnh / chọn ảnh từ thư viện, ký chữ ký và tải trực tiếp lên Cloudinary |

---

## 3. CẤU TRÚC THƯ MỤC CHUẨN (`lib/`)

Dự án áp dụng kiến trúc **Feature-First Layered Architecture**:

```text
lib/
├── core/                               # Tài nguyên dùng chung toàn app
│   ├── constants/
│   │   └── app_constants.dart          # API URLs, Storage Keys, Cloudinary Config
│   ├── network/
│   │   └── api_client.dart             # Cấu hình Dio, Interceptor, Error Handler
│   ├── router/
│   │   └── app_router.dart             # Định nghĩa GoRouter, Auth Redirect Guard
│   ├── services/
│   │   └── cloudinary_service.dart     # Service upload ảnh lên Cloudinary
│   ├── storage/
│   │   └── secure_storage_service.dart # Quản lý Token & Session an toàn
│   └── theme/
│       └── app_theme.dart              # Theme palette, typography, decoration
├── features/                           # Các module nghiệp vụ chính
│   ├── auth/                           # Đăng nhập, Đăng ký, Quên mật khẩu, Preferences
│   │   ├── data/                       # AuthRepository (gọi API thật)
│   │   ├── models/                     # AuthModels (UserModel, AuthResponse, etc.)
│   │   ├── presentation/               # LoginScreen, RegisterScreen, etc.
│   │   └── providers/                  # auth_provider.dart
│   ├── wardrobe/                       # Tủ đồ số hoá cá nhân (Digital Closet)
│   │   ├── data/                       # WardrobeRepository
│   │   ├── models/                     # WardrobeItemModel, CategoryModel
│   │   ├── presentation/               # WardrobeScreen (Grid đồ, lọc danh mục, upload)
│   │   └── providers/                  # wardrobe_provider.dart, upload_wardrobe_provider.dart
│   ├── outfit_studio/                  # Phối đồ Studio (AI Phối đồ & Canvas thủ công)
│   │   ├── data/                       # OutfitRepository
│   │   ├── models/                     # OutfitModels, CanvasItem, Recommendation
│   │   ├── presentation/
│   │   │   ├── outfit_studio_screen.dart # Canvas 2D kéo thả + Sticky Wardrobe Drawer
│   │   │   └── outfits_list_screen.dart  # Danh sách các bộ outfit đã lưu của user
│   │   └── providers/
│   │       ├── ai_outfit_provider.dart      # Gọi API AI gợi ý set đồ theo ngữ cảnh
│   │       ├── outfit_studio_provider.dart  # State quản lý Canvas, Layer, Scale, Search
│   │       └── outfits_list_provider.dart   # Quản lý danh sách outfit đã tạo
│   ├── stylist/                        # Chatbot Tư vấn phong cách AI
│   ├── marketplace/                    # Mua sắm & Khám phá sản phẩm đối tác
│   └── profile/                        # Trang cá nhân, thông số hình thể, cài đặt
└── shared/                             # Widgets & Components tái sử dụng
    └── widgets/
        ├── closy_network_image.dart    # Widget hiển thị ảnh tối ưu bộ nhớ đệm
        └── scaffold_with_nav_bar.dart  # Shell thanh điều hướng dưới đáy (5 tabs)
```

---

## 4. CÁC QUY TẮC BẮT BUỘC KHI VIẾT CODE (CODING STANDARDS)

### 4.1. Quy tắc State Management (Riverpod)
1. **Không sử dụng Mock Data** khi đã có API Backend:
   - Mọi nghiệp vụ phải đi qua `Repository` -> `Dio (ApiClient)` -> Backend.
2. **Khai báo State an toàn với Null-Safety**:
   - Khi tạo hoặc mở rộng State class (`OutfitStudioState`, `WardrobeState`...), các trường mới thêm vào **phải có giá trị mặc định** hoặc xử lý nullable an toàn với getter công khai:
   ```dart
   class OutfitStudioState {
     final String? _drawerSearchQuery;
     String get drawerSearchQuery => _drawerSearchQuery ?? '';
     ...
   }
   ```
   *Lý do:* Tránh lỗi `TypeError: null: type 'Null' is not a subtype of type 'String'` trên Flutter Web khi Hot Reload/Restart lưu lại state instance cũ trong RAM.
3. **Phân tách `ref.watch` và `ref.read`**:
   - Sử dụng `ref.watch(provider)` trong phương thức `build()` để lắng nghe thay đổi UI.
   - Sử dụng `ref.read(provider.notifier)` bên trong các hàm xử lý sự kiện (`onPressed`, `onTap`).

### 4.2. Quy tắc Xử lý Ảnh & Tránh Tràn Bộ Nhớ (VRAM Texture Thrashing)
- **TUYỆT ĐỐI KHÔNG** dùng `Image.network(url)` trực tiếp cho danh sách đồ tủ hoặc sản phẩm.
- **BẮT BUỘC** sử dụng `ClosyNetworkImage`:
  ```dart
  ClosyNetworkImage(
    imageUrl: item.displayImageUrl,
    fit: BoxFit.contain,
    memCacheWidth: 300,  // Downsample từ 1800px xuống 300px để giảm VRAM từ 12MB còn 350KB
    memCacheHeight: 300,
  )
  ```
- Đối với danh sách dạng Grid hoặc ListView có cuộn, bọc item card bằng `AutomaticKeepAliveClientMixin` với `wantKeepAlive => true` để tránh tình trạng ảnh bị dispose và reload gây chớp giật hoặc đen màn hình khi cuộn lên cuộn xuống.

### 4.3. Quy tắc Thiết kế Giao diện (UI/UX Luxury Editorial)
1. **Palette màu chuẩn `AppColors`**:
   - Nền chính: `AppColors.background` (`#FAF8F5` - màu kem sáng sang trọng).
   - Nền thẻ/Card: `AppColors.surface` (`#FFFFFF`).
   - Màu nhấn: `AppColors.accentSand` (`#E6DEC9`), `AppColors.accentSandDark` (`#B8A99A`).
   - Chữ chính: `AppColors.primary` (`#1A1A1A` - Đen tuyền).
   - Viền: `AppColors.border` (`#E8E3DC`).
   - Tuyệt đối không dùng các màu cơ bản thuần túy (như `Colors.red`, `Colors.blue`).
2. **Typography**:
   - Tiêu đề màn hình, thẻ chính: `GoogleFonts.playfairDisplay(...)` (Font có chân cổ điển, phong cách tạp chí thời trang).
   - Nội dung, nhãn, nút bấm, bảng thông số: `GoogleFonts.beVietnamPro(...)` hoặc sans-serif sạch.

### 4.4. Quy tắc Sticky Header trong Bottom Sheet
Khi thiết kế phần chọn đồ hoặc bộ lọc có thể cuộn:
- Dùng `DraggableScrollableSheet` kết hợp `CustomScrollView(controller: scrollController)`.
- Đặt thanh tiêu đề, tìm kiếm và chip danh mục trong `SliverPersistentHeader(pinned: true, delegate: ...)`.
- Bọc nội dung header bằng `ClipRRect` để không bị lẹm góc bo viền tròn khi item cuộn bên dưới.

---

## 5. CẢNH BÁO QUAN TRỌNG VỀ ENCODING (WINDOWS POWERSHELL GOTCHA)

> [!CAUTION]
> **LỖI LÀM HỎNG TIẾNG VIỆT (MOJIBAKE BUG TRÊN WINDOWS):**
> Trên hệ điều hành Windows, PowerShell 5.1 mặc định đọc và ghi file bằng bảng mã **ANSI (Windows-1252)** thay vì **UTF-8**.
> 
> **HÀNH VI BỊ CẤM:**
> `(Get-Content -Raw file.dart) -replace '...' | Set-Content file.dart`
> Lệnh trên sẽ biến toàn bộ tiếng Việt (`Áo`, `Quần`, `Đầm`) thành ký tự rác (`Ã¡o`, `quáº§n`, `Ä‘áº§m`).
> 
> **CÁCH XỬ LÝ ĐÚNG:**
> 1. Dùng tool `write_to_file` hoặc `replace_file_content` trực tiếp.
> 2. Nếu dùng PowerShell, bắt buộc phải có cờ `-Encoding utf8` ở cả 2 đầu:
>    `Get-Content -Path '...' -Encoding utf8 | ... | Set-Content -Path '...' -Encoding utf8`
> 3. Hoặc ghi file ra thư mục `scratch/` rồi dùng lệnh nhị phân `Copy-Item` để ghi đè.

> [!WARNING]
> **LỖI KOTLIN INCREMENTAL COMPILATION TRÊN ANDROID WINDOWS (KT-66598):**
> Khi build Android (`assembleDebug`), Kotlin 2.x trên Windows thường bị lỗi khóa file cache:
> `Could not close incremental caches ... Storage for [...] is already registered`
> **Cách khắc phục:** Luôn giữ `kotlin.incremental=false` trong `android/gradle.properties`.

---

## 6. DANH SÁCH TÀI KHOẢN & MÔI TRƯỜNG TEST

- **Tài khoản kiểm thử mặc định:**
  - Tên đăng nhập: `user`
  - Mật khẩu: `123456`
- **Tài khoản Brand/Admin:**
  - Tên đăng nhập: `brand_admin` hoặc `admin`
  - Mật khẩu: `123456`
- **Lệnh chạy ứng dụng kiểm thử:**
  ```bash
  # Chạy trên Chrome web:
  flutter run -d chrome

  # Chạy kiểm tra tĩnh mã nguồn:
  flutter analyze
  ```
- **Hot Restart trong terminal:** Nhấn `R` (chữ in hoa) để tải lại toàn bộ ứng dụng mà không cần khởi động lại tiến trình Flutter.

---

## 7. CHECKLIST KIỂM TRA TRƯỚC KHI BÀN GIAO (PRE-FLIGHT CHECKLIST)

Mỗi khi AI thực hiện một yêu cầu code mới:
- [ ] Chạy `flutter analyze` trong `smart-wardrobe-mobile` và đảm bảo **0 issues found**.
- [ ] Đảm bảo các chuỗi tiếng Việt hiển thị sắc nét, không bị biến dạng ký tự.
- [ ] Ảnh mạng được load qua `ClosyNetworkImage` có `memCacheWidth` hợp lý.
- [ ] Các màn hình có form gửi dữ liệu phải có trạng thái loading indicator và thông báo lỗi rõ ràng qua `SnackBar` hoặc Dialog.
- [ ] Cập nhật luồng điều hướng hợp lý bằng `GoRouter` (ví dụ: tạo outfit xong chuyển hướng về `/outfits`).
