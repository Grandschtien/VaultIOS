import Foundation
@testable import Vylok

enum MainModelFixtures {
    static let timeOfAdd = Date(timeIntervalSince1970: 1_783_166_400)

    static func makeCategory(
        id: String = "food",
        name: String = "Food",
        icon: String = "fork.knife",
        color: String = "light_orange"
    ) -> MainCategoryModel {
        MainCategoryModel(id: id, name: name, icon: icon, color: color)
    }

    static func makeCategoryCard(
        id: String = "cat-1",
        name: String = "Food",
        icon: String = "🍴",
        color: String = "light_orange",
        amount: Double = 10,
        currency: String = "USD"
    ) -> MainCategoryCardModel {
        MainCategoryCardModel(id: id, name: name, icon: icon, color: color, amount: amount, currency: currency)
    }

    static func makeExpense(
        id: String = "expense-1",
        title: String = "Coffee",
        description: String = "Latte",
        amount: Double = 4.5,
        currency: String = "USD",
        category: String = "food",
        timeOfAdd: Date = timeOfAdd
    ) -> MainExpenseModel {
        MainExpenseModel(
            id: id,
            title: title,
            description: description,
            amount: amount,
            currency: currency,
            category: category,
            timeOfAdd: timeOfAdd
        )
    }

    static func makeExpenseGroup(
        date: Date = timeOfAdd,
        expenses: [MainExpenseModel] = [makeExpense()]
    ) -> MainExpenseGroupModel {
        MainExpenseGroupModel(date: date, expenses: expenses)
    }
}
