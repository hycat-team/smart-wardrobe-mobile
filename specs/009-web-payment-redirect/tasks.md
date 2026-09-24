# Tasks: Web Payment Redirect

**Input**: Design documents from `/specs/009-web-payment-redirect/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: No automated test tasks — not requested in the feature specification. Validation is manual via `quickstart.md` (QS-1…QS-5) in the Polish phase.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Mobile (this project)**: `lib/` source root, feature code under `lib/features/profile/`, routing under `lib/core/router/`, deeplinks under `lib/core/deeplink/`
- Config: `.env` at repository root (single source for website host text)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Inventory payment entry points and confirm static inputs before changing code

- [X] T001 Audit all payment entry points in lib/features/profile/presentation/subscription_upgrade_screen.dart, lib/features/profile/presentation/wallet_detail_screen.dart, lib/features/profile/presentation/widgets/closy_wallet_card.dart, lib/core/router/app_router.dart, lib/core/deeplink/payment_deeplink_handler.dart and record the removal checklist
- [X] T002 [P] Confirm website host display text and Vietnamese copy requirements from specs/009-web-payment-redirect/spec.md into .env as the single source (plain host text only, no plan/amount/user params)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared read-only guidance UI that all user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T003 Create WebGuidanceCard widget in lib/features/profile/presentation/widgets/web_guidance_card.dart (title, websiteHostText as plain text, 3 steps: open browser manually → login with same account → pay/topup on web and return, same-account note, zero onTap/launchUrl/WebView/QR)
- [X] T004 [P] Add website host text constant to .env (single source of truth referenced by WebGuidanceCard, no deep-link params)
- [X] T005 Add stale-link expired message and Vietnamese error-with-retry copy to lib/features/profile/presentation/widgets/web_guidance_card.dart (used by router/deeplink fallback and load-failure states per FR-009/FR-010)

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Xem gói và hướng dẫn lên website thanh toán (Priority: P1) ⭐ MVP

**Goal**: Package screens become read-only (name, VND price, duration, benefits) with text-only web guidance; no checkout can be initiated from the app

**Independent Test**: QS-1 + QS-2 — open the upgrade screen with a Free account, select a paid plan, verify (1) full plan info with `formattedPrice` renders, (2) only `WebGuidanceCard` appears (no QR/checkout/WebView/navigation to waiting/result), (3) no payment link is created

### Implementation for User Story 1

- [X] T006 [US1] Remove direct-purchase initiation and show WebGuidanceCard on plan select in lib/features/profile/presentation/subscription_upgrade_screen.dart (delete createDirectPurchase call, payment_link_opener usage, navigation to PaymentWaitingScreen; keep getSubscriptionPlans rendering with name, formattedPrice, durationDays, features for isActive plans only)
- [X] T007 [P] [US1] Keep subscription detail read-only with web guidance in lib/features/profile/presentation/subscription_detail_screen.dart (plan name, price, expiry, quotas from UserSubscriptionModel/DailyQuotaModel; no purchase actions)
- [X] T008 [P] [US1] Sever direct-purchase call path in lib/features/profile/data/payment_repository.dart (stop calling POST /subscriptions/me/purchase; keep getSubscriptionPlans, getMySubscription, getDailyQuota intact)
- [X] T009 [US1] Remove direct-purchase trigger in lib/features/profile/providers/profile_provider.dart (remove purchase initiation delegating to payment_repository; keep subscription load methods for read-only display)

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - Nạp ví bằng cách lên website (Priority: P1)

**Goal**: Wallet becomes balance + history read-only; top-up form, top-up sheet, and wallet-purchase buttons are fully hidden; top-up need shows text-only web guidance

**Independent Test**: QS-1 + QS-2 (wallet part) — open wallet card and wallet detail screen, verify balance (`formattedBalance`) and statements (`typeLabel`, `formattedAmount`) render, no amount form / `TopUpBottomSheet` / top-up or wallet-purchase button exists, and only `WebGuidanceCard` explains web top-up

### Implementation for User Story 2

- [X] T010 [US2] Remove top-up button/sheet and show web guidance in lib/features/profile/presentation/wallet_detail_screen.dart (delete _openTopUp and Nạp Tiền Vào Ví button opening TopUpBottomSheet; render WebGuidanceCard for top-up need; keep balance, statements list, AppBar refresh and RefreshIndicator for read paths)
- [X] T011 [P] [US2] Remove top-up sheet opener from wallet card in lib/features/profile/presentation/widgets/closy_wallet_card.dart (delete _openTopUpSheet and Nạp Tiền button opening TopUpBottomSheet; show balance with hide/show toggle, Lịch Sử navigation, and WebGuidanceCard text for top-up need)
- [X] T012 [P] [US2] Deprecate TopUpBottomSheet widget in lib/features/profile/presentation/widgets/topup_bottom_sheet.dart (remove all call sites first, then delete the file or leave it unreferenced with no imports; verify zero imports remain)
- [X] T013 [P] [US2] Sever wallet top-up and wallet-purchase call paths in lib/features/profile/data/payment_repository.dart (stop calling POST /subscriptions/me/wallet/topup and POST /subscriptions/me/purchase-with-wallet; keep getWallet and getWalletStatements intact)
- [X] T014 [US2] Remove top-up/purchase delegation in lib/features/profile/providers/profile_provider.dart (remove topUp method calling createWalletTopUp and any wallet-purchase trigger; keep loadWallet and statements loading)
- [X] T015 [P] [US2] Remove top-up delegate in lib/features/profile/data/profile_repository.dart (remove createWalletTopUp delegating to payments.createWalletTopUp; keep wallet read delegates)

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - Đồng bộ trạng thái sau thanh toán web (Priority: P2)

**Goal**: Subscription + wallet auto-reload when returning to the app / reopening screens; stale pre-migration payment links never open checkout

**Independent Test**: QS-3 + QS-4 — pay/topup on the website with the same account, return to the backgrounded app, verify new plan/limits/balance/statements appear within 2 minutes with no manual refresh; repeat before web completion and verify old state plus retry-later hint with no false success

### Implementation for User Story 3

- [X] T016 [US3] Auto-reload subscription on resume/reopen in lib/features/profile/presentation/subscription_upgrade_screen.dart (WidgetsBindingObserver didChangeAppLifecycleState resumed → reload getMySubscription/getDailyQuota/getSubscriptionPlans; reopen reload; unfinished web transaction keeps old state with retry-later hint)
- [X] T017 [P] [US3] Auto-reload wallet on resume/reopen in lib/features/profile/presentation/wallet_detail_screen.dart (resumed → reload getWallet/getWalletStatements; unfinished web transaction keeps old balance with retry-later hint)
- [X] T018 [P] [US3] Redirect stale payment routes to expired message plus guidance in lib/core/router/app_router.dart (payment waiting/result routes no longer open checkout; show expired notice with WebGuidanceCard)
- [X] T019 [P] [US3] Neutralize payment deeplinks in lib/core/deeplink/payment_deeplink_handler.dart (smartwardrobe:// subscription/wallet payment links no longer navigate to checkout; route to expired notice with WebGuidanceCard)
- [X] T020 [P] [US3] Deprecate checkout opener in lib/features/profile/utils/payment_link_opener.dart (remove all payment launchUrl call sites; leave no reachable checkout opener)

**Checkpoint**: All user stories should now be independently functional

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Compliance sweep and end-to-end validation across all stories

- [X] T021 [P] Sweep for forbidden payment paths via grep in lib/ (no launchUrl/paymentUrl/PendingPayment/TopUpBottomSheet/purchase-with-wallet references reachable from package or wallet UI; document results)
- [X] T022 Run flutter analyze in C:\FPT\Project\smart-wardrobe\smart-wardrobe-mobile and fix all new warnings in touched files
- [X] T023 Run quickstart validation QS-1 through QS-5 in specs/009-web-payment-redirect/quickstart.md and record pass/fail per scenario (SC-001/SC-002/SC-003 gate the release)
- [X] T024 [P] Verify Vietnamese copy consistency for guidance, expired-link, and error-retry states across lib/features/profile/presentation/subscription_upgrade_screen.dart, lib/features/profile/presentation/wallet_detail_screen.dart, lib/features/profile/presentation/widgets/closy_wallet_card.dart, lib/features/profile/presentation/widgets/web_guidance_card.dart

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P1 → P2)
- **Polish (Final Phase)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P1)**: Can start after Foundational (Phase 2) - Shares provider/repository files with US1 by phase order but independently testable per QS-1/QS-2 wallet scope
- **User Story 3 (P2)**: Can start after Foundational (Phase 2) - Builds on US1/US2 screens for reload behavior but independently testable per QS-3/QS-4

### Within Each User Story

- Core removal before guidance wiring in the same screen
- Repository severing before provider cleanup
- Story complete before moving to next priority

### Parallel Opportunities

- T002 with T001; T004 with T003
- US1: T007, T008 in parallel after T006 starts (different files)
- US2: T011, T012, T013, T015 in parallel (different files); T014 after T013; T010 leads the story
- US3: T017, T018, T019, T020 in parallel (different files); T016 leads the story
- Polish: T021, T024 in parallel; T022 before T023

---

## Parallel Example: User Story 2

```bash
# Lead with the wallet detail screen (sets the pattern):
Task: "T010 Remove top-up button/sheet and show web guidance in lib/features/profile/presentation/wallet_detail_screen.dart"

# Then launch independent files together:
Task: "T011 Remove top-up sheet opener from wallet card in lib/features/profile/presentation/widgets/closy_wallet_card.dart"
Task: "T012 Deprecate TopUpBottomSheet widget in lib/features/profile/presentation/widgets/topup_bottom_sheet.dart"
Task: "T013 Sever wallet top-up and wallet-purchase call paths in lib/features/profile/data/payment_repository.dart"
Task: "T015 Remove top-up delegate in lib/features/profile/data/profile_repository.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Test User Story 1 independently (QS-1 + QS-2 package scope)
5. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Deploy/Demo (MVP!)
3. Add User Story 2 → Test independently → Deploy/Demo
4. Add User Story 3 → Test independently → Deploy/Demo
5. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1
   - Developer B: User Story 2
   - Developer C: User Story 3 (starts after A/B touch shared screens, or coordinates on shared files)
3. Stories complete and integrate independently

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence
