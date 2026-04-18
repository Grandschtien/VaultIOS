import Foundation
import UIKit
internal import Combine

@MainActor
protocol AnalyticsPresentationLogic: Sendable {
    func presentFetchedData(_ data: AnalyticsFetchData)
}

final class AnalyticsPresenter: AnalyticsPresentationLogic {
    private enum Constants {
        static let visibleLegendItemsCount = 3
    }

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
            periodButton: .init(
                tapCommand: Command { [weak handler] in
                    await handler?.handleTapMonthFilter()
                }
            ),
            state: makeState(from: data)
        )
    }
}

private extension AnalyticsPresenter {
    func makeState(from data: AnalyticsFetchData) -> AnalyticsViewModel.State {
        if data.isLocked {
            return .locked(makeLockedViewModel())
        }

        if let model = data.data, model.isEmpty == false {
            return .loaded(
                makeContentViewModel(
                    from: model,
                    selectedPeriod: data.selectedPeriod
                )
            )
        }

        switch data.loadingState {
        case .idle, .loading:
            return .loading
        case .failed:
            return .error(makeErrorViewModel())
        case .loaded:
            return .empty(
                .init(
                    text: L10n.analyticsEmpty,
                    font: Typography.typographyMedium16,
                    textColor: Asset.Colors.textAndIconSecondary.color,
                    alignment: .center,
                    numberOfLines: 0
                )
            )
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

    func makeContentViewModel(
        from model: AnalyticsDataModel,
        selectedPeriod: MainSummaryPeriod
    ) -> AnalyticsViewModel.ContentViewModel {
        let visibleCategories = Array(model.categories.prefix(Constants.visibleLegendItemsCount))
        let visibleShare = visibleCategories.reduce(.zero) { partialResult, category in
            partialResult + category.share
        }

        return AnalyticsViewModel.ContentViewModel(
            periodTitle: .init(
                text: formatter.formatPeriodTitle(
                    from: selectedPeriod.from,
                    to: selectedPeriod.to
                ),
                font: Typography.typographyMedium18,
                textColor: Asset.Colors.textAndIconSecondary.color,
                alignment: .center
            ),
            totalAmount: .init(
                text: formatter.formatAmount(model.totalAmount, currencyCode: model.currency),
                font: Typography.typographyBold36,
                textColor: Asset.Colors.textAndIconPrimary.color,
                alignment: .center
            ),
            chart: makeChartViewModel(
                categories: model.categories,
                visibleShare: visibleShare
            ),
            topCategoriesTitle: .init(
                text: L10n.analyticsTopCategories,
                font: Typography.typographyBold24,
                textColor: Asset.Colors.textAndIconPrimary.color,
                alignment: .left
            ),
            rows: model.categories.map(makeRowViewModel)
        )
    }

    func makeChartViewModel(
        categories: [AnalyticsCategorySummaryModel],
        visibleShare: Double
    ) -> AnalyticsChartSectionView.ViewModel {
        let legendItems = categories.prefix(Constants.visibleLegendItemsCount).map { category in
            AnalyticsChartSectionView.ViewModel.LegendItem(
                title: category.name,
                color: chartColor(for: category)
            )
        }
        let visibleCategories = categories.prefix(Constants.visibleLegendItemsCount).map { category in
            AnalyticsChartSectionView.ViewModel.Slice(
                value: category.share,
                color: chartColor(for: category)
            )
        }
        let remainderShare = max(0, 1 - visibleCategories.reduce(.zero) { partialResult, category in
            partialResult + category.value
        })
        let slices: [AnalyticsChartSectionView.ViewModel.Slice]
        if remainderShare > .zero {
            slices = visibleCategories + [
                .init(
                    value: remainderShare,
                    color: Asset.Colors.interactiveInputBackground.color
                )
            ]
        } else {
            slices = visibleCategories
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
                text: formatter.formatPercent(visibleShare),
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
