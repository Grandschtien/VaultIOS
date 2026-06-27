import SwiftUI
import WidgetKit

private struct VylokAIEntryWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: VylokWidgetSnapshot?
}

private struct VylokAIEntryWidgetProvider: TimelineProvider {
    private let storage = VylokWidgetSnapshotStorage()
    private let timelineResolver = VylokWidgetSnapshotTimelineResolver()

    func placeholder(in context: Context) -> VylokAIEntryWidgetEntry {
        VylokAIEntryWidgetEntry(
            date: Date(),
            snapshot: nil
        )
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (VylokAIEntryWidgetEntry) -> Void
    ) {
        let currentDate = Date()
        completion(
            VylokAIEntryWidgetEntry(
                date: currentDate,
                snapshot: timelineResolver.resolveSnapshot(
                    storage.loadSnapshot(),
                    at: currentDate
                )
            )
        )
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<VylokAIEntryWidgetEntry>) -> Void
    ) {
        let currentDate = Date()
        let storedSnapshot = storage.loadSnapshot()
        let currentEntry = VylokAIEntryWidgetEntry(
            date: currentDate,
            snapshot: timelineResolver.resolveSnapshot(
                storedSnapshot,
                at: currentDate
            )
        )
        let futureEntries = timelineResolver.significantDates(
            for: storedSnapshot,
            currentDate: currentDate
        )
        .map { refreshDate in
            VylokAIEntryWidgetEntry(
                date: refreshDate,
                snapshot: timelineResolver.resolveSnapshot(
                    storedSnapshot,
                    at: refreshDate
                )
            )
        }
        let entries = [currentEntry] + futureEntries
        let policy: TimelineReloadPolicy
        if let nextRefreshDate = timelineResolver.nextSignificantDate(
            for: storedSnapshot,
            currentDate: currentDate
        ) {
            policy = .after(nextRefreshDate)
        } else {
            policy = .never
        }

        completion(
            Timeline(
                entries: entries,
                policy: policy
            )
        )
    }
}

private struct VylokWidgetMetrics: LayoutScaleProviding {}

private enum VylokAIEntrySmallState {
    case signedOut
    case subscribe
    case content
}

struct VylokAIEntryWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "VaultAIEntryWidget",
            provider: VylokAIEntryWidgetProvider()
        ) { entry in
            VylokAIEntryWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(L10n.vaultWidgetConfigurationDisplayName)
        .description(L10n.vaultWidgetConfigurationDescription)
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

private struct VylokAIEntryWidgetEntryView: View {
    @Environment(\.widgetFamily)
    private var family

    private let metrics = VylokWidgetMetrics()
    let entry: VylokAIEntryWidgetEntry

    var body: some View {
        ZStack {
            Rectangle()
                .fill(VylokWidgetAssetCatalog.backgroundPrimary.swiftUIColor)

            switch family {
            case .systemSmall:
                VylokAIEntrySmallView(entry: entry)
            case .systemMedium:
                VylokAIEntryMediumView(entry: entry)
            default:
                VylokAIEntrySmallView(entry: entry)
            }
        }
        .widgetURL(widgetURL)
        .containerBackground(for: .widget) {
            Color.clear
        }
    }

    private var widgetURL: URL {
        switch family {
        case .systemSmall:
            switch smallState {
            case .signedOut, .content:
                VylokRoute.home.url
            case .subscribe:
                VylokRoute.subscription.url
            }
        default:
            VylokRoute.home.url
        }
    }

    private var smallState: VylokAIEntrySmallState {
        guard let snapshot = entry.snapshot else {
            return .signedOut
        }

        return snapshot.entitlementState == .regular ? .subscribe : .content
    }
}

private struct VylokAIEntrySmallView: View {
    private let metrics = VylokWidgetMetrics()
    let entry: VylokAIEntryWidgetEntry

    var body: some View {
        switch state {
        case .signedOut:
            VylokWidgetCenteredCTAView(
                title: L10n.vaultWidgetLogIn,
                destination: VylokRoute.home.url
            )
        case .subscribe:
            VylokWidgetCenteredCTAView(
                title: L10n.vaultWidgetSubscribe,
                destination: VylokRoute.subscription.url
            )
        case .content:
            VStack(alignment: .leading, spacing: metrics.spaceXXS) {
                HStack(spacing: metrics.spaceXS) {
                    Image(systemName: "wallet.pass")
                        .font(.appTypography(Typography.typographySemibold16))
                        .foregroundStyle(VylokWidgetAssetCatalog.widgetAccentPrimary.swiftUIColor)

                    Text(L10n.vaultWidgetBrand)
                        .font(.appTypography(Typography.typographyBold16))
                        .foregroundStyle(VylokWidgetAssetCatalog.widgetTextTertiary.swiftUIColor)
                        .textCase(.uppercase)
                        .tracking(1.2)
                }

                VStack(alignment: .leading, spacing: metrics.spaceXXS) {
                    Text(L10n.vaultWidgetSpentToday)
                        .font(.appTypography(Typography.typographyMedium14))
                        .foregroundStyle(VylokWidgetAssetCatalog.widgetTextSecondary.swiftUIColor)

                    Text(VylokWidgetValueFormatter.string(
                        amount: entry.snapshot?.todayAmount,
                        currency: entry.snapshot?.todayCurrency
                    ))
                        .font(.appTypography(Typography.typographyBold16))
                        .foregroundStyle(VylokWidgetAssetCatalog.widgetTextPrimary.swiftUIColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }

                HStack(alignment: .bottom) {
                    VylokWidgetDecorativeBars()

                    Spacer()

                    Link(destination: VylokRoute.aiEntry.url) {
                        VylokWidgetPlusButton()
                    }
                }
            }
            .padding(.top, metrics.spaceXXS)
            .padding(.horizontal, metrics.spaceS)
            .padding(.bottom, metrics.spaceXXS)
        }
    }

    private var state: VylokAIEntrySmallState {
        guard let snapshot = entry.snapshot else {
            return .signedOut
        }

        return snapshot.entitlementState == .regular ? .subscribe : .content
    }
}

private struct VylokAIEntryMediumView: View {
    private let metrics = VylokWidgetMetrics()
    let entry: VylokAIEntryWidgetEntry

    var body: some View {
        if entry.snapshot == nil {
            VylokWidgetCenteredCTAView(
                title: L10n.vaultWidgetLogIn,
                destination: VylokRoute.home.url
            )
        } else {
            VStack(alignment: .leading, spacing: metrics.spaceXXS) {
                Text(L10n.vaultWidgetTotalSpent)
                    .font(.appTypography(Typography.typographyBold16))
                    .foregroundStyle(VylokWidgetAssetCatalog.widgetTextTertiary.swiftUIColor)
                    .tracking(1.2)

                Text(VylokWidgetValueFormatter.string(
                    amount: entry.snapshot?.monthAmount,
                    currency: entry.snapshot?.monthCurrency
                ))
                    .font(.appTypography(Typography.typographyBold24))
                    .foregroundStyle(VylokWidgetAssetCatalog.widgetTextPrimary.swiftUIColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                HStack(spacing: metrics.spaceS) {
                    Image(systemName: "fork.knife")
                    Image(systemName: "car")
                    Image(systemName: "gamecontroller")
                }
                .font(.appTypography(Typography.typographyMedium18))
                .foregroundStyle(VylokWidgetAssetCatalog.widgetTextSubtle.swiftUIColor)
                .frame(maxWidth: .infinity, alignment: .trailing)

                HStack(alignment: .center, spacing: metrics.spaceXS) {
                    Spacer()
                    Link(destination: VylokRoute.aiEntry.url) {
                        VylokWidgetPlusButton()
                    }
                }
            }
            .padding(.top, metrics.spaceS)
            .padding(.horizontal, metrics.spaceS)
            .padding(.bottom, metrics.spaceS)
        }
    }
}

private struct VylokWidgetCenteredCTAView: View {
    private let metrics = VylokWidgetMetrics()
    let title: String
    let destination: URL

    var body: some View {
        VStack {
            Spacer()

            Link(destination: destination) {
                Text(title)
                    .font(.appTypography(Typography.typographyBold16))
                    .foregroundStyle(VylokWidgetAssetCatalog.widgetForegroundInverted.swiftUIColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, metrics.spaceS)
                    .background(VylokWidgetAssetCatalog.widgetAccentPrimary.swiftUIColor)
                    .clipShape(Capsule())
            }

            Spacer()
        }
        .padding(.horizontal, metrics.spaceS)
        .padding(.vertical, metrics.spaceS)
    }
}

private struct VylokWidgetPlusButton: View {
    private let metrics = VylokWidgetMetrics()

    var body: some View {
        ZStack {
            Circle()
                .fill(VylokWidgetAssetCatalog.widgetAccentPrimary.swiftUIColor)
                .frame(width: metrics.sizeXL, height: metrics.sizeXL)

            Image(systemName: "plus")
                .font(.appTypography(Typography.typographyBold22))
                .foregroundStyle(VylokWidgetAssetCatalog.widgetForegroundInverted.swiftUIColor)
        }
    }
}

private struct VylokWidgetDecorativeBars: View {
    private let metrics = VylokWidgetMetrics()

    var body: some View {
        HStack(alignment: .bottom, spacing: metrics.spaceXXS) {
            Capsule().fill(VylokWidgetAssetCatalog.widgetDecorativeBar.swiftUIColor).frame(width: metrics.sizeXS, height: metrics.sizeS)
            Capsule().fill(VylokWidgetAssetCatalog.widgetDecorativeBar.swiftUIColor).frame(width: metrics.sizeXS, height: metrics.sizeL)
            Capsule().fill(VylokWidgetAssetCatalog.widgetDecorativeBar.swiftUIColor).frame(width: metrics.sizeXS, height: metrics.sizeS)
            Capsule().fill(VylokWidgetAssetCatalog.widgetDecorativeBar.swiftUIColor).frame(width: metrics.sizeXS, height: metrics.sizeM)
        }
    }
}
