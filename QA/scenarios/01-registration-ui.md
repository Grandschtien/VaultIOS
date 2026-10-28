---
id: 01-registration-ui
setup: []
cleanup: [delete-user]
---
# Registration through the UI

Steps:
1. If the main screen is shown, log out: `navigation.profileButton` → `profile.logoutButton` → `confirmation.confirmButton`.
2. On onboarding tap `onboarding.primaryButton` until the auth choice appears, then open registration.
3. `registration.account.emailField` = `$EMAIL`, `registration.account.passwordField` and `registration.account.confirmPasswordField` = `$QA_PASSWORD`, tap `registration.primaryButton`.
4. `registration.name.nameField` = `QA`, tap `registration.primaryButton`.
5. Type `USD` into `registration.currency.searchField`, tap `registration.currency.cell.USD`, tap `registration.primaryButton`.
6. On `emailVerification.codeInput` type `$QA_DEV_CODE`.

Expected:
- `emailVerification.title` is shown after step 5.
- After step 6 the main screen opens: `main.summary.card` is visible.
- `emailVerification.errorLabel` never appears.
