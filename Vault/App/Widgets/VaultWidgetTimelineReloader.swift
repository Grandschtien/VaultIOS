import WidgetKit

protocol VylokWidgetTimelineReloading: Sendable {
    func reloadTimelines()
}

final class VylokWidgetTimelineReloader: VylokWidgetTimelineReloading {
    func reloadTimelines() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
