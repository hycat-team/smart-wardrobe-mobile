# Research: Wardrobe UX Bulk Quota Fixes

**Feature**: specs/004-wardrobe-ux-bulk-quota
**Date**: 2026-09-14
**Scope**: mobile-only (`smart-wardrobe-mobile`); backend (`smart-wardrobe-be`, Go/Gin) checked read-only for contract availability.

## R1 — Swipe-back flicker on ItemDetailScreen

**Context**: `lib/core/router/app_router.dart:133` — `/wardrobe/item/:id` is a top-level `GoRoute` (outside `StatefulShellRoute`), default Material page transition. Both list card (`wardrobe_screen.dart:447`) and detail hero (`item_detail_screen.dart:227`) use the same tag `item_${id}` with default `Hero(transitionOnUserGestures: false)`. Detail body is `CustomScrollView` + pinned `SliverAppBar` + `InteractiveViewer`. Nút mũi tên (`context.pop()`) works fine; only edge-swipe pop flickers (re-flash of detail frame once before list appears).

**Decision**: Keep the shared-element Hero for enter animation, but set `transitionOnUserGestures: true` on BOTH Hero widgets (list card + detail), and gate the detail `ref.watch(wardrobeItemDetailProvider)` rebuild during pop so no new frame is emitted mid-gesture. If flicker persists on device, fallback is `HeroMode(enabled: false)`-style suppression of the flight on pop only (enter animation preserved).

**Rationale**:
- `transitionOnUserGestures: false` (Flutter default) means an interactive swipe-back pop does not drive the Hero flight; the route pops without hero participation, then the framework snaps — producing exactly the reported "giật 1 lần rồi mới về" flash.
- Nút back works because a programmatic pop runs the full non-interactive Hero flight.
- Fix is 2-line + rebuild guard, zero route restructuring, zero new dependencies, preserves the premium Hero enter effect (Quiet Luxury).

**Alternatives considered**:
- Remove Hero entirely → kills the polished enter animation; rejected (UX downgrade).
- Custom page transition / move detail route into shell branch → larger blast radius on bottom-nav state; rejected for this fix (can revisit if fallback needed).
- CupertinoPage transition → changes Android feel; rejected (platform inconsistency).

**Verification**: 20 consecutive edge-swipes on emulator + 1 physical device; no re-flash; list scroll position + thumbnails intact.

## R2 — System catalog endpoints EXIST (verified in FE + BE, corrected 2026-09-14)

**Context**: User pointed out the system-wardrobe feature already exists in `smart-wardrobe-fe` — confirmed:
- FE `src/features/wardrobe/api/wardrobe.api.ts:38` `getSystemCatalogItems` → `GET /system-catalog/wardrobe-items` (`page/limit/categorySlug/q`, paginated `WardrobeItemRes` — SAME shape as my-wardrobe items); `:189` `initClosetFromCatalog` → `POST /wardrobe-items/catalog-init` body `{catalogItemIds: [...]}` → `WardrobeItemRes[]`. FE UX reference `src/app/(user)/wardrobe/explore/components/SystemCatalogClient.tsx` (`/wardrobe/explore`): always-on multi-select grid, 500ms-debounce search, category tabs, pagination, floating bar "Đã chọn N item" + "Thêm vào tủ đồ", success → clear selection + go `/wardrobe`.
- BE `wardrobe/presentation/router/router.go:32` public `GET /system-catalog/wardrobe-items` (query `GetSystemCatalogItemsQueryReq{page,limit,q,categorySlug}`); `wardrobe_item_handler.go:183` `POST /wardrobe-items/catalog-init` → 201 `WardrobeItemBriefRes[]` ("Sao chép hàng loạt các trang phục mẫu từ hệ thống sang tủ đồ cá nhân của user, không tốn quota AI").

**Decision**: Mobile mirrors the FE-verified contract 1:1 — `GET /system-catalog/wardrobe-items` parsed with the EXISTING `WardrobeItemModel.fromJson` (catalog returns `WardrobeItemRes`, identical shape); `POST /wardrobe-items/catalog-init` with `{catalogItemIds}`. Mobile UX mirrors FE: catalog screen with category chips (reuse `GET /categories`), debounced search field, 2-col grid tap-to-toggle select, bottom action bar `Đã chọn N` + `Thêm vào tủ đồ`; success → `loadItems(refresh: true)`, clear selection, pop back to Wardrobe with snackbar. Dedupe: client marks ids already in `wardrobeProvider` as "Đã có trong tủ" (non-selectable). Zero backend work — earlier "pending-BE" assessment was wrong and is withdrawn.

**Rationale**:
- Endpoints exist and are FE-proven in production → zero BE work, zero schema risk (catalog items parse with existing `WardrobeItemModel.fromJson`).
- Mobile UX mirrors FE (`/wardrobe/explore` behavior) so cross-platform behavior stays consistent.

**Alternatives considered**:
- Define new mobile-specific endpoints → unnecessary duplication; rejected.
- Bundle a static in-app catalog → stale data + app-size bloat; rejected.

## R3 — Bulk delete: wardrobe bulk exists, outfits single-only

**Context**: BE `wardrobe_item_handler.go:345` — `DELETE /api/v1/wardrobe-items/bulk` accepts `{ids: [...]}`; mobile `wardrobe_repository.dart:110` already calls it (single-id today). Outfits: BE `outfit_handler.go:179` — only `DELETE /outfits/{id}`; no bulk route. Mobile `outfit_repository.dart:105` + `outfits_list_provider.dart:83` are single-delete.

**Decision**:
- Wardrobe bulk: single `DELETE /wardrobe-items/bulk` with full id list → optimistic removal + total decrement (extend existing `deleteItem` pattern to `deleteItems`), rollback + per-item error on failure, invalidate insights/category providers as today.
- Outfits bulk: sequential `DELETE /outfits/{id}` calls (not parallel — keeps ordering deterministic and avoids BE rate issues), collect per-item success/failure → `BulkDeletionResult{deletedIds, failedIds}` → remove successes, keep failures with message listing failed names + retry. No BE change required.
- Both lists share one selection-mode UX pattern (R5) but keep separate notifiers (existing `WardrobeNotifier` / `OutfitsListNotifier` — no cross-feature state merge).

**Rationale**: Zero backend changes; failure semantics stay honest (partial success is reported, never silent). Extends patterns already in codebase.

**Alternatives considered**:
- Add BE `DELETE /outfits/bulk` → cleaner but cross-repo + migration; rejected for this iteration (mobile sequential is fast enough for <100 outfits; revisit if slow).
- Parallel outfit deletes (`Future.wait`) → faster but failure attribution + ordering harder; rejected (sequential lists are small).

## R4 — AI quota display sync (UI-only, same data source)

**Context**: Both `profile_screen.dart:471` and `subscription_detail_screen.dart:258` already read `subscriptionOverviewProvider.dailyQuota` (`DailyQuotaModel`: `aiOutfitUsed/Limit`, `aiChatUsed/Limit`, defaults 5/3, source `GET /subscriptions/me/daily-quota`). Only the format differs: profile shows `"$used / $limit lượt"` (+ progress), subscription shows `"Còn lại: $remaining / $limit"`. No data bug — pure presentation drift.

**Decision**: Extract one shared widget `AiQuotaDisplay` (in `lib/shared/widgets/` or profile widgets) rendering `"$used/$limit lượt"` + remaining + progress bar + `Tự động reset 00:00` note; use it in BOTH screens with identical props. No repository/provider/contract change. Loading state: skeleton/retry on both (never fake `"0/5"` before data arrives); zero-state and exhausted-state (`remaining == 0`, red highlight + upgrade hint) identical on both.

**Rationale**: Single widget = drift impossible by construction; smallest possible change; no BE involvement.

**Alternatives considered**:
- Fix only subscription screen text inline → drift can recur; rejected.
- New quota endpoint/fields → unnecessary; rejected.

## R5 — Selection-mode UX pattern for bulk delete

**Decision**: Standard pattern applied to both `WardrobeScreen` grid and `OutfitsListScreen` grid: toolbar icon (checkbox-select) or long-press enters selection mode → AppBar morphs to `{count} đã chọn` + select-all + close; tapping cards toggles; bottom action bar (or AppBar action) shows `Xóa (n)` opening confirm dialog with count + warning for processing-status items; result snackbar `Đã xóa n món` / partial-failure dialog with retry. Follows Quiet Luxury tokens (AppColors, BeVietnamPro/Playfair, radius 16–20) and touch target ≥ 44px. `ListTile`-in-colored-`Container` cases wrapped per Gotcha 3; sheets wrapped in `SingleChildScrollView` per Gotcha 4.

**Rationale**: One pattern learned once, applied twice; consistent with existing `_confirmDelete` dialogs.

## Open dependencies (not blockers for mobile tasks)

1. ~~BE catalog endpoints~~ — RESOLVED 2026-09-14: `GET /system-catalog/wardrobe-items` + `POST /wardrobe-items/catalog-init` exist on BE and are FE-proven. No BE work needed.
2. **Device verification**: edge-swipe fix must be confirmed on a real iOS + Android device (emulator gesture differs), per quickstart QS-001.
