# Data Model: Wardrobe UX Bulk Quota Fixes

**Feature**: specs/004-wardrobe-ux-bulk-quota
**Note**: Reuses existing models where they exist; only new shapes are specified here.

## Existing (reused, no change)

| Entity | Location | Reused fields |
|---|---|---|
| `WardrobeItemModel` | `lib/features/wardrobe/models/wardrobe_models.dart` | `id`, `status` (3=processing, 4=failed, 5=needsReview), `taskId`, `category`, `fashionItem`, `price`, `displayTitle`, `displayImageUrl` |
| `FashionItemModel` | same file | `id`, `imageUrl`, `color`, `colorHex`, `style`, `material`, `pattern`, `fit`, `seasonality`, `brandName`, `description`, `category` |
| `CategoryModel` | same file | `slug`, `name` |
| `UserOutfitModel` | `lib/features/outfit_studio/models/outfit_models.dart` | `id`, `name`, `coverImageUrl`, `items`, `formattedDate` |
| `DailyQuotaModel` | `lib/features/profile/models/user_profile_models.dart` | `aiOutfitUsed/Limit`, `aiChatUsed/Limit`, `outfitProgress/chatProgress`, `outfitRemaining/chatRemaining` (defaults 5/3) |
| `UserSubscriptionModel` | same file | `planSlug`, `planName`, `isPremium`, `maxWardrobeItems`, `expiresAt` |

## New — SystemCatalogItem (client view, FE/BE-verified shape)

Catalog items returned by `GET /system-catalog/wardrobe-items` have the SAME JSON shape as `WardrobeItemRes` → parsed with the EXISTING `WardrobeItemModel.fromJson`. No new model class needed; this section only defines client-side derived state:

- `catalogItem: WardrobeItemModel` (required) — id, imageUrl, category, attributes reused as-is.
- `inMyWardrobe: bool` (derived client-side, NOT from server) — `true` when any `wardrobeProvider` item has the same `id` → card shows "Đã có trong tủ", non-selectable.
- Add request: `{ "catalogItemIds": [...] }` → `POST /wardrobe-items/catalog-init` (verified contract, see `contracts/system-catalog.md`).

**Validation**: add-request MUST be non-empty; all ids MUST be non-`inMyWardrobe` at confirm time (re-checked, list may change while browsing); add button disabled while request in flight (anti-double-submit).

## New — BulkDeletionResult (client-only)

- `deletedIds: List<String>` — removed from local list + counted in success message.
- `failedIds: List<String>` — kept in local list; surfaced with names + retry action.
- Invariant: `deletedIds + failedIds == requestedIds` (no silent drops). Empty request is a no-op (delete action disabled at 0 selection).

**State transitions (per list)**: `normal → selecting(n≥0) → confirming(n) → deleting → done(all) | partial(failed>0 → stay in normal with error dialog + retry(failedIds))`. Cancel at `confirming` changes nothing.

**Special rule**: items with `status == 3` (AI processing) selected for delete trigger an extra warning line in the confirm dialog ("món đang được AI phân tích"); deletion proceeds normally on confirm.

## New — SelectionState (client-only, per screen)

- `isSelecting: bool` (default false).
- `selectedIds: Set<String>` (default empty).
- Derived: `selectedCount`, `allSelected` (vs visible filtered list), `canDelete = selectedIds.isNotEmpty && !isDeleting`.
- Entering: via AppBar select-action or card long-press. Exiting: close action, successful delete, or back navigation (selection cleared, no side effects).

## Changed (presentation only) — AiQuotaDisplay props

Shared widget input (both Profile + Subscription screens):
- `used: int`, `limit: int` (required) — renders `"$used/$limit lượt"` (exact format, Vietnamese suffix).
- `remaining = (limit - used).clamp(0, limit)`, `progress = limit > 0 ? used/limit : 0`.
- States: `loading` (skeleton, never `"0/5"` placeholder), `error` (retry affordance, no fake numbers), `exhausted` (`remaining == 0` → red accent + "Hết lượt — reset 00:00 / nâng cấp" hint), `normal`.
- Both screens MUST pass values from the same `subscriptionOverviewProvider.dailyQuota` instance (no second fetch, no local copy).

## Relationships

```text
WardrobeScreen (selecting) ──uses──▶ WardrobeItemModel ──bulk──▶ DELETE /wardrobe-items/bulk {ids}
OutfitsListScreen (selecting) ──uses──▶ UserOutfitModel ──sequential──▶ DELETE /outfits/{id}
SystemCatalogScreen ──views──▶ WardrobeItemModel (catalog) ──add──▶ POST /wardrobe-items/catalog-init {catalogItemIds}
ProfileScreen + SubscriptionDetailScreen ──share──▶ AiQuotaDisplay(DailyQuotaModel)
```
