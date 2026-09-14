# Contract — AI Quota Display (no contract change)

**Status**: ✅ No backend/API change. Single source already exists and is shared.

## Source of truth (existing)

```text
GET /api/v1/subscriptions/me/daily-quota
→ DailyQuotaModel{ aiOutfitUsed, aiOutfitLimit (=5 default),
                    aiChatUsed,  aiChatLimit  (=3 default) }
→ exposed via subscriptionOverviewProvider.dailyQuota
```

Both `ProfileScreen` and `SubscriptionDetailScreen` already consume this same provider instance.

## Display contract (the actual fix — presentation only)

One shared widget `AiQuotaDisplay(used, limit)` used by BOTH screens:

| Element | Rule |
|---|---|
| Primary text | `"$used/$limit lượt"` (exact — e.g. `0/5 lượt`), both screens, both quota types |
| Secondary | `Còn n lượt` + progress bar (`used/limit`, orange ≥ 90%) |
| Reset note | `Tự động reset 00:00` shown on both screens |
| Loading | skeleton shimmer on both — NEVER render `"0/5"` before data arrives |
| Error | retry affordance on both — NEVER render default-constructed numbers as real data |
| Exhausted (`remaining == 0`) | red accent + hint `Hết lượt hôm nay — chờ reset 00:00 hoặc nâng cấp gói`, identical both screens |

## Invariants

1. No second fetch: both screens read the same `dailyQuota` object (no local copies, no drift).
2. After any AI usage, both screens reflect the new numbers after the existing overview refresh (no extra polling added).
3. Day rollover: numbers update on next `loadOverview()`; no client-side date math.
