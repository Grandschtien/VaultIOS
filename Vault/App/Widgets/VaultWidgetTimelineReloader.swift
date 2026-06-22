import WidgetKit

protocol VaultWidgetTimelineReloading: Sendable {
    func reloadTimelines()
}

final class VaultWidgetTimelineReloader: VaultWidgetTimelineReloading {
    func reloadTimelines() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
