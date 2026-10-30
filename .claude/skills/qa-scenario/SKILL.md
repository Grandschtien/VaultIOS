---
name: qa-scenario
description: Writes a new Vault Maestro test flow into Maestro/ where every UI element is referenced by its accessibility identifier from AccessibilityIdentifier.swift. Use when the user asks to write, add or update a QA scenario, test case, Maestro flow or smoke check. Trigger words: сценарий, напиши сценарий, тест кейс, maestro, QA scenario, test scenario.
model: opus
---

# Maestro flow writer

Writes one flow `Maestro/<NN>-<name>.yaml`. `scripts/qa/maestro.sh` runs it on the booted simulator against the local QA backend: it creates a fresh `qa-maestro-…@example.com` account, runs the setup from the flow header, passes the variables, runs the flow and deletes the account.

Input: what the flow must check (feature, flow, expected result).

## 1. Collect identifiers

1. Read `Vault/Common/Accessibility/AccessibilityIdentifier.swift`. It is the only source of ids.
2. For each screen in the flow, find where the ids are set (`grep -rn "AccessibilityIdentifier.<Enum>" Vault`) to know which view owns the id and what it shows.
3. Expand dynamic ids into concrete values:
   - `cell(at:)` → `expenseCategoryPicker.cell.0`
   - `cell(section:item:)` → `main.expenses.cell.0.0`
   - `cell(code:)` → `profileCurrency.cell.USD`
   - `Plan.button(id:)` → `subscription.plan.<product id>.button`
4. Shared component parts:
   - `TextField`: the field id is the container, tap and type into `<id>.input`; errors in `<id>.helpText`; the label next to the title is `<id>.additionalLabel`.
   - Multiline input: `<id>.input`, `<id>.title`, `<id>.counter`.
   - Period picker fields: `<id>.title`, `<id>.value`.
   - Category editor grids: `<grid id>.option.<index>`.
   - Cells reuse item ids inside: `expenseItem.title`, `expenseItem.amount`, `categoryItem.title`. Scope them with `childOf: { id: main.expenses.cell.0.0 }`.

## 2. Write the flow

Copy `template.yaml` from this skill folder and fill it. Read one or two existing flows in `Maestro/` first and keep their style.

### Header

- `NN` is the next free number in `Maestro/`. First comment line is a short title.
- `# qa-setup:` — `;`-separated steps that `maestro.sh` knows: `create-user`, `seed <fixture>`, `rc-grant [entitlement] [duration]`, `rc-revoke [entitlement]`. Fixtures live in `QA/fixtures/`. Leave it empty when the flow creates the account itself (registration).
- `appId: com.egor.shkarin.Vault`. Do not add an `env:` block: values come from `maestro.sh`.

### Variables

`${EMAIL}`, `${QA_PASSWORD}`, `${QA_DEV_CODE}` (the email verification code the QA backend accepts), `${API_BASE_URL}`, `${USER_ID}` (empty when the flow did not use `create-user`), `${RC_WEBHOOK_AUTH}`. Never hardcode them.

### Subflows (`Maestro/subflows/`)

- `launch.yaml` — always the first command. Clean launch against the QA backend; never call `launchApp` directly.
- `login.yaml` — right after `launch.yaml` in every flow that needs a signed-in user (needs `create-user`). It signs in through the UI and waits for the main screen. Never skip it and never check login inside other flows: login and logout are verified only in `02-login-logout.yaml`.
- `wait-main.yaml` — wait for the main screen after an action that returns to it.
- `logout-if-signed-in.yaml`, then `open-login.yaml` — only for flows that test the auth screens themselves (registration).
- `dismiss-save-password.yaml` — right after submitting a form with a password field (iOS offers to save it).
- `dismiss-strong-password.yaml` — around every password field: tap `<id>.input`, run it, tap `<id>.input` again, `eraseText`, `inputText`, run it again.

### Steps

- Mark each step of the case with a comment `# N. <step>`; put checks right after the step they verify, with `# Expected: …`.
- Elements only by `id:`. Allowed commands: `tapOn`, `inputText`, `eraseText`, `pressKey: Enter` (after every `inputText` into a `TextField`: Return closes the keyboard, otherwise the next field or button may be under it and the tap types a letter; if the field has `onReturn` in the presenter, Return also runs it, e.g. submits the form — then it replaces the button tap), `hideKeyboard` (only where Return is not available, e.g. a number pad; never between text fields: on iOS it swipes over the screen and moves the cursor), `scrollUntilVisible`, `swipe` (then tap `common.swipeDeleteAction`), `assertVisible`, `assertNotVisible`, `extendedWaitUntil`, `runFlow`, `runScript`, `repeat`, `assertTrue`.
- After any network action wait with `extendedWaitUntil` (`timeout` 15000–30000), not with `assertVisible`.
- For non-deterministic content (AI parse) assert a regex on `text:` (`".*350.*"`), not exact titles.
- Visible text is allowed only for UI the app does not own (system alerts, the strong password sheet, the RevenueCat Test Store sheet). Add a comment why there is no id.
- Backend actions in the middle of a flow (webhooks, polling) go into `Maestro/scripts/<name>.js` through `runScript`, reusing the endpoints of `scripts/qa/*.sh`. See `scripts/rc-sync.js`.
- Do not depend on data the flow did not create: use `seed` or create it in earlier steps.
- Keep the flow short: one case, up to ~10 steps. Split longer cases into several flows.

## 3. Missing identifiers

If an element in the flow has no id:

- Do not fall back to visible text or coordinates.
- List it in a `# Missing identifiers:` comment at the top with the screen, the view file and a proposed id in the existing naming style (`<screen>.<element>`, lowerCamelCase).
- Tell the user. Adding ids to the app is a separate task (code change in `AccessibilityIdentifier.swift` and the view).

## 4. Verify

```bash
python3 -I .claude/skills/qa-scenario/check-ids.py Maestro/<file>.yaml
```

It fails on any `id:` that is not defined in `AccessibilityIdentifier.swift`. Fix the flow or move the id to `Missing identifiers`.

If `maestro` is installed, run the flow: `scripts/qa/maestro.sh <NN>-<name>`. Otherwise say it was not run.

Then show the user the flow and how to run it.

## Example

```yaml
# Category: delete an expense by swipe.
# qa-setup: create-user; seed analytics-month.json
appId: com.egor.shkarin.Vault
---
- runFlow: subflows/launch.yaml
- runFlow: subflows/login.yaml

# 1. Open the first category.
- extendedWaitUntil:
    visible:
      id: main.categories.collectionView
    timeout: 20000
- tapOn:
    id: categoryCell.0
- extendedWaitUntil:
    visible:
      id: category.tableView
    timeout: 15000
# Expected: the summary is shown.
- assertVisible:
    id: category.summary.amount

# 2. Delete the first expense.
- swipe:
    from:
      id: category.expenseCell.0.0
    direction: LEFT
- tapOn:
    id: common.swipeDeleteAction
# Expected: the expense is gone.
- extendedWaitUntil:
    notVisible:
      id: category.expenseCell.0.0
    timeout: 15000
```
