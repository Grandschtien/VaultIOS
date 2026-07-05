import Foundation
import UIKit

struct AnalyticsViewModel: Equatable {
    let periodButton: AnalyticsMonthBarButtonView.ViewModel
    let state: State

    init(
        periodButton: AnalyticsMonthBarButtonView.ViewModel = .init(),
        state: State = .loading
    ) {
        self.periodButton = periodButton
        self.state = state
    }
}

extension AnalyticsViewModel {
    enum State: Equatable {
        case loading
        case error(FullScreenCommonErrorView.ViewModel)
        case locked(LockedViewModel)
        case content(ContentViewModel)
    }

    struct LockedViewModel: Equatable {
        let button: Button.ButtonViewModel
    }

    struct PresetPillViewModel: Equatable {
        let preset: AnalyticsPeriodPreset
        let title: String
        let isSelected: Bool
        let tapCommand: Command
    }

    enum BodyState: Equatable {
        case loading
        case error(FullScreenCommonErrorView.ViewModel)
        case empty(Label.LabelViewModel)
        case loaded(LoadedBodyViewModel)
    }

    struct LoadedBodyViewModel: Equatable {
        let totalAmount: Label.LabelViewModel
        let chart: AnalyticsChartSectionView.ViewModel
        let topCategoriesTitle: Label.LabelViewModel
        let rows: [AnalyticsCategorySummaryCell.ViewModel]
    }

    struct ContentViewModel: Equatable {
        let presetPills: [PresetPillViewModel]
        let isPeriodSwipeEnabled: Bool
        let swipeToPreviousPeriodCommand: Command
        let swipeToNextPeriodCommand: Command
        let body: BodyState

        init(
            presetPills: [PresetPillViewModel] = [],
            isPeriodSwipeEnabled: Bool = false,
            swipeToPreviousPeriodCommand: Command = .nope,
            swipeToNextPeriodCommand: Command = .nope,
            body: BodyState = .loading
        ) {
            self.presetPills = presetPills
            self.isPeriodSwipeEnabled = isPeriodSwipeEnabled
            self.swipeToPreviousPeriodCommand = swipeToPreviousPeriodCommand
            self.swipeToNextPeriodCommand = swipeToNextPeriodCommand
            self.body = body
        }
    }
}
