import Foundation

final class VylokWidgetSubscriptionOutputAdapter: SubscriptionOutput, @unchecked Sendable {
    private let widgetSnapshotSyncService: VylokWidgetSnapshotSyncing

    init(widgetSnapshotSyncService: VylokWidgetSnapshotSyncing) {
        self.widgetSnapshotSyncService = widgetSnapshotSyncService
    }

    func handleSubscriptionDidSync() async {
        await widgetSnapshotSyncService.syncSnapshot()
    }
}
