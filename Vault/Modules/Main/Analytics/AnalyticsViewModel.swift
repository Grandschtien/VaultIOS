import Foundation
import UIKit

struct AnalyticsViewModel: Equatable {
    let monthBarButton: AnalyticsMonthBarButtonView.ViewModel
    let state: State

    init(
        monthBarButton: AnalyticsMonthBarButtonView.ViewModel = .init(),
        state: State = .loading
    ) {
        self.monthBarButton = monthBarButton
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
