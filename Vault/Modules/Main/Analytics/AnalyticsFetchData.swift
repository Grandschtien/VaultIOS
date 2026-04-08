import Foundation

struct AnalyticsFetchData: Equatable {
    let selectedPeriod: MainSummaryPeriod
    let loadingState: LoadingStatus
    let data: AnalyticsDataModel?

    init(
        selectedPeriod: MainSummaryPeriod,
        loadingState: LoadingStatus = .idle,
        data: AnalyticsDataModel? = nil
    ) {
        self.selectedPeriod = selectedPeriod
        self.loadingState = loadingState
        self.data = data
    }
}
