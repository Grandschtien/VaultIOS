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
            fromField: makeFieldViewModel(
                title: L10n.categoryPeriodPickerFrom,
                value: data.fromDate,
                isActive: data.activeField == .from,
                tapCommand: Command { [weak handler] in
                    await handler?.handleTapFromField()
                }
            ),
            toField: makeFieldViewModel(
                title: L10n.categoryPeriodPickerTo,
                value: data.toDate,
                isActive: data.activeField == .to,
                tapCommand: Command { [weak handler] in
                    await handler?.handleTapToField()
                }
            ),
            calendar: .init(
                selectedDate: data.selectedCalendarDate,
                visibleMonthDate: data.visibleMonthDate,
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
                isEnabled: data.isApplyEnabled,
                tapCommand: Command { [weak handler] in
                    await handler?.handleTapConfirm()
                }
            )
        )
    }
}

private extension CategoryPeriodPickerPresenter {
    func makeFieldViewModel(
        title: String,
        value: Date,
        isActive: Bool,
        tapCommand: Command
    ) -> CategoryPeriodPickerViewModel.PeriodFieldViewModel {
        .init(
            title: .init(
                text: title,
                font: Typography.typographyMedium12,
                textColor: Asset.Colors.textAndIconSecondary.color,
                alignment: .left
            ),
            value: .init(
                text: formattedDate(value),
                font: Typography.typographyBold16,
                textColor: Asset.Colors.textAndIconPrimary.color,
                alignment: .left
            ),
            isActive: isActive,
            tapCommand: tapCommand
        )
    }

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: date)
    }
}
