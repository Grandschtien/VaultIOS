import Foundation
import UIKit
internal import Combine

@MainActor
protocol CategoryPeriodPickerPresentationLogic: Sendable {
    func presentFetchedData(_ data: CategoryPeriodPickerFetchData)
}

final class CategoryPeriodPickerPresenter: CategoryPeriodPickerPresentationLogic {
    @Published
    private(set) var viewModel: CategoryPeriodPickerViewModel

    weak var handler: CategoryPeriodPickerHandler?

    init(viewModel: CategoryPeriodPickerViewModel) {
        self.viewModel = viewModel
    }

    func presentFetchedData(_ data: CategoryPeriodPickerFetchData) {
        viewModel = .init(
            navigationTitle: .init(
                text: L10n.categoryPeriodPickerTitle,
                font: Typography.typographyBold20,
                textColor: Asset.Colors.textAndIconPrimary.color,
                alignment: .left
            ),
            calendar: .init(
                selectedDate: data.selectedDate,
                minimumDate: data.minimumDate,
                maximumDate: data.maximumDate,
                selectionCommand: .init(action: { [weak handler] date in
                    await handler?.handleSelectDate(date)
                })
            ),
            closeButton: .init(
                tapCommand: Command { [weak handler] in
                    await handler?.handleTapClose()
                }
            ),
            confirmButton: .init(
                title: L10n.categoryPeriodPickerApply,
                tapCommand: Command { [weak handler] in
                    await handler?.handleTapConfirm()
                }
            )
        )
    }
}
