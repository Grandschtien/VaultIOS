import WidgetKit

// sourcery: AutoMockable
protocol VylokWidgetTimelineReloading: Sendable {
    func reloadTimelines()
}

final class VylokWidgetTimelineReloader: VylokWidgetTimelineReloading {
    func reloadTimelines() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
