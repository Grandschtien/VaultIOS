// Created by Egor Shkarin 23.03.2026

import Foundation

protocol MainExpenseGrouping: Sendable {
    func groupExpenses(_ expenses: [MainExpenseModel]) -> [MainExpenseGroupModel]
}

struct MainExpenseDateGrouping: MainExpenseGrouping {
    func groupExpenses(_ expenses: [MainExpenseModel]) -> [MainExpenseGroupModel] {
        let calendar = Calendar.current

        let groupedExpenses = Dictionary(grouping: expenses) { expense in
            calendar.startOfDay(for: expense.timeOfAdd)
        }

        return groupedExpenses
            .map { date, values in
                MainExpenseGroupModel(
                    date: date,
                    expenses: values.sorted { $0.timeOfAdd > $1.timeOfAdd }
                )
            }
            .sorted { $0.date > $1.date }
    }
}
