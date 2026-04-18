import Foundation
import UIKit

struct AnalyticsViewModel: Equatable {
    let periodButton: MainPeriodBarButtonView.ViewModel
    let state: State

    init(
        periodButton: MainPeriodBarButtonView.ViewModel = .init(),
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
        case empty(Label.LabelViewModel)
        case locked(LockedViewModel)
        case loaded(ContentViewModel)
    }

    struct LockedViewModel: Equatable {
        let button: Button.ButtonViewModel
    }

    struct ContentViewModel: Equatable {
        let periodTitle: Label.LabelViewModel
        let totalAmount: Label.LabelViewModel
        let chart: AnalyticsChartSectionView.ViewModel
        let topCategoriesTitle: Label.LabelViewModel
        let rows: [AnalyticsCategorySummaryCell.ViewModel]
    }
}
