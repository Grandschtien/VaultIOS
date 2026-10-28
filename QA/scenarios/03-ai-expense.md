---
id: 03-ai-expense
setup: [create-user]
login: api
cleanup: [delete-user]
---
# Expense through AI

The parse result is not deterministic: check structure and amounts, not exact titles.

Steps:
1. The app starts signed in as `$EMAIL`: `main.summary.card` is visible.
2. Tap `tabBar.addExpenseButton`, then `entryChooser.aiButton`.
3. Type `coffee 350 and taxi 800` into `aiEntry.promptInput.input`, tap `aiEntry.processButton`.
4. Confirm the parsed expenses with the primary button on the review screen.

Expected:
- After step 3 the review shows 2 expenses with amounts 350 and 800.
- `aiEntry.noExpenseAlert` does not appear.
- After step 4 `main.expenses.collectionView` contains items with amounts 350 and 800.
