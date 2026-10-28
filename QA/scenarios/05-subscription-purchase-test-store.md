---
id: 05-subscription-purchase-test-store
setup: [create-user]
login: api
cleanup: [delete-user]
---
# Subscription purchase through the RevenueCat Test Store

Steps:
1. The app starts signed in as `$EMAIL`: `main.summary.card` is visible.
2. Tap `tabBar.statsTab`; `analytics.unlockButton` is visible, tap it.
3. On the subscription screen tap `subscription.plan.vault.subscription.premium.button` (if the id differs, tap the only plan's button).
4. In the Test Store sheet choose the successful purchase option.
5. Run `scripts/qa/rc-sync.sh $EMAIL INITIAL_PURCHASE` and `scripts/qa/wait-subscription.sh $EMAIL PREMIUM`.
6. Go back to `tabBar.statsTab`.

Expected:
- After step 2 `subscription.title` is visible.
- Step 5 commands exit with 0.
- After step 6 `analytics.unlockButton` is gone and `analytics.chart` or `analytics.body.emptyText` is visible.

If the Test Store sheet has no elements in the hierarchy, report BLOCKED with a screenshot; purchase is then covered by 06.
