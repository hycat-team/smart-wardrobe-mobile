# Feature Specification: App Logo Update

**Feature Branch**: `008-app-logo-update`

**Created**: 2026-09-24

**Status**: Draft

**Input**: User description: "tui muốn thay đổi logo hiện tại bằng ảnh logo trong thư mục "C:\FPT\Project\smart-wardrobe\logo""

## Clarifications

### Session 2026-09-24

- Q: Nên thay logo ở những mặt hiển thị nào trong lần này? → A: Launcher + header login (app icon Android/iOS và placeholder ở màn login; các màn khác giữ nguyên).
- Q: Header màn login nên hiển thị logo mới theo kiểu nào? → A: Ảnh full lockup, bỏ khung (dùng logo-full.png hiển thị trực tiếp, gỡ bỏ khung bo tròn + icon checkroom cũ).
- Q: Logo PNG trong suốt nên xử lý nền thế nào để nổi trên cả sáng và tối? → A: Giữ nguyên, kiểm tra thực tế (dùng ảnh gốc, chỉ thêm nền khi kiểm tra phát hiện bị chìm).
- Q: Icon launcher Android (adaptive icon) nên dùng nền gì phía sau logo-only? → A: Màu brand primary (nền AppColors.primary, logo nổi lên trên).
- Q: Có máy Mac/Xcode để build và kiểm tra icon iOS không? → A: Có, verify cả 2 nền tảng (kiểm tra thực tế trên thiết bị Android và iOS).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - New app icon on device (Priority: P1)

A user who has the app installed sees the new Closy brand logo as the app icon on their phone home screen / app drawer instead of the default Flutter icon.

**Why this priority**: The launcher icon is the most visible brand surface; shipping only this already delivers recognizable value.

**Independent Test**: Install a fresh build on Android and iOS, then visually confirm the home-screen icon shows the new logo (no default Flutter icon remains).

**Acceptance Scenarios**:

1. **Given** a fresh install of the app, **When** the user looks at the device home screen / app list, **Then** the app icon displays the new logo artwork.
2. **Given** the app is installed, **When** the user views the app info / settings entry for the app, **Then** the same new logo artwork is shown (not the old default icon).

---

### User Story 2 - New logo in login / brand header (Priority: P2)

A user opening the login screen sees the new Closy full-lockup logo image in the brand header, shown directly with no surrounding rounded frame, replacing the generic placeholder (rounded square with `checkroom` icon).

**Why this priority**: Removes the placeholder branding inside the app and makes the brand consistent with the new logo set.

**Independent Test**: Open the login screen and confirm the header shows the new logo image with correct proportions and no placeholder icon.

**Acceptance Scenarios**:

1. **Given** the user opens the login screen, **When** the brand header renders, **Then** the full-lockup logo image (`logo-full.png`) is displayed directly with no surrounding frame or generic icon.
2. **Given** the user opens the login screen on small and large screen sizes, **When** the header renders, **Then** the logo keeps correct aspect ratio, is not cropped or stretched, and does not break the layout.

---

### User Story 3 - Consistent logo across brand surfaces (Priority: P3)

A user sees the correct logo variant in each context: the full lockup where horizontal space allows, the icon-only mark where space is square/compact.

**Why this priority**: The source folder contains three variants (`logo-full.png`, `logo-only.png`, `logo-text.png`); using the right variant per surface keeps the brand legible.

**Independent Test**: Review each updated surface (launcher icon, login header, any splash/about header included in scope) and confirm the variant used is legible at that size.

**Acceptance Scenarios**:

1. **Given** a compact square surface (launcher icon, small header mark), **When** it renders, **Then** the icon-only variant is used and remains recognizable.
2. **Given** a wide header surface (login brand header), **When** it renders, **Then** the full lockup variant is used and text in the logo is legible.

---

### Edge Cases

- What happens when a logo PNG has transparency and is shown on light vs. dark backgrounds? Logo must remain visible on both (background treatment or appropriate variant).
- How does the app handle missing or unreadable source files in `C:\FPT\Project\smart-wardrobe\logo`? Setup must fail with a clear message naming the missing file instead of silently keeping the old logo.
- What happens on high-density screens (xxhdpi / @3x)? Launcher and in-app images must not appear blurry or pixelated.
- What happens if the logo image is much larger (900KB+ source files) than needed? Shipped assets must be sized/compressed so app size and load time do not regress noticeably.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: App MUST display the new Closy logo as the Android launcher icon, replacing the current default Flutter icon (`android/app/src/main/res/mipmap-*/ic_launcher.png`). The adaptive-icon background behind the `logo-only` mark MUST be the brand primary color.
- **FR-002**: App MUST display the new Closy logo as the iOS app icon, replacing the current default icon set.
- **FR-003**: App MUST display the full-lockup logo image (`logo-full.png`) directly in the login screen brand header — the old rounded container and `checkroom` icon (`lib/features/auth/presentation/login_screen.dart`) MUST be removed, not reused.
- **FR-004**: App MUST bundle the logo images from `C:\FPT\Project\smart-wardrobe\logo` (`logo-full.png`, `logo-only.png`, `logo-text.png`) as declared app assets so they render on-device without network access.
- **FR-005**: App MUST use the icon-only variant (`logo-only.png`) for square/compact surfaces (launcher icon, small marks) and the full lockup (`logo-full.png`) for wide brand headers, preserving each image's aspect ratio without stretching or cropping the mark.
- **FR-006**: Logo artwork MUST be used as-is (no forced background added upfront); legibility on light and dark backgrounds MUST be verified visually on-device, and a background treatment added only where verification shows the logo sinks into the background.
- **FR-007**: Launcher icons MUST be provided at all required densities/sizes for Android (mipmap buckets) and iOS (AppIcon sizes) so no blurry fallback or missing-size warning occurs.

### Key Entities

- **Logo Asset Set**: The three source images (`logo-full` — full lockup, `logo-only` — icon mark, `logo-text` — wordmark); attributes include variant, proportions, transparency.
- **Brand Surface**: Each place the logo appears (Android launcher icon, iOS app icon, login brand header); attributes include surface shape/size, background, required variant.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of brand surfaces in scope (Android launcher, iOS icon, login header) show the new logo; zero occurrences of the old default icon or placeholder remain on those surfaces.
- **SC-002**: Logo is recognizable and legible on all in-scope surfaces when reviewed on at least one physical Android device and one physical iOS device (no cropping, stretching, or invisible-on-background states).
- **SC-003**: Users can identify the app by its new icon on the home screen on first glance (verified by a 5-person hallway check with 5/5 correct identification).
- **SC-004**: App download/install size increases by no more than 5 MB compared to the build before the logo change.

## Assumptions

- Source of truth is the local folder `C:\FPT\Project\smart-wardrobe\logo` containing `logo-full.png` (~926KB), `logo-only.png` (~738KB), `logo-text.png` (~521KB).
- Variant mapping default: `logo-only.png` → launcher icons and compact square marks; `logo-full.png` → login/wide brand headers; `logo-text.png` reserved for future use unless a surface explicitly needs the wordmark alone.
- In-app scope for this change is confirmed as launcher icons + login brand header only; register, onboarding, splash, and other screens are out of scope and keep their current appearance.
- Logo files may be downscaled/compressed copies for shipping; originals stay untouched in the source folder.
- Project constitution (`constitution.md`) is an unfilled template, so no additional governance constraints apply beyond standard review and testing.
