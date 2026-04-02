import Foundation
import UIKit
internal import Combine

@MainActor
protocol ProfileCurrencyPresentationLogic: Sendable {
    func presentFetchedData(_ data: ProfileCurrencyFetchData)
}

final class ProfileCurrencyPresenter: ProfileCurrencyPresentationLogic, ImageProviding {
    @Published
    private(set) var viewModel: ProfileCurrencyViewModel

    weak var handler: ProfileCurrencyHandler?

    init(viewModel: ProfileCurrencyViewModel) {
        self.viewModel = viewModel
    }

    func presentFetchedData(_ data: ProfileCurrencyFetchData) {
        let rows = makeRows(
            from: data.currencies,
            selectedCurrencyCode: data.selectedCurrencyCode
        )

        viewModel = ProfileCurrencyViewModel(
            navigationTitle: .init(
                text: data.navigationTitle,
                font: Typography.typographySemibold20,
                textColor: Asset.Colors.textAndIconPrimary.color,
                alignment: .left
            ),
            searchField: .init(
                text: data.searchQuery,
                placeholder: L10n.registrationSearchCurrencyPlaceholder,
                leftIcon: magnifyingglassImage,
                onTextDidChanged: CommandOf { [weak handler] query in
                    await handler?.handleSearchQueryDidChange(query)
                }
            ),
            closeButton: .init(
                tapCommand: Command { [weak handler] in
                    await handler?.handleTapClose()
                }
            ),
            rows: rows
        )
    }
}

private extension ProfileCurrencyPresenter {
    func makeRows(
        from currencies: [RegistrationCurrency],
        selectedCurrencyCode: String
    ) -> [ProfileCurrencyViewModel.RowViewModel] {
        let selectedCode = selectedCurrencyCode.uppercased()
        let sortedCurrencies = currencies.sorted { lhs, rhs in
            let lhsSelected = lhs.code == selectedCode
            let rhsSelected = rhs.code == selectedCode

            if lhsSelected != rhsSelected {
                return lhsSelected
            }

            return lhs.title < rhs.title
        }

        return sortedCurrencies.map { currency in
            ProfileCurrencyViewModel.RowViewModel(
                code: currency.code,
                title: .init(
                    text: currency.title.localizedCapitalized,
                    font: Typography.typographySemibold16,
                    textColor: Asset.Colors.textAndIconPrimary.color,
                    alignment: .left
                ),
                subtitle: .init(
                    text: currency.code,
                    font: Typography.typographyMedium14,
                    textColor: Asset.Colors.textAndIconPlaceseholder.color,
                    alignment: .left
                ),
                isSelected: currency.code == selectedCode,
                tapCommand: Command { [weak handler] in
                    await handler?.handleSelectCurrency(currency.code)
                }
            )
        }
    }
}
