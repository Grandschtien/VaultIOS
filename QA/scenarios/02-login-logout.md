---
id: 02-login-logout
setup: [create-user]
cleanup: [delete-user]
---
# Login and logout

Steps:
1. If the main screen is shown, log out: `navigation.profileButton` → `profile.logoutButton` → `confirmation.confirmButton`.
2. Go to the login screen (from onboarding: `onboarding.primaryButton`, then sign in).
3. `login.emailField` = `$EMAIL`, `login.passwordField` = `$QA_PASSWORD`, tap `login.signInButton`.
4. Tap `navigation.profileButton`, then `profile.logoutButton`.
5. Tap `confirmation.cancelButton`, then `profile.logoutButton` again and `confirmation.confirmButton`.

Expected:
- After step 3 `main.summary.card` is visible.
- After step 4 `confirmation.title` is visible.
- After cancel the profile screen is still shown (`profile.logoutButton` visible).
- After step 5 the app is on onboarding or login, `main.summary.card` is gone.
