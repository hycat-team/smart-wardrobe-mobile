# Tasks: App Logo Update

**Input**: Design documents from `/specs/008-app-logo-update/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/logo-assets.md, quickstart.md

**Tests**: No automated test tasks — not requested in spec. Verification is physical-device checks per quickstart.md (wired into story tasks below).

**Organization**: Tasks grouped by user story; US1 alone is the MVP increment.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Exact file paths in every description

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Confirm inputs and baseline before touching any shipped file

- [X] T001 Verify source art readable at `C:\FPT\Project\smart-wardrobe\logo\logo-only.png` and `C:\FPT\Project\smart-wardrobe\logo\logo-full.png`, record SHA-256 of current `android/app/src/main/res/mipmap-*/ic_launcher.png` files and baseline release install size (for SC-004 delta)
- [X] T002 Declare `assets/images/` bundle in `pubspec.yaml` under `flutter.assets` and create `assets/images/` directory

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Generate every resized output from the 1254px sources once — all story phases consume these files

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T003 Generate resized logo outputs to a temp dir (NOT committed): Android legacy tiles 48/72/96/144/192px with safe-zone padding from `logo-only.png`; Android adaptive foreground tile from `logo-only.png`; iOS AppIcon set (all 16 `Contents.json` slots incl. 1024px, opaque, padded) from `logo-only.png`; in-app copy of `logo-full.png` with longest edge ≤512px — all preserving aspect ratio with no stretch/crop of the mark (contract rules 1–3)

**Checkpoint**: All resized files exist and visually inspected at 100% — story implementation can now begin

---

## Phase 3: User Story 1 - New app icon on device (Priority: P1) ✅ MVP

**Goal**: Launcher shows the Closy mark instead of the Flutter default icon on Android and iOS

**Independent Test**: Fresh install on Android + iOS; home-screen and app-info icons show the new logo (spec US1 acceptance scenarios; quickstart steps 3–4)

### Implementation for User Story 1

- [X] T004 [P] [US1] Replace legacy icons `android/app/src/main/res/mipmap-mdpi/ic_launcher.png` (48px), `mipmap-hdpi` (72px), `mipmap-xhdpi` (96px), `mipmap-xxhdpi` (144px), `mipmap-xxxhdpi` (192px) with generated tiles from T003 (contract rule 4)
- [X] T005 [P] [US1] Add adaptive icon `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` + `ic_launcher_round.xml` with `#111111` background (`android/app/src/main/res/values/colors.xml` `ic_launcher_background`, contract rule 4) and white-tiled foreground; leave `AndroidManifest.xml` `android:icon` reference unchanged
- [X] T006 [P] [US1] Replace all 16 image files in `ios/Runner/Assets.xcassets/AppIcon.appiconset/` with generated copies from T003, leaving `Contents.json` unchanged and keeping the 1024px image alpha-free (contract rule 5)
- [ ] T007 [US1] Build release APK and verify on physical Android device per quickstart step 3 (home-screen + app-info icon, no Flutter default remaining; depends on T004, T005)
- [ ] T008 [US1] Build release IPA via Xcode and verify on physical iOS device per quickstart step 4 (home-screen + settings/Spotlight sizes crisp; depends on T006)

**Checkpoint**: US1 fully functional and testable independently — shippable MVP

---

## Phase 4: User Story 2 - New logo in login brand header (Priority: P2)

**Goal**: Login header shows the full `CLOSY` lockup directly, placeholder removed

**Independent Test**: Open login screen on smallest and largest supported sizes; lockup centered, correct aspect ratio, no frame/clipping, blends into `#FAFAFA` (spec US2 acceptance scenarios; quickstart step 5)

### Implementation for User Story 2

- [X] T009 [P] [US2] Ship in-app copy to `assets/images/logo-full.png` (generated file from T003, longest edge ≤512px; contract rule 6)
- [X] T010 [US2] Edit `lib/features/auth/presentation/login_screen.dart`: delete the 68×68 rounded placeholder `Container` + `Icons.checkroom_rounded` block and render `Image.asset('assets/images/logo-full.png')` with aspect-preserving fit at ~200–240 logical px width (contract rule 2; depends on T009)
- [ ] T011 [US2] Run `flutter analyze` on touched files and verify login header on small + large screen sizes per quickstart step 5 (depends on T010)

**Checkpoint**: US1 AND US2 both work independently

---

## Phase 5: User Story 3 - Consistent logo across brand surfaces (Priority: P3)

**Goal**: Correct variant on every surface, legible everywhere, hallway check passed

**Independent Test**: Variant audit matches contract rules 1–3 on all three surfaces + 5/5 hallway identification (SC-003)

### Implementation for User Story 3

- [ ] T012 [US3] Perform cross-surface variant/legibility audit (launcher = `only`, login = `full`, no stretch/crop/invisible-on-background per contract rules 1–3) and run the 5-person hallway identification check (depends on US1 + US2 complete)

**Checkpoint**: All user stories independently functional

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final gates before done

- [ ] T013 Run full `quickstart.md` validation (steps 1–6) and confirm install-size delta vs. T001 baseline is ≤ +5MB (SC-004)
- [X] T014 Run `flutter analyze` + existing `flutter_test` suite with zero regressions and delete the T003 temp generation dir (originals in `C:\FPT\Project\smart-wardrobe\logo` untouched)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Setup — BLOCKS all user stories
- **User Stories (Phase 3–5)**: Depend on Foundational; then proceed in parallel (if staffed) or priority order (P1 → P2 → P3)
- **Polish (Phase 6)**: Depends on all desired stories complete

### User Story Dependencies

- **US1 (P1)**: After Foundational — no other story dependencies
- **US2 (P2)**: After Foundational — independent of US1 (different files: `login_screen.dart` + `assets/images/` vs. platform icon dirs)
- **US3 (P3)**: Depends on US1 + US2 visible output (audit task)

### Within Each User Story

- Consume T003 outputs → place files → device verification
- T007 depends on T004, T005; T008 depends on T006; T011 depends on T010; T012 depends on US1+US2

### Parallel Opportunities

- T001 + T002 (different locations, no shared files)
- T004, T005, T006 (android mipmaps vs. android anydpi vs. iOS appiconset — disjoint paths)
- T009 can run parallel with T004/T005/T006
- US1 and US2 implementation can proceed in parallel after Phase 2 (disjoint file sets)

---

## Parallel Example: User Story 1

```bash
# Launch all US1 file placements together (disjoint paths, share only T003 outputs):
Task: "Replace legacy icons android/app/src/main/res/mipmap-*/ic_launcher.png (T004)"
Task: "Add adaptive icon mipmap-anydpi-v26 + colors.xml background (T005)"
Task: "Replace ios/Runner/Assets.xcassets/AppIcon.appiconset images (T006)"
# Device verifications run after: T007 (Android), T008 (iOS) in parallel on two devices
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001–T002)
2. Complete Phase 2: Foundational (T003)
3. Complete Phase 3: User Story 1 (T004–T008)
4. **STOP and VALIDATE**: Fresh-install check on both devices
5. Deploy/demo if ready

### Incremental Delivery

1. Setup + Foundational → generation outputs ready
2. Add US1 → verify independently → Deploy/Demo (MVP!)
3. Add US2 → verify independently → Deploy/Demo
4. Add US3 audit → hallway check → Deploy/Demo

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to user story for traceability
- Contract references are `specs/008-app-logo-update/contracts/logo-assets.md` rules 1–7
- Never edit originals in `C:\FPT\Project\smart-wardrobe\logo`; never assume transparency
- Commit after each task or logical group
