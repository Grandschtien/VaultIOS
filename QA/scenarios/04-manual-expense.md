---
id: 04-manual-expense
setup: [create-user]
login: api
cleanup: [delete-user]
---
# Manual expense

Steps:
1. The app starts signed in as `$EMAIL`: `main.summary.card` is visible.
2. Tap `tabBar.addExpenseButton`, then `entryChooser.manualButton`.
3. `manualEntry.amount.input` = `42`, `manualEntry.titleField` = `QA lunch`.
4. Tap `manualEntry.category.button`, pick `expenseCategoryPicker.cell.0`.
5. Tap `manualEntry.primaryButton`.

Expected:
- After step 4 `manualEntry.category.value` shows the picked category.
- After step 5 `main.expenses.collectionView` has an item titled `QA lunch` with amount 42.
- `main.summary.amount` is not zero.
