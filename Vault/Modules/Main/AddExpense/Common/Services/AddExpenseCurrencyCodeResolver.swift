import Foundation

struct AddExpenseCurrencyCodeResolver: Sendable {
    private let observer: MainFlowDomainObserverProtocol
    private let userProfileStorageService: UserProfileStorageServiceProtocol

    init(
        observer: MainFlowDomainObserverProtocol,
        userProfileStorageService: UserProfileStorageServiceProtocol
    ) {
        self.observer = observer
        self.userProfileStorageService = userProfileStorageService
    }

    func resolve() -> String {
        let profileCurrency = userProfileStorageService.loadProfile()?.currency
        if let profileCurrency = normalizedCurrencyCode(from: profileCurrency) {
            return profileCurrency
        }

        let overviewCurrency = observer.currentOverviewSnapshot().summary?.currency
        if let overviewCurrency = normalizedCurrencyCode(from: overviewCurrency) {
            return overviewCurrency
        }

        let categoryCurrency = observer.currentCategoriesSnapshot().categories.first?.currency
        if let categoryCurrency = normalizedCurrencyCode(from: categoryCurrency) {
            return categoryCurrency
        }

        return "USD"
    }
}

private extension AddExpenseCurrencyCodeResolver {
    func normalizedCurrencyCode(from code: String?) -> String? {
        guard let code = code?.trimmingCharacters(in: .whitespacesAndNewlines),
              !code.isEmpty else {
            return nil
        }

        return code.uppercased()
    }
}
