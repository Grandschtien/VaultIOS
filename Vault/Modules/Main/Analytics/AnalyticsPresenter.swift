import Foundation
import UIKit
internal import Combine

@MainActor
protocol AnalyticsPresentationLogic: Sendable {
    func presentFetchedData(_ data: AnalyticsFetchData)
}

final class AnalyticsPresenter: AnalyticsPresentationLogic {
    @Published
    private(set) var viewModel: AnalyticsViewModel

    weak var handler: AnalyticsHandler?

    private let formatter: AnalyticsValueFormatting
    private let colorProvider: CategoryColorProviding

    init(
        viewModel: AnalyticsViewModel,
        formatter: AnalyticsValueFormatting,
        colorProvider: CategoryColorProviding
    ) {
        self.viewModel = viewModel
        self.formatter = formatter
        self.colorProvider = colorProvider
    }

    func presentFetchedData(_ data: AnalyticsFetchData) {
        viewModel = AnalyticsViewModel(
            periodButton: makePeriodButtonViewModel(from: data),
            state: makeState(from: data)
        )
    }
}

private extension AnalyticsPresenter {
    func makePeriodButtonViewModel(from data: AnalyticsFetchData) -> AnalyticsMonthBarButtonView.ViewModel {
        .init(
            title: makePeriodButtonTitle(
                selectedPeriod: data.selectedPeriod,
                selectedPreset: data.selectedPreset
            ),
            tapCommand: Command { [weak handler] in
                await handler?.handleTapMonthFilter()
            }
        )
    }

    func makePeriodButtonTitle(
        selectedPeriod: MainSummaryPeriod,
        selectedPreset: AnalyticsPeriodPreset?
    ) -> String {
        if selectedPreset == .month {
            return formatter.formatMonth(selectedPeriod.from)
        }

        return formatter.formatPeriodTitle(
            from: selectedPeriod.from,
            to: selectedPeriod.to
        )
    }

    func makeState(from data: AnalyticsFetchData) -> AnalyticsViewModel.State {
        if data.isLocked {
            return .locked(makeLockedViewModel())
        }

        if data.showsContentShell {
            return .content(makeContentViewModel(from: data))
        }

        switch data.loadingState {
        case .idle, .loading:
            return .loading
        case .failed:
            return .error(makeErrorViewModel())
        case .loaded:
            return .content(makeContentViewModel(from: data))
        }
    }

    func makeLockedViewModel() -> AnalyticsViewModel.LockedViewModel {
        .init(
            button: .init(
                title: L10n.analyticsSubscribeToSee,
                titleColor: Asset.Colors.textAndIconPrimaryInverted.color,
                backgroundColor: Asset.Colors.interactiveElemetsPrimary.color,
                font: Typography.typographySemibold16,
                isEnabled: true,
                tapCommand: Command { [weak handler] in
                    await handler?.handleTapSubscribe()
                }
            )
        )
    }

    func makeContentViewModel(from data: AnalyticsFetchData) -> AnalyticsViewModel.ContentViewModel {
        return AnalyticsViewModel.ContentViewModel(
            presetPills: makePresetPillViewModels(selectedPreset: data.selectedPreset),
            body: makeBodyState(from: data)
        )
    }

    func makePresetPillViewModels(selectedPreset: AnalyticsPeriodPreset?) -> [AnalyticsViewModel.PresetPillViewModel] {
        AnalyticsPeriodPreset.allCases.map { preset in
            AnalyticsViewModel.PresetPillViewModel(
                preset: preset,
                title: title(for: preset),
                isSelected: preset == selectedPreset,
                tapCommand: Command { [weak handler] in
                    await handler?.handleSelectPreset(preset)
                }
            )
        }
    }

    func title(for preset: AnalyticsPeriodPreset) -> String {
        switch preset {
        case .day:
            return L10n.analyticsDay
        case .week:
            return L10n.analyticsWeek
        case .month:
            return L10n.analyticsMonth
        }
    }

    func makeBodyState(from data: AnalyticsFetchData) -> AnalyticsViewModel.BodyState {
        if let model = data.data, model.isEmpty == false {
            return .loaded(makeLoadedBodyViewModel(from: model))
        }

        switch data.loadingState {
        case .failed:
            return .error(makeErrorViewModel())
        case .idle, .loading, .loaded:
            return .empty(makeEmptyViewModel())
        }
    }

    func makeLoadedBodyViewModel(from model: AnalyticsDataModel) -> AnalyticsViewModel.LoadedBodyViewModel {
        let totalAmount = formatter.formatAmount(model.totalAmount, currencyCode: model.currency)

        return AnalyticsViewModel.LoadedBodyViewModel(
            totalAmount: .init(
                text: totalAmount,
                font: Typography.typographyBold36,
                textColor: Asset.Colors.textAndIconPrimary.color,
                alignment: .center
            ),
            chart: makeChartViewModel(
                categories: model.categories,
                totalAmount: totalAmount
            ),
            topCategoriesTitle: .init(
                text: L10n.mainOverviewCategories,
                font: Typography.typographyBold24,
                textColor: Asset.Colors.textAndIconPrimary.color,
                alignment: .left
            ),
            rows: model.categories.map(makeRowViewModel)
        )
    }

    func makeEmptyViewModel() -> Label.LabelViewModel {
        .init(
            text: L10n.analyticsEmpty,
            font: Typography.typographyMedium16,
            textColor: Asset.Colors.textAndIconSecondary.color,
            alignment: .center,
            numberOfLines: 0
        )
    }

    func makeChartViewModel(
        categories: [AnalyticsCategorySummaryModel],
        totalAmount: String
    ) -> AnalyticsChartSectionView.ViewModel {
        let legendItems = categories.map { category in
            AnalyticsChartSectionView.ViewModel.LegendItem(
                title: category.name,
                color: chartColor(for: category)
            )
        }
        let slices = categories.map { category in
            AnalyticsChartSectionView.ViewModel.Slice(
                value: category.share,
                color: chartColor(for: category)
            )
        }

        return .init(
            slices: slices,
            legendItems: legendItems,
            centerTitle: .init(
                text: L10n.analyticsSpent,
                font: Typography.typographyMedium12,
                textColor: Asset.Colors.textAndIconPlaceseholder.color,
                alignment: .center
            ),
            centerValue: .init(
                text: totalAmount,
                font: Typography.typographyBold30,
                textColor: Asset.Colors.textAndIconPrimary.color,
                alignment: .center
            )
        )
    }

    func makeRowViewModel(_ category: AnalyticsCategorySummaryModel) -> AnalyticsCategorySummaryCell.ViewModel {
        let backgroundColor = categoryBackgroundColor(for: category)
        let progressColor = chartColor(for: category)

        return AnalyticsCategorySummaryCell.ViewModel(
            id: category.id,
            iconText: category.icon,
            iconBackgroundColor: backgroundColor,
            progressColor: progressColor,
            progress: min(max(category.share, .zero), 1),
            title: .init(
                text: category.name,
                font: Typography.typographyBold16,
                textColor: Asset.Colors.textAndIconPrimary.color,
                alignment: .left
            ),
            amount: .init(
                text: formatter.formatAmount(category.amount, currencyCode: category.currency),
                font: Typography.typographyBold18,
                textColor: Asset.Colors.textAndIconPrimary.color,
                alignment: .right
            ),
            share: .init(
                text: formatter.formatShare(category.share),
                font: Typography.typographyRegular12,
                textColor: Asset.Colors.textAndIconPlaceseholder.color,
                alignment: .right
            ),
            tapCommand: category.isInteractive
                ? Command { [weak handler] in
                    await handler?.handleTapCategory(
                        id: category.id,
                        name: category.name
                    )
                }
                : .nope,
            isInteractive: category.isInteractive
        )
    }

    func chartColor(for category: AnalyticsCategorySummaryModel) -> UIColor {
        if category.colorValue.isEmpty {
            return Asset.Colors.textAndIconPlaceseholder.color.withAlphaComponent(0.45)
        }

        return colorProvider.accentColor(for: category.colorValue)
    }

    func categoryBackgroundColor(for category: AnalyticsCategorySummaryModel) -> UIColor {
        if category.colorValue.isEmpty {
            return Asset.Colors.interactiveInputBackground.color
        }

        return colorProvider.summaryColor(for: category.colorValue)
    }

    func makeErrorViewModel() -> FullScreenCommonErrorView.ViewModel {
        .init(
            title: .init(
                text: L10n.mainOverviewError,
                font: Typography.typographyBold14,
                textColor: Asset.Colors.textAndIconSecondary.color,
                alignment: .center
            ),
            tapCommand: Command { [weak handler] in
                await handler?.handleTapRetry()
            }
        )
    }
}
