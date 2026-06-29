import Foundation

struct AnalyticsFetchData: Equatable {
    let selectedPeriod: MainSummaryPeriod
    let selectedPreset: AnalyticsPeriodPreset?
    let isLocked: Bool
    let loadingState: LoadingStatus
    let data: AnalyticsDataModel?
    let showsContentShell: Bool

    init(
        selectedPeriod: MainSummaryPeriod,
        selectedPreset: AnalyticsPeriodPreset? = nil,
        isLocked: Bool = false,
        loadingState: LoadingStatus = .idle,
        data: AnalyticsDataModel? = nil,
        showsContentShell: Bool = false
    ) {
        self.selectedPeriod = selectedPeriod
        self.selectedPreset = selectedPreset
        self.isLocked = isLocked
        self.loadingState = loadingState
        self.data = data
        self.showsContentShell = showsContentShell
    }
}
