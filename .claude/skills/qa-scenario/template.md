---
id: NN-short-name
setup: [create-user]
cleanup: [delete-user]
---
# <Feature>: <what is checked>

Preconditions:
- <State the setup gives: logged-out user, PREMIUM via rc-grant, seeded fixture…>
- Start screen: <onboarding | login | main>.

Steps:
1. Log in as `$EMAIL` (log out first if another user is logged in).
2. Tap `<screen.element>`.
3. Type `<value>` into `<screen.field>`.
4. Wait for `<screen.element>`.
5. Run `scripts/qa/<script>.sh $EMAIL …`.

Expected:
- After step 2 `<screen.element>` is visible.
- After step 4 `<screen.element>` has text `<value>`.
- After step 5 `<screen.element>` is gone.

Missing identifiers:
- —
