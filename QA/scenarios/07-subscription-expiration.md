---
id: 07-subscription-expiration
setup: [create-user, seed analytics-month.json, rc-grant premium_access weekly, rc-revoke premium_access]
login: api
cleanup: [delete-user]
---
# Subscription expiration

Steps:
1. The app starts signed in as `$EMAIL`: `main.summary.card` is visible.
2. Tap `tabBar.statsTab`.
3. Tap `navigation.profileButton`.

Expected:
- After step 2 `analytics.unlockButton` is visible.
- After step 3 `profile.plan.title` names the free plan.
