// Created by Egor Shkarin 28.10.2026

import Foundation

enum AccessibilityIdentifier {
    enum TextFieldParts {
        static func input(of identifier: String) -> String {
            "\(identifier).input"
        }

        static func additionalLabel(of identifier: String) -> String {
            "\(identifier).additionalLabel"
        }

        static func rightAccessory(of identifier: String) -> String {
            "\(identifier).rightAccessory"
        }

        static func helpText(of identifier: String) -> String {
            "\(identifier).helpText"
        }
    }

    enum Login {
        static let title = "login.title"
        static let subtitle = "login.subtitle"
        static let emailField = "login.emailField"
        static let passwordField = "login.passwordField"
        static let signInButton = "login.signInButton"
    }

    enum Registration {
        static let stepLabel = "registration.stepLabel"
        static let progress = "registration.progress"
        static let primaryButton = "registration.primaryButton"
        static let secondaryButton = "registration.secondaryButton"

        enum Account {
            static let title = "registration.account.title"
            static let subtitle = "registration.account.subtitle"
            static let emailField = "registration.account.emailField"
            static let passwordField = "registration.account.passwordField"
            static let confirmPasswordField = "registration.account.confirmPasswordField"
        }

        enum Name {
            static let title = "registration.name.title"
            static let subtitle = "registration.name.subtitle"
            static let nameField = "registration.name.nameField"
        }

        enum Currency {
            static let title = "registration.currency.title"
            static let searchField = "registration.currency.searchField"
            static let errorLabel = "registration.currency.errorLabel"
            static let tableView = "registration.currency.tableView"

            static func cell(code: String) -> String {
                "registration.currency.cell.\(code)"
            }
        }
    }

    enum EmailVerification {
        static let title = "emailVerification.title"
        static let subtitle = "emailVerification.subtitle"
        static let codeInput = "emailVerification.codeInput"
        static let errorLabel = "emailVerification.errorLabel"
        static let resendPrompt = "emailVerification.resendPrompt"
        static let resendButton = "emailVerification.resendButton"
        static let resendCountdown = "emailVerification.resendCountdown"
    }

    enum Profile {
        static let scrollView = "profile.scrollView"
        static let errorView = "profile.errorView"
        static let savingIndicator = "profile.savingIndicator"
        static let saveButton = "profile.saveButton"
        static let sendLogsButton = "profile.sendLogsButton"
        static let logoutButton = "profile.logoutButton"
        static let deleteAccountButton = "profile.deleteAccountButton"
        static let version = "profile.version"

        enum Header {
            static let avatar = "profile.header.avatar"
            static let avatarInitials = "profile.header.avatarInitials"
            static let name = "profile.header.name"
            static let membership = "profile.header.membership"
        }

        enum Plan {
            static let card = "profile.plan.card"
            static let title = "profile.plan.title"
            static let subtitle = "profile.plan.subtitle"
            static let usage = "profile.plan.usage"
        }

        enum General {
            static let title = "profile.general.title"
            static let currencyRow = "profile.general.currencyRow"
            static let languageRow = "profile.general.languageRow"
        }
    }

    enum Analytics {
        static let periodButton = "analytics.periodButton"
        static let loadingView = "analytics.loadingView"
        static let errorButton = "analytics.errorButton"
        static let unlockButton = "analytics.unlockButton"
        static let topCategoriesTitle = "analytics.topCategoriesTitle"

        static func presetPill(_ preset: AnalyticsPeriodPreset) -> String {
            "analytics.presetPill.\(preset)"
        }

        static func categoryRow(at index: Int) -> String {
            "analytics.categoryRow.\(index)"
        }

        enum Body {
            static let loadingView = "analytics.body.loadingView"
            static let errorButton = "analytics.body.errorButton"
            static let emptyText = "analytics.body.emptyText"
        }

        enum Chart {
            static let view = "analytics.chart"
            static let centerTitle = "analytics.chart.centerTitle"
            static let centerValue = "analytics.chart.centerValue"

            static func legendItem(at index: Int) -> String {
                "analytics.chart.legendItem.\(index)"
            }
        }
    }

    enum Common {
        static let swipeDeleteAction = "common.swipeDeleteAction"
    }

    enum Toast {
        static let view = "toast"
        static let title = "toast.title"
        static let actionButton = "toast.actionButton"
    }

    enum ExpenseItem {
        static let icon = "expenseItem.icon"
        static let title = "expenseItem.title"
        static let subtitle = "expenseItem.subtitle"
        static let amount = "expenseItem.amount"
    }

    enum CategoryItem {
        static let icon = "categoryItem.icon"
        static let title = "categoryItem.title"
        static let amount = "categoryItem.amount"
    }

    enum ExpensesList {
        static let collectionView = "expensesList.collectionView"
        static let errorView = "expensesList.errorView"
        static let emptyLabel = "expensesList.emptyLabel"
        static let loadingView = "expensesList.loadingView"
        static let paginationSpinner = "expensesList.paginationSpinner"

        static func sectionHeader(at section: Int) -> String {
            "expensesList.sectionHeader.\(section)"
        }

        static func cell(section: Int, item: Int) -> String {
            "expensesList.cell.\(section).\(item)"
        }
    }

    enum Category {
        static let editButton = "category.editButton"
        static let tableView = "category.tableView"
        static let errorView = "category.errorView"
        static let emptyLabel = "category.emptyLabel"
        static let loadingView = "category.loadingView"
        static let paginationSpinner = "category.paginationSpinner"

        static func sectionHeader(at section: Int) -> String {
            "category.sectionHeader.\(section)"
        }

        static func expenseCell(section: Int, row: Int) -> String {
            "category.expenseCell.\(section).\(row)"
        }

        enum Summary {
            static let card = "category.summary.card"
            static let title = "category.summary.title"
            static let amount = "category.summary.amount"
            static let note = "category.summary.note"
        }
    }

    enum CategoriesList {
        static let addButton = "categoriesList.addButton"
        static let collectionView = "categoriesList.collectionView"
        static let errorView = "categoriesList.errorView"
        static let emptyLabel = "categoriesList.emptyLabel"
    }

    enum PeriodPicker {
        static let closeButton = "periodPicker.closeButton"
        static let confirmButton = "periodPicker.confirmButton"
        static let fromField = "periodPicker.fromField"
        static let toField = "periodPicker.toField"
        static let calendar = "periodPicker.calendar"

        static func fieldTitle(of identifier: String) -> String {
            "\(identifier).title"
        }

        static func fieldValue(of identifier: String) -> String {
            "\(identifier).value"
        }
    }

    enum SheetHeader {
        static let title = "sheetHeader.title"
        static let closeButton = "sheetHeader.closeButton"
    }

    enum Confirmation {
        static let title = "confirmation.title"
        static let subtitle = "confirmation.subtitle"
        static let closeButton = "confirmation.closeButton"
        static let confirmButton = "confirmation.confirmButton"
        static let cancelButton = "confirmation.cancelButton"
    }

    enum ProfileCurrency {
        static let closeButton = "profileCurrency.closeButton"
        static let searchField = "profileCurrency.searchField"
        static let tableView = "profileCurrency.tableView"

        static func cell(code: String) -> String {
            "profileCurrency.cell.\(code)"
        }
    }

    enum Subscription {
        static let loadingView = "subscription.loadingView"
        static let errorView = "subscription.errorView"
        static let overlayLoadingView = "subscription.overlayLoadingView"
        static let overlayMessage = "subscription.overlayMessage"
        static let title = "subscription.title"
        static let subtitle = "subscription.subtitle"
        static let tableView = "subscription.tableView"
        static let restoreButton = "subscription.restoreButton"
        static let termsOfUseLink = "subscription.termsOfUseLink"
        static let privacyPolicyLink = "subscription.privacyPolicyLink"

        enum CurrentPlan {
            static let card = "subscription.currentPlan.card"
            static let title = "subscription.currentPlan.title"
            static let planTitle = "subscription.currentPlan.planTitle"
            static let description = "subscription.currentPlan.description"
        }

        enum Plan {
            static func cell(id: String) -> String {
                "subscription.plan.\(id)"
            }

            static func title(id: String) -> String {
                "subscription.plan.\(id).title"
            }

            static func description(id: String) -> String {
                "subscription.plan.\(id).description"
            }

            static func trial(id: String) -> String {
                "subscription.plan.\(id).trial"
            }

            static func price(id: String) -> String {
                "subscription.plan.\(id).price"
            }

            static func button(id: String) -> String {
                "subscription.plan.\(id).button"
            }
        }
    }

    enum MultilineInputParts {
        static func title(of identifier: String) -> String {
            "\(identifier).title"
        }

        static func input(of identifier: String) -> String {
            "\(identifier).input"
        }

        static func counter(of identifier: String) -> String {
            "\(identifier).counter"
        }
    }

    enum EntryChooser {
        static let aiButton = "entryChooser.aiButton"
        static let manualButton = "entryChooser.manualButton"
    }

    enum AIEntry {
        static let promptInput = "aiEntry.promptInput"
        static let voiceButton = "aiEntry.voiceButton"
        static let processButton = "aiEntry.processButton"

        enum NoExpenseAlert {
            static let view = "aiEntry.noExpenseAlert"
            static let title = "aiEntry.noExpenseAlert.title"
            static let message = "aiEntry.noExpenseAlert.message"
            static let addManuallyButton = "aiEntry.noExpenseAlert.addManuallyButton"
            static let fixPromptButton = "aiEntry.noExpenseAlert.fixPromptButton"
        }
    }

    enum ManualEntry {
        static let amountTitle = "manualEntry.amount.title"
        static let amountCurrency = "manualEntry.amount.currency"
        static let amountInput = "manualEntry.amount.input"
        static let titleField = "manualEntry.titleField"
        static let categoryTitle = "manualEntry.category.title"
        static let categoryButton = "manualEntry.category.button"
        static let categoryValue = "manualEntry.category.value"
        static let descriptionInput = "manualEntry.descriptionInput"
        static let primaryButton = "manualEntry.primaryButton"
        static let skipButton = "manualEntry.skipButton"
    }

    enum ExpenseCategoryPicker {
        static let tableView = "expenseCategoryPicker.tableView"
        static let errorView = "expenseCategoryPicker.errorView"
        static let emptyLabel = "expenseCategoryPicker.emptyLabel"
        static let createButton = "expenseCategoryPicker.createButton"
        static let addButton = "expenseCategoryPicker.addButton"

        static func cell(at index: Int) -> String {
            "expenseCategoryPicker.cell.\(index)"
        }
    }

    enum CategoryEditor {
        static let backButton = "categoryEditor.backButton"
        static let title = "categoryEditor.title"
        static let preview = "categoryEditor.preview"
        static let nameField = "categoryEditor.nameField"
        static let emojiTitle = "categoryEditor.emojiTitle"
        static let emojiGrid = "categoryEditor.emojiGrid"
        static let colorTitle = "categoryEditor.colorTitle"
        static let colorGrid = "categoryEditor.colorGrid"
        static let customEmojiInput = "categoryEditor.customEmojiInput"
        static let loadingView = "categoryEditor.loadingView"
        static let errorView = "categoryEditor.errorView"
        static let primaryButton = "categoryEditor.primaryButton"
        static let deleteButton = "categoryEditor.deleteButton"

        static func option(of gridIdentifier: String, at index: Int) -> String {
            "\(gridIdentifier).option.\(index)"
        }
    }

    enum ForgotPassword {
        static let closeButton = "forgotPassword.closeButton"
        static let title = "forgotPassword.title"
        static let emailField = "forgotPassword.emailField"
        static let sendButton = "forgotPassword.sendButton"
    }

    enum Onboarding {
        static let pagesScrollView = "onboarding.pagesScrollView"
        static let pageControl = "onboarding.pageControl"
        static let primaryButton = "onboarding.primaryButton"

        static func pageTitle(at index: Int) -> String {
            "onboarding.page.\(index).title"
        }

        static func pageSubtitle(at index: Int) -> String {
            "onboarding.page.\(index).subtitle"
        }

        static func pagePill(at index: Int) -> String {
            "onboarding.page.\(index).pill"
        }
    }

    enum TabBar {
        static let homeTab = "tabBar.homeTab"
        static let statsTab = "tabBar.statsTab"
        static let addExpenseButton = "tabBar.addExpenseButton"
    }

    enum Navigation {
        static let profileButton = "navigation.profileButton"
    }

    enum CategoryCell {
        static func cell(at index: Int) -> String {
            "categoryCell.\(index)"
        }
    }

    enum Main {
        static let scrollView = "main.scrollView"

        enum BlockingError {
            static let view = "main.blockingError"
            static let title = "main.blockingError.title"
            static let subtitle = "main.blockingError.subtitle"
            static let retryButton = "main.blockingError.retryButton"
        }

        enum Summary {
            static let card = "main.summary.card"
            static let title = "main.summary.title"
            static let amount = "main.summary.amount"
            static let periodDescription = "main.summary.periodDescription"
            static let errorView = "main.summary.errorView"
        }

        enum Categories {
            static let title = "main.categories.title"
            static let seeAllButton = "main.categories.seeAllButton"
            static let collectionView = "main.categories.collectionView"
            static let emptyLabel = "main.categories.emptyLabel"
            static let errorView = "main.categories.errorView"
            static let loadingView = "main.categories.loadingView"
        }

        enum Expenses {
            static let title = "main.expenses.title"
            static let seeAllButton = "main.expenses.seeAllButton"
            static let collectionView = "main.expenses.collectionView"
            static let emptyLabel = "main.expenses.emptyLabel"
            static let errorView = "main.expenses.errorView"
            static let loadingView = "main.expenses.loadingView"

            static func sectionHeader(at section: Int) -> String {
                "main.expenses.sectionHeader.\(section)"
            }

            static func cell(section: Int, item: Int) -> String {
                "main.expenses.cell.\(section).\(item)"
            }
        }
    }
}
