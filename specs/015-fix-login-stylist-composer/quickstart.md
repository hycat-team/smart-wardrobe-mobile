# Quickstart: Kiểm chứng 015-fix-login-stylist-composer

Hướng dẫn chạy kiểm chứng end-to-end. Dùng `make` (đã có sẵn ở root repo).

---

## 0. Điều kiện tiên quyết

| Cần | Ghi chú |
|---|---|
| Máy chủ backend đang chạy | `docker compose -f deployments/docker-compose.yml --env-file .env up -d` trong repo BE |
| Cổng backend | **`8080`** — không phải 5000 (xem `Makefile`, biến `DEV_API`) |
| Flutter 3.47.2 | `flutter --version` |
| Tài khoản thử | `user` / `123456` |

Kiểm tra máy chủ trước khi làm bất cứ việc gì:

```powershell
Invoke-WebRequest -Uri "http://localhost:8080/api/v1/categories" -UseBasicParsing | Select-Object StatusCode
# kỳ vọng: StatusCode 200
```

> ⚠ Nếu sửa mã nguồn máy chủ, `docker compose up -d` **không** đủ — phải có `--build`,
> nếu không container vẫn chạy image cũ. Xem `docs/work-log-2026-10-01.md` §6.

---

## 1. Kiểm thử tự động

```powershell
flutter analyze          # kỳ vọng: No issues found
flutter test             # kỳ vọng: các test mới pass
```

Ba file test mới:

| File | Chứng minh |
|---|---|
| `test/auth_session_state_test.dart` | FR-001, FR-002, FR-026, FR-027, FR-028 |
| `test/composer_layout_test.dart` | FR-012…FR-015 |
| `test/stylist_recommendation_contract_test.dart` | FR-016…FR-020, FR-031, FR-032 |

> 3 integration test cần máy chủ thật (`auth_integration_test.dart` ×2,
> `outfit_integration_test.dart` setUpAll). Không có máy chủ thì chúng fail với
> *"Không thể kết nối đến máy chủ backend"* — đây là **trạng thái có sẵn**, không phải
> hồi quy.

---

## 2. Nhóm A+B — Trạng thái phiên và lớp phủ đăng nhập

```powershell
make run     # web trên Edge, cổng 8081
```

### K1 — Không còn nháy màn đăng nhập (SC-001)

1. Đăng nhập một lần bằng `user` / `123456`.
2. **Tải lại trang (F5).**
3. **Kỳ vọng**: thấy màn hình khởi động ngắn → vào thẳng tủ đồ.
   **Không** thấy màn đăng nhập ở bất kỳ khoảnh khắc nào.
4. Đóng tab, mở lại app. **Kỳ vọng**: giống bước 3.

> Gợi ý kiểm tra: thu nhỏ cửa sổ rất hẹp hoặc tạm chặn mạng bằng DevTools → splash phải
> hiện và **không** treo vô hạn.

### K2 — Phủ màn hình khi lấy phiên (FR-007…FR-011)

1. Đăng xuất. Mở lại màn đăng nhập.
2. Nhập tài khoản/mật khẩu, bấm **Đăng nhập**.
3. **Kỳ vọng**: **toàn màn hình** bị phủ, có nhãn tiếng Việt, bấm vô hiu quả.
4. Bấm liên tục vào vị trí nút cũ. **Kỳ vọng**: chỉ **một** yêu cầu gửi đi
   (kiểm tra ở tab Network của DevTools).
5. Đăng nhập sai. **Kỳ vọng**: lớp phủ biến mất, thông báo lỗi tiếng Việt hiện ra.

### K3 — Đăng nhập Google và huỷ giữa chừng (FR-010)

1. Màn đăng nhập → bấm **Tiếp tục với Google**.
2. Chọn tài khoản rồi bấm **Huỷ**, hoặc bấm nút quay lại.
3. **Kỳ vọng**: thoát khỏi trạng thái đang xử lý, màn hình dùng lại được.
   **Không** kẹt vĩnh viễn.

### K4 — Phân biệt lỗi mạng với token hỏng (FR-026…FR-028)

| Bước | Kỳ vọng |
|---|---|
| Đã đăng nhập → tắt mạng → mở lại app | **Giữ phiên**, có thông báo tạm thời, **không** ra màn đăng nhập |
| Bật lại mạng → thử lại | Vào thẳng tủ đồ, phiên còn nguyên |
| Đã đăng nhập → xoá token trong DevTools → mở lại app | Phiên bị xoá, hiện màn đăng nhập |

### K5 — Ngưỡng chống nháy (FR-005, SC-002)

Đo bằng DevTools → Performance, hoặc đơn giản quay video màn hình rồi đếm khung hình:

| Tình huống | Kỳ vọng |
|---|---|
| Mở app, phiên hợp lệ | Splash **không vượt 1 giây** |
| Máy chậm / mạng yếu | Splash vẫn tự biến mất, không treo |
| Đăng xuất hẳn rồi mở app | Splash → **màn đăng nhập** (không nháy qua tủ đồ) |

> ⚠ Số 1 giây là con số đề xuất, **chưa kiểm chứng trên máy thật**. Nếu quan sát thấy
> nháy trên thiết bị chậm, mở ngưỡng và cập nhật FR-005 + SC-002 cho khớp.

---

## 3. Nhóm C — Tràn viền màn Up bài

```powershell
make run
```

1. Vào **Cộng đồng** → **Up bài**.
2. **Kỳ vọng**: dải "HÌNH ẢNH & VIDEO (0/10)" và hai nút "Thêm ảnh" / "Thêm video"
   hiển thị đầy đủ. **Không** có dải cảnh báo vàng-đen "OVERFLOWED".
3. **Thu nhỏ cửa sổ từ từ** về khoảng **300px**.
   **Kỳ vọng**: nút tự xuống dòng, không tràn ngang, vẫn bấm được (FR-013).
4. **Nới rộng lại**. **Kỳ vọng**: bố cục về đúng như hiện tại (FR-014).
5. Thêm tới đủ **10** tệp. **Kỳ vọng**: bộ đếm hiện `(10/10)`, cả hai nút khoá
   (FR-015).

### Kiểm tra bằng nhật ký

Mở DevTools → Console. Trước khi sửa sẽ thấy:

```
A RenderFlex overflowed by 66 pixels on the bottom.
A RenderFlex overflowed by 67 pixels on the right.
```

Sau khi sửa: **không còn** dòng `RenderFlex overflowed` nào sinh ra từ màn Up bài.

> Phạm vi chỉ gồm màn Up bài. Các lỗi tràn viền khác ghi trong nhật ký là **nợ kỹ thuật
> riêng**, không thuộc đợt này — xem `spec.md` § Out of Scope.

---

## 4. Nhóm D — Gợi ý phối đồ của stylist

> Nhóm này **bắt buộc** phải có máy chủ thật, vì nó đọc hợp đồng gợi ý thật.

```powershell
make run
```

### K6 — Ảnh hiện được (SC-005)

1. Vào **Stylist**.
2. Hỏi: `gợi ý phối đồ cho đi làm`
3. **Kỳ vọng**:
   - Dải thẻ gợi ý xuất hiện.
   - **Mỗi thẻ có tên món hiển thị** (không thẻ nào trống).
   - **Mọi ảnh tải được** — không có biểu tượng quần áo thay ảnh.
   - Mỗi thẻ có nhãn vai trò tiếng Việt, ví dụ *Áo*, *Quần / Váy*, *Giày dép*.

### K7 — Ảnh không có thì hiện nhãn vai trò (FR-019)

Món trong tủ đồ chưa qua xử lý ảnh sẽ không có địa chỉ ảnh.
**Kỳ vọng**: thẻ đó hiện **nhãn vai trò** thay vì khung trống hay biểu tượng vỡ.

### K8 — Không gọi gợi ý cho câu hỏi không liên quan (FR-021)

Hỏi: `hôm nay thời tiết thế nào`
**Kỳ vọng**: có câu trả lời văn bản, **không** có dải thẻ gợi ý.

Hỏi: `áo nào hợp với quần nâu`
**Kỳ vọng**: **có** dải thẻ — bộ khoá nhận diện phải bắt được câu này.

### K9 — Gợi ý dự phòng của máy chủ có nhãn (FR-029, SC-010)

Dùng hết hạn mức gợi ý trong ngày rồi hỏi lại.
**Kỳ vọng**:
- Bộ gợi ý hiển thị kèm nhãn **"gợi ý dự phòng"**.
- Hiện **số hạn mức còn lại** (bằng 0) (FR-030).
- **Không** bị trình bày như gợi ý chuẩn.

### K10 — Lỗi được thông báo, không bị thay bằng dữ liệu bịa (FR-022, FR-023)

Tắt máy chủ, hoặc chặn mạng, rồi hỏi stylist về cách phối đồ.
**Kỳ vọng**:
- Phần trả lời văn bản **vẫn còn nguyên**.
- Có thông báo phần gợi ý món đồ tạm thời không có.
- **Không** có danh sách ảnh nào hiện ra (trước đây là bộ Unsplash nhúng sẵn).

> ⚠ Đây là **thay đổi hành vi có chủ đích**. Lỗi trước đây bị nuốt im lặng sẽ giờ hiện
> ra — đã ghi ở `spec.md` § Risks. Khi bàn giao cần nói rõ điều này.

### K11 — Tải lại lịch sử trò chuyện (FR-024, SC-008)

1. Mở một cuộc trò chuyện cũ đã hỏi về phối đồ.
2. Tải lại trang.
3. **Kỳ vọng**: nội dung trò chuyện hiển thị đầy đủ, **không** báo lỗi.
   Thẻ gợi ý **không** quay lại — máy chủ không lưu phần này theo từng tin nhắn
   (xem [contracts/](./contracts/stylist-outfit-recommendation.md) §2).

> **Giới hạn đã biết — đã chốt là hành vi chấp nhận được (spec 015 — T055).**
> Thẻ gợi ý mất **vĩnh viễn** sau khi tải lại, không phải hồi quy. Lý do kép, cả hai
> đều nằm ngoài phạm vi sửa của đợt này:
>
> 1. Máy chủ lưu văn bản trò chuyện nhưng **không** lưu kết quả gợi ý.
> 2. Ứng dụng **không** có `toJson()` cũng không cache cục bộ, nên không có gì để
>    khôi phục.
>
> Phương án lưu cục bộ rồi khôi phục đã được cân nhắc và **loại** vì làm tăng phạm
> vi ngoài đặc tả gốc, đồng thời thêm bề mặt lỗi mới (cache hỏng, schema cũ).
> Nếu sau này cần, mở lại như một feature riêng.
>
> Hệ quả mong muốn: sau khi tải lại, người dùng **hỏi lại** là thẻ gợi ý hiện
> trở lại ngay — không cần sửa gì thêm.

---

## 5. Hồi quy — kiểm chữ ký bằng chứng

Sau mỗi nhóm đã xong, chạy lại phần chưa đụng tới để chắc không phá:

| Nhóm | Phải vẫn chạy |
|---|---|
| A+B xong | K6…K11 (stylist) và K3 (Up bài) |
| C xong | K1…K3, K6…K11 |
| D xong | K1…K5, K3 |

Đặc biệt: đăng nhập Google (`docs/Google_OAuth_Android_Guide.md`) và luồng cộng đồng
phải không hồi quy sau nhóm A+B, vì cả hai đều dựa trên việc chuyển trạng thái phiên.

---

## 6. Ngưỡng bàn giao

- [ ] `flutter analyze` → 0 issues
- [ ] 3 file test mới pass
- [ ] K1…K11 đã chạy, có ghi kết quả
- [ ] Không vi phạm mục nào trong `AGENTS.md`
- [ ] Đã cập nhật `docs/work-log-<ngày>.md`
- [ ] Chưa commit gì — chờ yêu cầu