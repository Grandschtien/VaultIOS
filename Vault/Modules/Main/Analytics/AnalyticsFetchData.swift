import Foundation

struct AnalyticsFetchData: Equatable {
    let selectedPeriod: MainSummaryPeriod
    let isLocked: Bool
    let loadingState: LoadingStatus
    let data: AnalyticsDataModel?

    init(
        selectedPeriod: MainSummaryPeriod,
        isLocked: Bool = false,
        loadingState: LoadingStatus = .idle,
        data: AnalyticsDataModel? = nil
    ) {
        self.selectedPeriod = selectedPeriod
        self.isLocked = isLocked
        self.loadingState = loadingState
        self.data = data
    }
}
