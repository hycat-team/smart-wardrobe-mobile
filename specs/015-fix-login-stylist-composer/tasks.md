---

description: "Task list for 015-fix-login-stylist-composer"
---

# Tasks: Sửa nháy màn login, tràn viền Up bài, gợi ý AI sai

**Input**: Design documents from `/specs/015-fix-login-stylist-composer/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/stylist-outfit-recommendation.md, quickstart.md

**Tests**: CÓ. Hiến pháp mục I bắt buộc `flutter test` cho phần liên quan. Viết test **trước**,
xác nhận fail, rồi mới viết code.

**Organization**: Gom theo user story. Năm story độc lập về mặt kỹ thuật — hoàn thành
story nào thì bàn giao được phần đó.

> **Sinh lại lần 4 (2026-10-02)** sau `clarify` phiên 4 + `analyze`.
>
> Trạng thái phiên nay có **bốn** trạng thái (FR-001), không còn ba. Người dùng chốt
> giữ ở màn hình khởi động kèm nút "Thử lại" khi lỗi tạm thời, và **không** tự thử lại
> (FR-035). Ba lỗi HIGH của `analyze` đã xử lý:
> - **C2** → T016/T017 chặn theo **hai** cờ, không chỉ `isCheckingAuth`
> - **U1** → thêm T019, T020 cho nút Thử lại và chặn bấm liên tụp
> - **U2** → T049 kiểm chứng cả nhánh splash ở lại

## Format: `[ID] [P?] [Story] Description`

- **[P]**: chạy song song được (khác file, không phụ thuộc task chưa xong)
- **[Story]**: story nào thuộc về (US1…US5)
- **Đường dẫn chính xác** nằm trong mô tả — **mọi task triển khai đều phải có**

## Quy ước bắt buộc cho repo này

- Sửa file bằng tool `edit`/`write`. **Cấm** `Get-Content | -replace | Set-Content` và
  redirect `>` — PowerShell 5.1 mặc định ANSI sẽ làm hỏng tiếng Việt (hiến pháp V).
- Mọi nhãn hiển thị bằng **tiếng Việt**, không mojibake.
- Ảnh mạng **bắt buộc** qua `ClosyNetworkImage` — cấm `Image.network`.
- Mọi trường mới trong state/model class **phải có giá trị mặc định**.
- Cỡ chữ tiêu đề Playfair Display, nhãn/nút Be Vietnam Pro.

---

## Phase 1: Setup (Hạ tầng dùng chung)

**Mục đích**: Xác nhận môi trường trước khi sửa. Không tạo cấu trúc mới.

- [X] T001 Xác nhận backend chạy ở cổng **8080** (không phải 5000): `Invoke-WebRequest http://localhost:8080/api/v1/categories` trả `200`. Ghi kết quả vào work-log
- [X] T002 Xác nhận `flutter analyze` sạch trước khi bắt đầu: `make analyze` → `No issues found`
- [X] T003 Chạy `make test`, ghi lại baseline: xác nhận đúng 3 integration test cần BE thật là **trạng thái có sẵn** bằng cách đếm số test pass trước khi sửa
- [X] T004 Đọc `specs/015-fix-login-stylist-composer/research.md` R1–R10 và `specs/015-fix-login-stylist-composer/contracts/stylist-outfit-recommendation.md` trước khi viết code — nắm vì sao mỗi quyết định được chọn

---

## Phase 2: Foundational (Chặn US1 và US2)

**Mục đích**: Hạ tầng dùng chung cho US1 và US2 (cùng nằm trong feature `auth`).
**⚠️ CRITICAL**: US1 và US2 không thể bắt đầu trước khi phase này xong.

### Trạng thái phiên — bốn trạng thái (FR-001)

| Cờ | Ý nghĩa | Mặc định |
|---|---|---|
`isCheckingAuth` | đang kiểm tra | `true` |
`authCheckFailed` | kiểm tra lỗi tạm thời, phiên được giữ | `false` |
`isAuthenticated` | đã xác nhận có hồ sơ | `false` |

- [X] T005 [P] Thêm cờ `isCheckingAuth` (bool, **mặc định `true`**) vào `AuthState` tại `lib/features/auth/providers/auth_provider.dart`, bổ sung tham số vào `copyWith`. Hiến pháp II: phải có default để chống `Null is not a subtype of bool` khi hot reload web
- [X] T006 [P] Thêm cờ `authCheckFailed` (bool, **mặc định `false`**) cùng tham số `copyWith` trong `lib/features/auth/providers/auth_provider.dart`. Đây là trạng thái thứ tư mà FR-001 yêu cầu
- [X] T007 Sửa `getCurrentUser()` trong `lib/features/auth/data/auth_repository.dart` để **rethrow nguyên `DioException`** thay vì bọc thành `Exception` chuỗi tiếng Việt — hiện tại mất mã trạng thái HTTP nên không phân biệt được 401 với lỗi mạng (nghiên cứu R1)
- [X] T008 Sửa `checkAuthStatus()` trong `lib/features/auth/providers/auth_provider.dart` theo **bốn nhánh**: bật `isCheckingAuth` và tắt `authCheckFailed` lúc bắt đầu; thành công → `isCheckingAuth=false`, `authCheckFailed=false`, `isAuthenticated=true`; lỗi tạm thời (không có `response`, hoặc 5xx) → `isCheckingAuth=false`, `authCheckFailed=**true**`, `isAuthenticated=**true**` (giữ phiên, FR-027); 401/403 → xoá phiên, `isAuthenticated=false`. Bắt buộc tắt `isCheckingAuth` trong **`finally`** (tránh kẹt vô hạn)
- [X] T009 Trong `lib/features/auth/providers/auth_provider.dart`: (a) `checkAuthStatus()` phải **an toàn khi gọi lại** và **chặn gọi chồng nhau** — nếu một lần kiểm tra đang chạy thì lời gọi mới bị bỏ qua, tránh dồn yêu cầu khi người dùng bấm "Thử lại" liên tục; (b) **KHÔNG** thêm timer, vòng lặp, hay bất kỳ cơ chế tự thử lại theo thời gian nào — chỉ lời gọi tường minh từ nút "Thử lại" mới được phép phát sinh yêu cầu (FR-035); (c) `isCheckingAuth` phải chỉ bắt đầu ở `true` ở **lần kiểm tra phiên đầu tiên của tiến trình** — từ lần thứ hai (do đổi phiên) bắt đầu ở `false` để splash không nháy giữa phiên. Cờ đánh dấu "đã khởi động" phải **sống sót** việc dispose `ProviderScope` khi đăng xuất, nên đặt ở cấp thư viện chứ không đặt trong một provider thường (FR-003, SC-011)
- [X] T010 Tạo widget splash tại `lib/features/auth/presentation/widgets/splash_screen.dart`: toàn màn hình, nền `#FAF8F5`, logo sẵn có, chữ Playfair Display, không màu mặc định hệ điều hành. Nhận tham số cho **thông báo lỗi tiếng Việt** và **nút "Thử lại"** (FR-006, FR-027)

**Checkpoint**: US1 và US2 có nền tảng.

---

## Phase 3: User Story 1 — Mở app thấy splash thay vì màn đăng nhập (P1) 🎯 MVP

**Mục đích**: Không bao giờ thấy màn đăng nhập khi thực tế đã đăng nhập. Khi lỗi mạng,
giữ người dùng ở splash kèm nút "Thử lại" thay vì đá ra ngoài.

**Independent test**: Đăng nhập một lần → nhấn F5 → **phải** thấy splash rồi vào thẳng tủ
đồ, không thấy màn đăng nhập ở bất kỳ khoảnh khắc nào. Tắt mạng → mở lại app → **phải** ở
lại splash kèm nút "Thử lại"; bật lại mạng, bấm nút → vào thẳng tủ đồ, không phải đăng
nhập lại. Tương ứng quickstart K1, K4, K5.

### Test cho US1 ⚠️ viết trước

- [X] T011 [P] [US1] Tạo `test/auth_session_state_test.dart`: khẳng định `isCheckingAuth` và `authCheckFailed` có đúng giá trị mặc định, và chuyển về `false` ở **cả** đường thành công lẫn đường throw (FR-001, FR-002)
- [X] T012 [P] [US1] Thêm test rẽ nhánh lỗi trong `test/auth_session_state_test.dart`: lỗi **không có** `response` (mạng) → `authCheckFailed=true` + `isAuthenticated=true`; 5xx → tương tự; 401/403 → xoá phiên, `authCheckFailed=false` (FR-026, FR-027, FR-028)
- [X] T013 [P] [US1] Thêm test **không tự thử lại** trong `test/auth_session_state_test.dart`: sau khi rơi vào trạng thái lỗi tạm thời, chờ nhiều giây và khẳng định **không** có lời gọi `getCurrentUser` nào phát sinh; chỉ khi gọi `checkAuthStatus()` một cách tường minh thì mới có (FR-035)
- [X] T014 [P] [US1] Thêm test gọi chồng trong `test/auth_session_state_test.dart`: gọi `checkAuthStatus()` hai lần liên tiếp thì chỉ một lời gọi `getCurrentUser` xảy ra; một lần thử lại trả 401 thì phải chuyển sang `isAuthenticated=false` chứ không quay lại trạng thái lỗi tạm thời; và `isCheckingAuth` chỉ bắt đầu ở `true` ở lần kiểm tra đầu tiên — lần thứ hai phải bắt đầu ở `false` để splash không nháy khi đổi phiên (FR-003, SC-011)

### Triển khai US1

- [X] T015 [US1] Sửa `AppRouterNotifier` trong `lib/core/router/app_router.dart` phát `notifyListeners()` khi **bất kỳ** cờ nào trong `isCheckingAuth` / `authCheckFailed` / `isAuthenticated` đổi. Thiếu phần này thì splash biến mất nhưng router không đánh giá lại → kẹt hoặc vào app sai (nghiên cứu R2)
- [X] T016 [US1] Sửa `redirect` trong `lib/core/router/app_router.dart` cho thoát sớm — không áp luật đá về `/login` — khi `isCheckingAuth` **hoặc** `authCheckFailed` còn `true`. Chỉ kiểm một cờ là **không đủ**: sau lỗi tạm thời, `isCheckingAuth` đã tắt nhưng người dùng vẫn phải ở lại splash (FR-004, FR-027)
- [X] T017 [US1] Sửa `SmartWardrobeApp.build` trong `lib/main.dart` để hiển thị `SplashScreen` khi `isCheckingAuth` **hoặc** `authCheckFailed`, đặt **trên** `MaterialApp.router` để router vẫn tính đích đến bình thường và không phát sinh route mới. Thứ tự này bảo đảm không màn hình nào khác hiện ra, kể cả màn đăng nhập (FR-003)
- [X] T018 [US1] Thêm đếm ngược chống nháy trong `lib/main.dart`: `Future.delayed` 1 giây có thể huỷ, chạy **song song** với việc kiểm tra phiên. Splash luôn hiện ở mọi lần khởi động; nếu kiểm tra xong sớm thì ẩn sớm. **Không** thêm độ trờ cố ý, và **không** có nhánh bỏ qua splash. Ngưỡng này **chỉ áp dụng khi đang kiểm tra** — trạng thái lỗi tạm thời thì splash ở lại chờ người dùng (FR-005, SC-002)
- [X] T019 [US1] Nối nút "Thử lại" trong `lib/features/auth/presentation/widgets/splash_screen.dart` với `checkAuthStatus()`: bấm thì hiện lại trạng thái đang kiểm tra, gọi lại và giữ nguyên phiên; thành công thì thoát splash, thất bại thì quay lại trạng thái lỗi tạm thời kèm thông báo tiếng Việt
- [X] T020 [US1] Vô hiệu hoá nút "Thử lại" trong `lib/features/auth/presentation/widgets/splash_screen.dart` khi đang trong trạng thái *đang kiểm tra*, để bấm liên tục không tạo ra một loạt yêu cầu dồn dập

**Checkpoint**: US1 chạy độc lập.

---

## Phase 4: User Story 2 — Đang lấy token thì không thao tác lại được (P1)

**Mục đích**: Chặn toàn màn hình trong lúc lấy phiên, mỗi lần bấm chỉ sinh một yêu cầu.

**Independent test**: Bấm Đăng nhập → thấy lớp phủ chặn tương tác; bấm liên tục vị trí nút
cũ → chỉ **một** yêu cầu trong tab Network. Đăng nhập sai → lớp phủ biến mất, thông báo
lỗi hiện ra. Tương ứng quickstart K2, K3.

> Không cần file test mới — dùng lại `test/auth_session_state_test.dart` và
> `test/login_enter_submit_test.dart` sẵn có.

### Triển khai US2

- [X] T021 [US2] Sửa `login_screen.dart` tại `lib/features/auth/presentation/login_screen.dart`: khi `authState.isLoading` thì phủ **toàn màn hình** bằng lớp chặn tương tác, thay vì chỉ xoay spinner trên nút. Lớp phủ phải nuốt mọi chạm/nhấn, **kể cả nhấn lại nút đăng nhập** (FR-007, FR-008)
- [X] T022 [P] [US2] Sửa `lib/features/auth/presentation/widgets/google_sign_in_button.dart` đảm bảo mọi đường thoát — thành công, thất bại, người dùng huỷ, hết thời gian chờ — đều trả `isLoading` về `false` (FR-010, FR-011)

> **T022 — KHÔNG cần sửa code.** Đã kiểm tra `google_sign_in_button.dart`: có `finally`
> (dòng 161-165) gọi `setState(_isLocallyLoading = false)` phủ **mọi** đường thoát —
> thành công, idToken rỗng, timeout, huỷ, lỗi. Phía web không có state loading riêng
> (nút do GIS render, `web_button_web.dart` không có biến loading) nên không thể kẹt
> vĩnh viễn. `loginWithGoogle` trong `auth_provider.dart` cũng trả `isLoading: false` ở
> cả 3 nhánh (thành công / từ chối / exception). FR-010 + FR-011 chỉ yêu cầu *mọi đường
> thoát đều trả về false* — điều kiện này đã thoả từ trước.

- [X] T023 [US2] Thêm nhãn tiếng Việt nói rõ đang xử lý vào lớp phủ đã tạo ở T021, trong `lib/features/auth/presentation/login_screen.dart`; giữ vùng chạm ≥ 44px, bảng màu Quiet Luxury (FR-009)

**Checkpoint**: US1 và US2 đều chạy độc lập.

---

## Phase 5: User Story 3 — Màn Up bài không tràn viền (P2)

**Mục đích**: Dải "HÌNH ẢNH & VIDEO" hiển thị trọn vẹn ở mọi bề rộng cửa sổ.

**Independent test**: Thu nhỏ cửa sổ về khoảng 300px rồi mở màn Up bài → không có
`RenderFlex overflowed` trong Console, mọi nút vẫn bấm được. Tương ứng quickstart K3.

> Story này **độc lập hoàn toàn** với US1/US2/US4 — có thể làm song song, không cần
> phase Foundational.

### Test cho US3 ⚠️ viết trước

- [X] T024 [P] [US3] Tạo `test/composer_layout_test.dart`: dựng màn Up bài ở bề rộng hẹp 300px và khẳng định **không** phát sinh `RenderFlex overflow`; thêm case bề rộng rộng khẳng định bố cục không đổi (FR-012, FR-014)

### Triển khai US3

- [X] T025 [US3] Sửa dải media tại `lib/features/community/presentation/post_composer_screen.dart` khoảng dòng 425–458: bọc nhãn "HÌNH ẢNH & VIDEO (n/10)" trong `Flexible` kèm `overflow: ellipsis` (FR-012)
- [X] T026 [US3] Sửa **cùng file** `lib/features/community/presentation/post_composer_screen.dart`: đổi `Row` chứa hai `TextButton.icon` thành `Wrap` để nút tự xuống dòng khi khung hẹp, không tràn ngang (FR-013)
- [X] T027 [US3] Rà lại `lib/features/community/presentation/post_composer_screen.dart` và `lib/features/community/providers/post_composer_provider.dart`: khẳng định hành vi sẵn có còn nguyên — giới hạn 10 tệp, định dạng chấp nhận, giới hạn dung lượng, trạng thái khoá nút khi đã đủ 10 tệp (FR-015). Không thay `ListView`, không thu nhỏ font

**Checkpoint**: US3 hoàn tất, không ảnh hưởng US1/US2.

---

## Phase 6: User Story 4 — Gợi ý phối đồ hiện đúng món kèm ảnh thật (P1)

**Mục đích**: Mọi thẻ gợi ý có tên món và ảnh tải được. Nguyên nhân gốc là parse sai
hợp đồng máy chủ.

**Independent test**: Hỏi stylist `gợi ý phối đồ cho đi làm` → dải thẻ hiện, **không thẻ
nào trống**, mọi ảnh tải được. Tương ứng quickstart K6, K7, K8.

> ⚠ **Bắt buộc có backend thật** ở cổng 8080 cho phần đọc hợp đồng gợi ý.

### Test cho US4 ⚠️ viết trước

- [X] T028 [P] [US4] Tạo `test/stylist_recommendation_contract_test.dart` với fixture JSON đúng hợp đồng máy chủ (`items` là **nhóm theo vai trò**, món nằm trong `fashionItem`/`brandItem`): khẳng định sau khi làm phẳng, mọi món có `id` và `title` khác rỗng (FR-016, FR-017)
- [X] T029 [P] [US4] Thêm test lấy ảnh từ **cả hai** nguồn `fashionItem.imageUrl` và `brandItem.imageUrl` trong `test/stylist_recommendation_contract_test.dart` (FR-018)
- [X] T030 [P] [US4] Thêm test bảng ánh xạ vai trò trong `test/stylist_recommendation_contract_test.dart`: đủ 8 giá trị đóng gồm `headwear`, và giá trị lạ thì trả về nguyên chuỗi gốc chứ không phải chuỗi rỗng (FR-031, FR-032)
- [X] T031 [P] [US4] Thêm test điều kiện kích hoạt trong `test/stylist_recommendation_contract_test.dart`: hàm so khớp câu hỏi phải bắt được `gợi ý phối đồ`, `áo nào hợp với quần nâu`, `mặc gì đi làm`; và **không** bắt được `hôm nay thời tiết thế nào`. Logic thuần nên **không cần backend**. Phải fail trước khi T037 sửa (FR-021)

### Triển khai US4

- [X] T032 [US4] Sửa `getOutfitRecommendation()` trong `lib/features/stylist/data/stylist_repository.dart` để parse bằng bộ model **đã có sẵn** `RecommendedOutfitRes` từ `lib/features/outfit_studio/models/outfit_models.dart` — đừng viết lại model mới, đừng sửa máy chủ (nghiên cứu R5)
- [X] T033 [US4] Thêm bước làm phẳng trong `lib/features/stylist/data/stylist_repository.dart`: duyệt `primary` rồi `alternatives` của từng nhóm; **bỏ qua hẳn** món thiếu cả `fashionItem` lẫn `brandItem` (nguyên nhân gốc tạo thẻ rỗng); giữ lại món có `imageUrl` rỗng nhưng để `imageUrl = null`
- [X] T034 [US4] **Mở rộng model stylist sẵn có** tại `lib/features/stylist/models/stylist_models.dart` (chặn US5): thêm `role` vào `OutfitRecommendationItem`; thêm `isFallback` và `remainingQuota` vào `OutfitRecommendationModel`. Tất cả trường mới **phải có giá trị mặc định**. Đây là nơi duy nhất mang ba giá trị này tới UI — **cấm** tạo bộ model phẳng thứ hai song song (FR-033, FR-034)
- [X] T035 [US4] Bổ sung `headwear` và `other` vào bảng ánh xạ vai trò đóng tại `lib/features/outfit_studio/models/outfit_models.dart`; để `roleLabelVi` ở `OutfitRecommendationItem` (T034) là **getter** gọi tới đúng bảng đó, không tạo bảng nhãn thứ hai (FR-031, FR-032, nghiên cứu R6). **Phụ thuộc T034**
- [X] T036 [US4] Cập nhật `_buildLookbookCarousel()` trong `lib/features/stylist/presentation/stylist_screen.dart`: hiển thị nhãn vai trò tiếng Việt; khi `imageUrl` rỗng thì hiện nhãn vai trò thay vì để widget ảnh rơi về biểu tượng lỗi (FR-019, FR-020). **Phụ thuộc T034, T035**
- [X] T037 [US4] Thay điều kiện kích hoạt trong `lib/features/stylist/providers/stylist_provider.dart` khoảng dòng 250: giữ marker `[ACTION:REDIRECT_OUTFIT]`, thay `contains('phối')||contains('outfit')` bằng bộ khoá từ máy chủ đã bỏ dấu tiếng Việt và hạ chữ thường. Xem `research.md` R7 — prompt máy chủ phát marker **ngược** với logic cũ của ứng dụng (FR-021). **Phụ thuộc T031**
- [X] T038 [US4] Loại khỏi `ChatMessageModel.fromJson` trong `lib/features/stylist/models/stylist_models.dart` hai nhánh tra `outfitRecommendation` và `suggestedItems` — máy chủ `ChatMessageRes` không gửi hai trường này, đọc luôn ra `null` (FR-024, nghiên cứu R8). **Phụ thuộc T034**
- [X] T039 [US4] Bảo đảm marker `[ACTION:REDIRECT_OUTFIT]` không bao giờ hiển thị cho người dùng trong phần văn bản trả lời — dùng getter `cleanContent` đã có trong `lib/features/stylist/models/stylist_models.dart`, hoặc loại marker trong `lib/features/stylist/presentation/stylist_screen.dart` nếu getter chưa dùng ở đó

**Checkpoint**: Ảnh gợi ý tải được.

---

## Phase 7: User Story 5 — Lỗi gợi ý được thông báo (P2)

**Mục đích**: Không bị thay bằng dữ liệu bịa, và lỗi phải chẩn đoán được.

**Independent test**: Chặn mạng rồi hỏi stylist về cách phối đồ → phần trả lời văn bản
còn nguyên, có thông báo phần gợi ý tạm thời không có, **không** hiện danh sách ảnh nào.
Tương ứng quickstart K9, K10.

> **Phụ thuộc US4** — dùng chung model đã mở rộng ở T034.

### Test cho US5 ⚠️ viết trước

- [X] T040 [P] [US5] Thêm test lỗi trong `test/stylist_recommendation_contract_test.dart`: khi yêu cầu gợi ý thất bại thì văn bản trả lời được giữ nguyên, và **không** có danh sách món nào từ ứng dụng tự chế (FR-022, FR-023). **Phụ thuộc T028**

### Triển khai US5

- [X] T041 [US5] **Xoá** khối fallback Unsplash nhúng sẵn trong `lib/features/stylist/data/stylist_repository.dart` — đây chính là danh sách món bịa gây cảm giác "AI không chính xác" (FR-023)
- [X] T042 [US5] Thay hai nhánh `catch (_) {}` trần trong `lib/features/stylist/providers/stylist_provider.dart` khoảng dòng 252 và 268 bằng log có tiền tố nhận dạng theo đúng quy ước sẵn có của feature (`[StylistRepository]` / `[StylistNotifier]`), kèm nội dung lỗi (FR-025, nghiên cứu R9)
- [X] T043 [US5] Hiển thị nhãn **"gợi ý dự phòng"** trong `lib/features/stylist/presentation/stylist_screen.dart` khi `isFallback` là `true`, và **không** trình bày như gợi ý chuẩn của stylist (FR-029). **Phụ thuộc T034**
- [X] T044 [US5] Hiển thị số hạn mức còn lại trong `lib/features/stylist/presentation/stylist_screen.dart` kèm thông báo gợi ý tự làm mới vào ngày mới. **Không** hiển thị ngày giờ cụ thể — máy chủ không cung cấp mốc thời gian làm mới (FR-030). **Phụ thuộc T034**

**Checkpoint**: Cả 5 story hoàn tất và chạy độc lập.

---

## Phase 8: Polish & Cross-Cutting

> **Lưu ý (converge, 2026-10-02):** T045, T046, T048, T049 đều là kiểm chứng **thủ công**
> và nay đã bị **T057** ở Phase 9 gộp lại thành một task duy nhất. Giữ nguyên trạng thái
> `[ ]` cho tới khi người dùng chạy xong K1–K11 trên máy thật — không đánh dấu `[X]`
> khi chưa thực sự chạy.

- [ ] T045 Chạy toàn bộ `specs/015-fix-login-stylist-composer/quickstart.md` K1–K11 và ghi kết quả từng kịch bản vào `docs/work-log-2026-10-02.md`
- [ ] T046 Ma trận hồi quy: sau khi xong US1+US2 thì chạy K6–K11; sau US3 thì chạy K1–K3 và K6–K11; sau US5 thì chạy K1–K5. Đặc biệt đăng nhập Google và luồng cộng đồng không được hồi quy vì cả hai đều dựa trên chuyển trạng thái phiên
- [X] T047 `flutter analyze` phải **0 issues**; `flutter test` — xác nhận 3 integration test cần BE thật vẫn fail đúng như baseline ở T003 và không xuất hiện test mới fail
- [ ] T048 Chạy kịch bản hồi quy trên **máy thật**: đăng nhập Google, tủ đồ, cộng đồng (hiến pháp I)
- [ ] T049 **Đo ngưỡng chống nháy trên máy thật** (quickstart K5): đo cả **hai** nhánh — (a) phiên hợp lệ, splash biến mất trong 1 giây; (b) lỗi mạng, splash **ở lại** chờ bấm "Thử lại" chứ không tự ẩn. Số 1 giây là đề xuất chưa kiểm chứng — nếu thấy nháy trên thiết bị chậm thì mở ngưỡng và cập nhật đồng bộ FR-005 + SC-002
- [X] T050 [P] Ghi work-log `docs/work-log-2026-10-02.md`: story nào xong, file nào sửa, kết quả K1–K11, và **nêu rõ** rằng bỏ `catch (_) {}` làm lộ lỗi trước đây bị che (đã ghi ở `spec.md` § Risks)
- [X] T051 [P] Ghi chú cho người sau: bảng ánh xạ vai trò đóng nằm ở `lib/features/outfit_studio/models/outfit_models.dart`, nhưng **model mang `role`** thì ở `lib/features/stylist/models/stylist_models.dart`. Sửa một bên phải kiểm tra bên kia

---

## Ánh xạ Success Criteria → nơi kiểm chứng

Phần lớn SC kiểm chứng bằng **kịch bản thủ công** trong `quickstart.md`. Ghi rõ để không ai tưởng là bỏ sót:

| SC | Kiểm chứng ở đâu |
|---|---|
SC-001 | K1 + T011 test |
SC-002 | K5 + **T049 đo cả hai nhánh** |
SC-003 | K2 (đếm request ở tab Network) |
SC-004 | K3 + T024 test |
SC-005 | K6 + T028/T029 test |
SC-006 | K10 |
SC-007 | K10 |
SC-008 | K11 |
SC-009 | K4 + T012 test |
SC-010 | K9 |
SC-011 | K3 (đăng xuất / đổi tài khoản → thấy thẳng màn đăng nhập) + T014 test |

---

## Dependencies & Execution Order

### Phụ thuộc giữa các phase

- **Phase 1 (Setup)**: không phụ thuộc gì — làm ngay
- **Phase 2 (Foundational)**: phụ thuộc Phase 1 — **chặn US1 và US2**
- **US3 (Phase 5)**: phụ thuộc **Phase 1** thôi → có thể làm song song từ sớm
- **US4 (Phase 6)**: phụ thuộc **Phase 1**. Chuỗi nội bộ: T034 → T035 → T036
- **US5 (Phase 7)**: phụ thuộc **US4** qua T034
- **Phase 8**: phụ thuộc các story tương ứng

### Phụ thuộc giữa các user story

| Story | Phụ thuộc |
|---|---|
| **US1 (P1)** | Phase 2 (T005–T010) |
| **US2 (P1)** | Phase 2 + nền `AuthState` chung với US1 |
| **US3 (P2)** | Không phụ thuộc story nào — **hoàn toàn độc lập** |
| **US4 (P1)** | Không phụ thuộc US1/US2/US3 |
| **US5 (P2)** | Phụ thuộc US4 (model đã mở rộng ở T034) |

### Task cùng đụng một file → KHÔNG song song

| File | Task trùng |
|---|---|
`lib/features/auth/providers/auth_provider.dart` | T005, T006, T008, T009 |
`lib/main.dart` | T017, T018 |
`lib/core/router/app_router.dart` | T015, T016 |
`lib/features/auth/presentation/widgets/splash_screen.dart` | T010, T019, T020 |
`test/auth_session_state_test.dart` | T011, T012, T013, T014 |
`lib/features/auth/presentation/login_screen.dart` | T021, T023 |
`lib/features/community/presentation/post_composer_screen.dart` | T025, T026, T027 |
`test/stylist_recommendation_contract_test.dart` | T028, T029, T030, T031, T040 |
`lib/features/stylist/data/stylist_repository.dart` | T032, T033, T041 |
`lib/features/stylist/models/stylist_models.dart` | T034, T038 |
`lib/features/stylist/presentation/stylist_screen.dart` | T036, T043, T044 |
`lib/features/stylist/providers/stylist_provider.dart` | T037, T042 |

**Có thể song song**: T005↔T006 · T005↔T007 · T011↔T012↔T013↔T014 · T021↔T022 · T022↔T023 ·
T028↔T029↔T030↔T031 · T041↔T042 · T050↔T051

---

## Parallel Example: US1

```bash
# Chạy song song 4 test của US1:
Task: "T011 isCheckingAuth + authCheckFailed có default đúng, false ở cả success và throw"
Task: "T012 rẽ nhánh lỗi: mạng/5xx → authCheckFailed=true, 401/403 → xoá phiên"
Task: "T013 không tự thử lại: chờ nhiều giây không có lời gọi getCurrentUser"
Task: "T014 gọi chồng bị chặn; retry ra 401 thì chuyển sang isAuthenticated=false"

# Sau đó tuần tự:
Task: "T015 AppRouterNotifier phát tín hiệu khi cả ba cờ đổi"
Task: "T016 redirect chặn khi isCheckingAuth HOẶC authCheckFailed"
Task: "T017 main.dart hiện splash theo hai cờ"
```

## Parallel Example: US3 + US1 (hai người)

```bash
# Người A — US1, cần Phase 2:
Task: "T015 Sửa AppRouterNotifier trong lib/core/router/app_router.dart"

# Người B — US3, hoàn toàn độc lập, chạy được ngay:
Task: "T024 Tạo test/composer_layout_test.dart khẳng định không tràn ở 300px"
Task: "T025 Bọc nhãn trong Flexible + ellipsis"
```

---

## Implementation Strategy

### MVP giai đoạn 1

1. Phase 1 Setup
2. Phase 2 Foundational
3. **Phase 3 — US1**
4. **DỪNG và kiểm chứng** US1 độc lập
5. Bàn giao nếu chấp nhận được

US1 là phần có giá trị cao nhất và rủi ro thấp nhất: sửa 6 file, không đụng hợp đồng
dữ liệu, và xoá được thứ hấp dẫn nhất mà người dùng gặp hằng ngày.

### Giao từng phần

1. Setup + Foundational → nền sẵn sàng
2. US1 → kiểm chứng → **MVP**
3. US2 → kiểm chứng
4. US3 → kiểm chứng — *độc lập, chèn bất cứ lúc nào*
5. US4 → kiểm chứng
6. US5 → kiểm chứng
7. Polish + hồi quy toàn bộ

### Ưu tiên khi thiếu thời gian

| Bậc | Task | Lý do |
|---|---|---|
| 1 | T032, T033 | Sửa đúng nguyên nhân gốc ảnh vỡ — giá trị cao, rủi ro thấp |
| 2 | T005–T017 | Xoá nháy login — người dùng thấy mỗi ngày |
| 3 | T025, T026 | Sửa tràn viền — chỉ 2 dòng code, rất nhanh |
| 4 | T037 | Xoá gọi thừa endpoint — cải thiện độ chính xác |
| 5 | T041, T042 | Gỡ dữ liệu bịa — quan trọng về niềm tin người dùng |

> Nếu buộc phải giao rút gọn, **US4 chỉ cần T032 + T033** là đã hết ảnh vỡ. T034–T036
> và T041–T044 là cải thiện trải nghiệm, có thể để đợt sau.

---

## Ghi chú

- `[P]` = khác file, không phụ thuộc
- Nhãn `[Story]` để truy vết — mọi task trong phase US phải có
- **Mọi task triển khai phải có đường dẫn file**
- Viết test trước, xác nhận fail, rồi mới viết code
- **Không commit** gì trừ khi bạn yêu cầu rõ (hiến pháp VI)
- Không sửa mã nguồn backend — chỉ đọc để đối chiếu hợp đồng
- Có thể dừng ở bất kỳ checkpoint nào để kiểm chứng độc lập
- Tránh: task mơ hồ, hai task cùng sửa một file, phụ thuộc chéo làm mất tính độc lập

---

## Phase 9: Convergence

> Sinh bởi `/speckit-converge` sau khi `/speckit-implement` đã chạy trên `tasks.md` hiện tại.
> Đánh giá trạng thái **mã nguồn hiện tại** so với `spec.md` + `plan.md`, không dùng git diff.
> 6 finding: **0 missing · 0 contradicts · 0 unrequested · 6 partial** (2 HIGH, 2 MEDIUM, 2 LOW).
> Đã kiểm 71 mục (35 FR + 11 SC + 22 acceptance scenario + 3 edge case), 9 quyết định plan
> (R1–R9) và 6 nguyên tắc hiến pháp. **Không có vi phạm hiến pháp nào.**

- [X] T052 Sửa `OutfitRecommendationModel.fromJson()` tại `lib/features/stylist/models/stylist_models.dart` để đọc `isFallback` và `remainingQuota` từ JSON, kèm test chống hồi quy trong `test/stylist_recommendation_contract_test.dart` (FR-033, FR-029, FR-030 — partial). **Lý do:** factory hiện bỏ sót hai trường nên khi parse lại từ JSON, cờ dự phòng âm thầm về `false` và hạn mức về `0` — nhãn dự phòng biến mất
- [X] T053 Rút phần trích `id` trong `addItem()` ở `getOutfitRecommendation()` (`lib/features/stylist/data/stylist_repository.dart`) thành null-safe, bỏ ép buộc `brand!`, kèm test cho ca `fashionItem` tồn tại nhưng `id` rỗng và **không có** `brandItem` (FR-017, FR-016 — partial). **Lý do:** dòng `brand!.id` ném lỗi null-check runtime thay vì bỏ qua món, làm hỏng cả lượt gợi ý
- [X] T054 Sửa nhánh copy dự phòng tại `_buildLookbookCarousel()` trong `lib/features/stylist/presentation/stylist_screen.dart`: khi `remainingQuota > 0` thì không được in câu *"đã dùng hết lượt"* vì header đang in *"Còn N lượt"* ngay phía trên — hai câu trái nhau trên cùng một thẻ (FR-030, FR-029 — partial)
- [X] T055 Làm rõ hành vi khi tải lại lịch sử trò chuyện: `ChatMessageModel.fromJson()` không khôi phục `outfitRecommendation`/`suggestedItems` vì máy chủ không gửi (đúng R8/T038) và ứng dụng không có `toJson()`/lưu cục bộ — nên thẻ gợi ý **mất vĩnh viễn** sau khi tải lại. Chốt với người dùng giữa hai lựa chọn (i) ghi nhận đây là giới hạn đã biết trong `quickstart.md` K11, hoặc (ii) lưu cục bộ rồi khôi phục; sau đó cập nhật US4/AC4 cho khớp (FR-024 — partial). **Không** tự chọn phương án vì (ii) làm tăng phạm vi ngoài đặc tả gốc

  > **Đã chốt (2026-10-02): chọn (i) — ghi nhận là giới hạn đã biết.** Cập nhật
  > `spec.md` §Edge Cases + FR-024 và `quickstart.md` §K11, kèm lý do kép (máy chủ không lưu kết
  > quả gợi ý, ứng dụng không cache cục bộ) và lý do loại phương án (ii) vì tăng phạm vi ngoài đặc tả.
- [X] T056 Thêm test khẳng định carousel chỉ hiện khi `msg.suggestedItems` khác rỗng, để `outfitRecommendation` mang model rỗng (`id:''`, `title:''`) do thất bại không làm phát sinh khung gợi ý rỗng (Constitution II, FR-022, FR-023 — partial). Kiểm tra `lib/features/stylist/presentation/stylist_screen.dart` và `lib/features/stylist/providers/stylist_provider.dart:306`
- [ ] T057 Chạy `specs/015-fix-login-stylist-composer/quickstart.md` K1–K11 trên máy thật / trình duyệt và ghi kết quả; **đặc biệt đo thời lượng thực tế của splash** ở cả hai nhánh (phiên hợp lệ, và hết ngân sách 1 giây) rồi điền vào T045/T046/T048/T049. Nếu quan sát thấy nháy trên thiết bị chậm thì mở ngưỡng và cập nhật FR-005 + SC-002 cho khớp — con số 1 giây hiện **chưa** được kiểm chứng thực đo (FR-005, SC-002 — partial)
