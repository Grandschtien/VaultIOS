---
id: 06-premium-without-purchase
setup: [create-user, seed analytics-month.json, rc-grant premium_access weekly]
login: api
cleanup: [delete-user]
---
# Premium without purchase

Steps:
1. The app starts signed in as `$EMAIL`: `main.summary.card` is visible.
2. Tap `tabBar.statsTab`.
3. Tap `navigation.profileButton`.

Expected:
- After step 2 `analytics.unlockButton` is not visible, `analytics.chart` is visible, `analytics.categoryRow.0` exists.
- The top category is `Home` (largest total in the fixture).
- After step 3 `profile.plan.title` names the premium plan.
