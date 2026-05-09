enum AnalyticsEvent: Equatable, Sendable {
    case screenOpen(AnalyticsScreen)
    case screenSuccess(AnalyticsScreen)
    case screenFailure(AnalyticsScreen)
    case paywallOpen(source: AnalyticsScreen)
    case subscriptionPurchaseStart
    case subscriptionPurchaseSuccess
    case subscriptionPurchaseFailure
    case aiParseStart
    case aiParseSuccess
    case aiParseFailure
    case dateChange(source: AnalyticsScreen)
    case tap(AnalyticsAction)

    var name: String {
        switch self {
        case .screenOpen(let screen):
            "\(screen.rawValue).open"
        case .screenSuccess(let screen):
            "\(screen.rawValue).load.success"
        case .screenFailure(let screen):
            "\(screen.rawValue).load.failure"
        case .paywallOpen(let source):
            "\(source.rawValue).paywall.open"
        case .subscriptionPurchaseStart:
            "\(AnalyticsScreen.subscription.rawValue).purchase.start"
        case .subscriptionPurchaseSuccess:
            "\(AnalyticsScreen.subscription.rawValue).purchase.success"
        case .subscriptionPurchaseFailure:
            "\(AnalyticsScreen.subscription.rawValue).purchase.failure"
        case .aiParseStart:
            "\(AnalyticsScreen.expenseAIEntry.rawValue).parse.start"
        case .aiParseSuccess:
            "\(AnalyticsScreen.expenseAIEntry.rawValue).parse.success"
        case .aiParseFailure:
            "\(AnalyticsScreen.expenseAIEntry.rawValue).parse.failure"
        case .dateChange(let source):
            "\(source.rawValue).date_change"
        case .tap(let action):
            action.rawValue
        }
    }
}

enum AnalyticsScreen: String, Equatable, Sendable {
    case login
    case registration
    case forgotPassword = "forgot_password"
    case profile
    case profileCurrency = "profile_currency"
    case logout
    case subscription
    case categoriesList = "categories_list"
    case category
    case expensesList = "expenses_list"
    case analytics
    case expenseEntryChooser = "expense_entry_chooser"
    case expenseAIEntry = "expense_ai_entry"
    case expenseCategoryPicker = "expense_category_picker"
    case expenseManualEntry = "expense_manual_entry"
    case categoryCreate = "category_create"
}

enum AnalyticsAction: String, Equatable, Sendable {
    case addCategory = "category_create.tap.open"
    case chooserTapAiEntry = "expense_entry_chooser.ai.tap"
    case chooserTapManualEntry = "expense_entry_chooser.manual.tap"
    case aiConfirmTap = "expense_ai_entry.confirm.tap"
    case aiMicrophoneTap = "expense_ai_entry.microphone.tap"
    case manualTapCategory = "expense_manual_entry.category.tap"
    case manualTapPrimaryNext = "expense_manual_entry.primary_next.tap"
    case manualTapPrimaryConfirm = "expense_manual_entry.primary_confirm.tap"
    case manualTapSkip = "expense_manual_entry.skip.tap"
    case manualTapClose = "expense_manual_entry.close.tap"
    case manualPageChange = "expense_manual_entry.page_change"
}
