# Hướng dẫn chụp screenshot cho Play Store

Google Play **yêu cầu screenshot của ứng dụng thật**. Ảnh mockup trong
`assets/mockups/` không dùng được vì chúng tiếng Anh, vẽ trong khung iPhone
giả, khác app thật.

Yêu cầu: tối thiểu 2, khuyến nghị 8 (Play hiển thị tối đa 8 ảnh).

---

## Chuẩn bị

| Mục | Giá trị |
|---|---|
| Máy | Android thật, màn từ 1080×2400 trở lên |
| Tài khoản | `user` / `123456` |
| App | **bản cài từ Play (Internal testing)**, không phải debug build |
| Cần dữ liệu | ≥ 4 món tủ đồ, ≥ 2 bộ phối, ≥ 1 bài đăng cộng đồng |

Vì sao phải từ bản Play: app debug có thanh debug overlay và `dart-define`
khác. Ảnh chụp từ bản debug sẽ lệch với app người dùng thấy.

## Cài app lên máy thật để chụp thử (nhanh hơn Play)

Có thể cài APK release đã build sẵn, không cần chờ upload Play:

```powershell
# File: build\app\outputs\flutter-apk\app-release.apk
```

Cách cài: xem `docs/Install_APK_Guide.md`. APK này **trỏ API production**
(`https://api.closy.hycat.online/api/v1`), dữ liệu thật nên nhớ đừng xoá nhầm
tài khoản `user`.

Ảnh chụp từ APK và từ bản Play giống nhau về giao diện (cùng code, cùng
`--dart-define`). Nhưng **nội dung phải submit nên chụp từ bản Play** để khớp
hoàn toàn với thứ người dùng tải.

## Chuẩn kỹ thuật

- Định dạng: PNG hoặc JPEG, cạnh ngắn từ 320px trở lên
- Tỉ lệ: giữ nguyên tỉ lệ màn máy, **không crop**, không viền, không khung
- Không có dữ liệu cá nhân của người thật
- Không có trạng thái lỗi/loading

Play hiển thị ảnh đầu tiên nổi bật nhất — nên để ảnh đẹp nhất ở vị trí 1.

---

## Danh sách 8 màn nên chụp

### 1. Tủ đồ (ảnh chính — đặt vị trí 1)
Điều hướng: Tủ đồ → tab All

Cần: lưới 2 cột đầy đủ, mỗi món có ảnh đẹp, tách nền rõ.

Đây là màn hình bán được nhiều nhất. Nên chọn bộ sưu tập màu sắc hài hòa,
tránh tập hỗn tạp.

### 2. Chi tiết món đồ
Từ tủ đồ, bấm 1 món.

Cần: ảnh lớn, tên, danh mục, style, màu, giá, số lần mặc.

### 3. Phối đồ AI — kết quả
Điều hướng: Phối đồ AI → tạo gợi ý (tab "AI Gợi Ý Phối Đồ").

Cần: kết quả gợi ý hiển thị đầy đủ, có nhiều món và ảnh.

Đây là tính năng AI — ảnh quan trọng với người dùng tải app.

### 4. Outfit Studio — canvas
Điều hướng: Phối đồ AI → tab "Studio Thủ Công", bấm thêm 2-3 món lên canvas.

Cần: canvas có đồ đặt rõ, khay tủ đồ mở bên dưới, nút "Lưu" dính đáy.

Tính năng khác biệt nhất so với app đối thủ, nên ảnh này nên có caption.

### 5. Tủ bộ phối đã lưu
Điều hướng: Studio → nút lưu ở góc phải.

Cần: lưới 2 cột các bộ phối đã lưu, có ảnh bìa đẹp.

### 6. Chi tiết bộ phối
Bấm 1 bộ phối trong danh sách.

Cần: ảnh bìa chiếm phần lớn khung hình, tên bộ phối, ngày, các món đồ.
Đây là màn hình mới sửa gần đây (ảnh bìa ~78% khung, thanh nút dính đáy).

### 7. Cộng đồng — bảng tin
Điều hướng: Cộng đồng.

Cần: danh sách bài đăng có ảnh thời trang đẹp.

### 8. Hồ sơ
Điều hướng: Hồ sơ.

Cần: ảnh đại diện, tên, thẻ gói, menu.

---

## Mẹo

**Chuẩn bị dữ liệu trước.** Đăng nhập `user/123456` sẵn, tải sẵn ảnh chất lượng
cao vào tủ đồ, tạo sẵn bộ phối. Chụp ảnh trên dữ liệu rác sẽ khiến ảnh xấu.

**Dùng chế độ sáng.** Ảnh sáng tốt hơn ảnh tối trên Play Store.

**Ẩn bàn phím.** Trước khi chụp, đóng bàn phím và các hộp thoại.

**Cắt từng màn riêng.** Dùng phím tắt chụp màn hình rồi crop ảnh ra, không
chụp liên tục nhiều màn trong một ảnh.

---

## Sau khi chụp

Upload vào Play Console → **Main store listing** → **Phone screenshots**.

Chọn ảnh theo thứ tự ưu tiên trong danh sách trên. Ảnh đầu tiên sẽ hiện
trên trang tìm kiếm Google Play, nên để ảnh tủ đồ (số 1).

---

## Lưu ý về icon và feature graphic

| Tài nguyên | Nguồn | Ghi chú |
|---|---|---|
| App icon 512×512 | `android/app/src/main/res/mipmap-*/ic_launcher.png` | Play tự sinh từ icon trong app |
| Feature graphic 1024×500 | `assets/mockups/*.jpg` | Được phép dùng mockup cho mục này |

Feature graphic **không** bị ràng buộc phải là screenshot thật, nên ảnh mockup
chất lượng cao trong repo dùng được. Ảnh phù hợp:
`wardrobe_outfit_studio_1788790978388.jpg`.

---

Nội dung chữ (tên app, mô tả, Data Safety) đã soạn sẵn trong
`docs/Store_Listing.md`.
