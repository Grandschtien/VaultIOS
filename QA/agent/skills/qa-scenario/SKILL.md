---
name: qa-scenario
description: Writes a new Vault release QA scenario into QA/scenarios/ where every UI element is referenced by its accessibility identifier from AccessibilityIdentifier.swift. Use when the user asks to write, add or update a QA scenario, test case or smoke check for release-qa. Trigger words: сценарий, напиши сценарий, QA scenario, test scenario.
---

# QA scenario writer

Writes one scenario file `QA/scenarios/<NN>-<name>.md` for the `release-qa` skill. The `qa-runner` agent executes it by finding elements in the UI hierarchy, so the scenario must name elements by accessibility identifier, never by visible text or position.

Input: what the scenario must check (feature, flow, expected result).

## 1. Collect identifiers

1. Read `Vault/Common/Accessibility/AccessibilityIdentifier.swift`. It is the only source of ids.
2. For each screen in the flow, find where the ids are set (`grep -rn "AccessibilityIdentifier.<Enum>" Vault`) to know which view owns the id and what it shows.
3. Expand dynamic ids into concrete values:
   - `cell(at:)` → `expenseCategoryPicker.cell.0`
   - `cell(section:item:)` → `main.expenses.cell.0.0`
   - `cell(code:)` → `profileCurrency.cell.USD`
   - `Plan.button(id:)` → `subscription.plan.<product id>.button`
4. Shared component parts:
   - `TextField`: the field id is the container, typing goes to `<id>.input`; errors in `<id>.helpText`.
   - Multiline input: `<id>.input`, `<id>.title`, `<id>.counter`.
   - Period picker fields: `<id>.title`, `<id>.value`.
   - Category editor grids: `<grid id>.option.<index>`.
   - Cells reuse item ids inside: `expenseItem.title`, `expenseItem.amount`, `categoryItem.title`. Scope them by the cell: "`expenseItem.title` inside `main.expenses.cell.0.0`".

## 2. Write the scenario

Copy `template.md` from this skill folder and fill it.

- `id` equals the file name without `.md`. `NN` is the next free number in `QA/scenarios/`.
- `setup` / `cleanup` use only steps that `release-qa` knows: `create-user`, `seed <fixture>`, `rc-grant [entitlement] [duration]`, `rc-revoke [entitlement]`, `delete-user`. Fixtures live in `QA/fixtures/`.
- One action per step. Allowed verbs:
  - `Tap \`<id>\``
  - `Type \`<value>\` into \`<id>\`` (the runner types into `<id>.input`)
  - `Wait for \`<id>\`` (visible, or loader gone)
  - `Swipe left on \`<id>\`` (then tap `common.swipeDeleteAction`)
  - `Run \`scripts/qa/<script>.sh …\``
- Every element is a backticked id. Variables: `$EMAIL`, `$QA_PASSWORD`, `$QA_DEV_CODE`.
- Every `Expected` item points at a step and an id: `After step N \`<id>\` is visible | is gone | has text \`…\``.
- Visible text is allowed only for UI the app does not own (system alerts, the RevenueCat Test Store sheet, keyboard). Write it as `text:"Allow"` and say why there is no id.
- Do not depend on data the scenario did not create: use `seed` or create it in earlier steps.
- Keep the scenario short: one flow, up to ~10 steps. Split longer flows into several scenarios.

## 3. Missing identifiers

If an element in the flow has no id:

- Do not fall back to visible text or coordinates.
- List it under `Missing identifiers:` with the screen, the view file and a proposed id in the existing naming style (`<screen>.<element>`, lowerCamelCase).
- Tell the user. Adding ids to the app is a separate task (code change in `AccessibilityIdentifier.swift` and the view).

## 4. Verify

```bash
python3 -I .claude/skills/qa-scenario/check-ids.py QA/scenarios/<file>.md
```

It fails on any backticked id that is not defined in `AccessibilityIdentifier.swift`. Fix the scenario or move the id to `Missing identifiers` (written without backticks).

Then show the user the scenario and how to run it: `/release-qa <id>`.

## Example

```markdown
---
id: 08-delete-expense
setup: [create-user, seed analytics-month]
cleanup: [delete-user]
---
# Category: delete an expense by swipe

Preconditions:
- User with seeded expenses for the current month.
- Start screen: any.

Steps:
1. Log in as `$EMAIL` (log out first if another user is logged in).
2. Wait for `main.categories.collectionView`, tap `categoryCell.0`.
3. Wait for `category.tableView`.
4. Swipe left on `category.expenseCell.0.0`.
5. Tap `common.swipeDeleteAction`.

Expected:
- After step 3 `category.summary.amount` is visible.
- After step 5 `category.summary.amount` is less than before step 4.

Missing identifiers:
- —
```
