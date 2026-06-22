import Foundation

final class VaultWidgetSubscriptionOutputAdapter: SubscriptionOutput, @unchecked Sendable {
    private let widgetSnapshotSyncService: VaultWidgetSnapshotSyncing

    init(widgetSnapshotSyncService: VaultWidgetSnapshotSyncing) {
        self.widgetSnapshotSyncService = widgetSnapshotSyncService
    }

    func handleSubscriptionDidSync() async {
        await widgetSnapshotSyncService.syncSnapshot()
    }
}
