# Implementation Plan: Sửa nháy màn login, tràn viền Up bài, gợi ý AI sai

**Branch**: `015-fix-login-stylist-composer` | **Date**: 2026-10-02 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/015-fix-login-stylist-composer/spec.md`

## Summary

Ba lỗi độc lập, cùng khai báo trong một đợt QA:

1. **Nháy màn đăng nhập** — `AuthState` không có trạng thái "đang kiểm tra", router đọc
   trạng thái đồng bộ nên coi người dùng là chưa đăng nhập trong lúc chờ `GET /me`.
2. **Tràn viền Up bài** — dải "HÌNH ẢNH & VIDEO" dùng `Row` + chiều rộng cố định.
3. **Gợi ý AI sai, ảnh vỡ** — ứng dụng parse hợp đồng gợi ý theo dạng phẳng trong khi
   máy chủ trả dạng **nhóm theo vai trò**, nên mọi món ra `imageUrl` rỗng.

Hướng kỹ thuật: thêm một trạng thái phiên trung gian và chặn ở tầng `MaterialApp`;
co giãn bố cục Up bài; và **tái dùng bộ model đã có sẵn** trong repo cho đúng hợp
đồng máy chủ, kèm hai điều chỉnh hành vi phát hiện được khi đọc mã nguồn máy chủ.

## Technical Context

**Language/Version**: Dart 3.13.2 · Flutter 3.47.2 (stable)

**Primary Dependencies**: `flutter_riverpod ^2.5.1` (StateNotifierProvider) ·
`go_router ^14.2.0` · `dio ^5.4.3` · `flutter_secure_storage ^9.2.2` ·
`google_fonts` (Playfair Display + Be Vietnam Pro) · `cached_network_image ^3.3.1`

**Storage**: `flutter_secure_storage` (token/refresh/profile) — web dùng cookie
HttpOnly đánh dấu bằng giá trị giữ chỗ `web_session_active`

**Testing**: `flutter test` (unit + widget). 3 integration test cần BE thật sẽ fail
nếu không có máy chủ — đã biết, phải chứng minh pre-existing.

**Target Platform**: Android (bản phát hành) + Web (dev/QA). Mã dùng chung, một sửa
đổi áp dụng cho cả hai.

**Project Type**: mobile-app + web, feature-first layered
(`lib/core/` → `lib/features/<domain>/{data,models,presentation,providers}/` → `lib/shared/`)

**Performance Goals**: splash tự ẩn trong 1 giây khi phiên hợp lệ (SC-002); không thêm
độ trễ cảm nhận được khi phiên xác nhận nhanh (R3).

**Constraints**: Quiet Luxury — nền `#FAF8F5`, chữ `#1A1A1A`, viền `#E8E3DC`, cấm
`Colors.red`/`Colors.blue` thuần; tiêu đề Playfair Display, nhãn/nút Be Vietnam Pro;
ảnh mạng **bắt buộc** qua `ClosyNetworkImage`; vùng chạm ≥ 44px; chuỗi tiếng Việt không
mojibake.

**Scale/Scope**: 3 nhóm FR, 6 file sửa + 1 file mới + 1 file test. Ba nhóm độc lập về
kỹ thuật, triển khai theo thứ tự A+B → C → D.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Nguyên tắc | Áp dụng cho thay đổi này | Kết quả |
|---|---|---|
| **I. Spec-Driven & Verify-First** | Đi qua pipeline specify → clarify → plan → tasks → implement. Fix > 1 file nên bắt buộc có spec | ✅ Đang ở `/speckit-plan` |
| **II. Kiến trúc & kỷ luật Riverpod** | Cờ mới trong `AuthState` **phải có default** (`true`) để chống `TypeError: Null is not String` khi hot reload web. Business logic qua notifier, không `setState` | ✅ Ghi vào T003 |
| **III. Không mock khi đã có API** | Không sửa máy chủ. Gỡ fallback Unsplash nhúng sẵn (vi phạm nếu giữ). Ưu tiên `ClosyNetworkImage` | ✅ |
| **IV. Quiet Luxury & hiệu năng media** | Splash dùng bảng màu sản phẩm. Lớp phủ đăng nhập có nhãn tiếng Việt. Không sửa `ClosyNetworkImage` (dùng chung 26 chỗ) | ✅ |
| **V. Gotcha Windows & build** | Chỉ sửa file bằng công cụ `edit`/`write`, không dùng `Get-Content | -replace | Set-Content`. Giữ `kotlin.incremental=false` | ✅ |
| **VI. An toàn phát hành** | Không commit secret. Không sửa BE. Route mới không thêm nên không đụng `ENABLE_PAID_FEATURES` / deep-link | ✅ |

**Kết luận gate**: PASS. Không có vi phạm nào cần biện minh. Rà lại sau Phase 1 — xem
mục cuối file.

## Các quyết định kỹ thuật đã chốt (tóm tắt)

Chi tiết và phương án bị loại nằm ở [research.md](./research.md).

| # | Quyết định | Nguồn |
|---|---|---|
| R1 | `getCurrentUser()` **rethrow nguyên `DioException`** thay vì bọc thành `Exception` chuỗi tiếng Việt — hiện tại mất mã trạng thái nên không phân biệt được 401 với lỗi mạng | R1 |
| R2 | Thêm **hai** cờ `isCheckingAuth` (mặc định `true`) và `authCheckFailed` (mặc định `false`) vào `AuthState`; `AppRouterNotifier` phát tín hiệu khi **ba** cờ đổi; `redirect` và splash chặn theo `isCheckingAuth` **hoặc** `authCheckFailed`; splash **chỉ** hiện khi khởi động ứng dụng, không hiện khi đổi phiên giữa phiên | R2 |
| R3 | Splash: đếm ngược 1 giây song song với kiểm tra phiên, ai xong trước thì dùng — không ép thêm độ trễ. Ở trạng thái lỗi tạm thời thì ở lại chờ bấm "Thử lại", **không** tự retry | R3 |
| R4 | Không sửa `ClosyNetworkImage`; nhãn vai trò thay ảnh làm ở widget gợi ý | R4 |
| R5 | Tái dùng `RecommendedOutfitRes` / `RecommendedItemGroup` / `RecommendedItemRes` đã có sẵn, làm phẳng `primary` + `alternatives` ra danh sách có `imageUrl` thật | R5 |
| R6 | Bảng ánh xạ vai trò **đóng**, 8 giá trị theo đúng điển từ BE, **bổ sung `headwear`** và `other` | R6 |
| R7 | Kích hoạt gợi ý = marker `[ACTION:REDIRECT_OUTFIT]` **hoặc** câu khớp bộ khoá từ BE (bỏ dấu + hạ chữ thường). Bỏ `contains('outfit')` | R7 |
| R8 | Bỏ tra cứu `outfitRecommendation`/`suggestedItems` khi đọc lịch sử chat — máy chủ không gửi hai trường đó | R8 |
| R9 | Bỏ `catch (_) {}` trong luồng gợi ý, thay bằng log có tiền tố nhận dạng | R9 |

### Phát hiện quan trọng ảnh hưởng thiết kế

- Prompt máy chủ phát marker `[ACTION:REDIRECT_OUTFIT]` **chỉ khi tủ đồ trống**
  (`chat/helper.go:33-46`); khi tủ đồ có món thì AI tự trả lời trong văn bản và **cố ý
  không** phát marker. Heuristic cũ của ứng dụng gọi endpoint cả khi BE đã trả lời xong
  → lặp nội dung. Xem R7.
- Bảng vai trò hiện có ở ứng dụng **thiếu `headwear`**, rơi xuống `toUpperCase()` nên
  hiện chữ `OTHER`. Xem R6.

## Project Structure

### Documentation (this feature)

```text
specs/015-fix-login-stylist-composer/
├── spec.md                          # Đặc tả (25+7 FR sau clarify, 10 SC)
├── plan.md                          # File này
├── research.md                      # Phase 0 — 10 quyết định đã xác minh
├── data-model.md                    # Phase 1
├── quickstart.md                    # Phase 1 — kịch bản kiểm chứng
├── contracts/
│   └── stylist-outfit-recommendation.md   # Hợp đồng đọc dữ liệu gợi ý
├── checklists/
│   └── requirements.md              # 16/16
└── tasks.md                         # Phase 2 — chưa tạo
```

### Source Code (repository root)

```text
lib/
├── main.dart                                    # M: cổng chặn splash
├── core/
│   ├── network/api_client.dart                  # giữ nguyên (đã có 401 + refresh)
│   └── router/app_router.dart                   # M: không đá về /login khi đang kiểm tra
├── features/
│   ├── auth/
│   │   ├── models/auth_models.dart              # giữ nguyên
│   │   ├── data/auth_repository.dart            # M: rethrow DioException
│   │   ├── providers/auth_provider.dart         # M: isCheckingAuth + authCheckFailed + rẽ nhánh lỗi
│   │   └── presentation/
│   │       ├── login_screen.dart                # M: lớp phủ chặn tương tác
│   │       ├── auth_callback_screen.dart         # giữ nguyên
│   │       └── widgets/
│   │           ├── splash_screen.dart           # M: MỚI
│   │           └── google_sign_in_button.dart    # M: nhả trạng thái khi huỷ
│   ├── community/presentation/
│   │   └── post_composer_screen.dart            # M: co giãn dải media
│   └── stylist/
│       ├── models/stylist_models.dart           # M: + role, isFallback, remainingQuota; bỏ tra cứu trường chết
│       ├── data/stylist_repository.dart         # M: đúng hợp đồng + gỡ fallback
│       ├── providers/stylist_provider.dart      # M: điều kiện kích hoạt + log lỗi
│       └── presentation/stylist_screen.dart      # M: nhãn vai trò + nhãn dự phòng
└── shared/widgets/
    └── closy_network_image.dart                 # giữ nguyên (dùng chung 26 chỗ)

test/
├── auth_session_state_test.dart                 # M: MỚI — 4 trạng thái phiên + rẽ nhánh lỗi
├── composer_layout_test.dart                    # M: MỚI — không tràn ở khung hẹp
└── stylist_recommendation_contract_test.dart    # M: MỚI — parse đúng hợp đồng BE
```

**Structure decision**: giữ nguyên cấu trúc feature-first hiện có. Ba nhóm sửa nằm ở
ba feature khác nhau (`auth`, `community`, `stylist`) nhưng cùng dùng một bộ model gợi ý
đã có sẵn trong `outfit_studio` — sẽ **tái dùng**, không nhân bản (xem R5).

## Thứ tự triển khai

Nhóm A+B (auth) → Nhóm C (Up bài) → Nhóm D (stylist). Ba nhóm độc lập, mỗi nhóm tự
kiểm thử được, có thể dừng giữa chừng mà vẫn bàn giao được phần đã xong.

## Rà lại Constitution Check sau Phase 1

| Nguyên tắc | Kết quả sau thiết kế |
|---|---|
| II — default cho state mới | `isCheckingAuth` có default `true`, `authCheckFailed` có default `false`; getter cờ mới đều nullable-safe |
| III — không mock | Đã **gỡ** fallback Unsplash nhúng sẵn; dữ liệu chỉ từ máy chủ |
| IV — ảnh qua `ClosyNetworkImage` | Giữ nguyên; nhãn vai trò hiển thị khi `imageUrl` rỗng, không thêm `Image.network` |
| VI — không sửa BE | Đã xác minh mọi trường dữ liệu từ repo BE **chỉ để đọc**; không có thay đổi nào đề xuất cho BE |

**Kết luận**: PASS. Sẵn sàng sang `/speckit-tasks`.

## Complexity Tracking

> Không có vi phạm hiến pháp nào. Mục này để trống có chủ đích.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| *(không có)* | — | — |

## Rủi ro còn lại

| Rủi ro | Giảm thiểu |
|---|---|
| Ngưỡng 1 giây có thể vẫn nháy trên máy chậm | T041 bắt buộc đo trên máy thật, mở rộng ngưỡng nếu cần (ghi trong spec) |
| Bỏ `catch (_) {}` làm lộ lỗi trước đây bị che | Đã ghi trong `spec.md` §Risks; cần nêu rõ khi bàn giao |
| Bảng ánh xạ vai trò lệch nếu BE thêm vai trò mới | FR-032 hiển thị nguyên chuỗi gốc — lộ ra ngay thay vì ẩn âm thầm |
| Tái dùng model từ `outfit_studio` ở `stylist` | Tách coupling — chấp nhận được vì cùng hợp đồng máy chủ; ghi chú tại T016 để người sau biết |