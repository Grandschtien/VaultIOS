import SwiftUI
import WidgetKit

private struct VaultAIEntryWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: VaultWidgetSnapshot?
}

private struct VaultAIEntryWidgetProvider: TimelineProvider {
    private let storage = VaultWidgetSnapshotStorage()

    func placeholder(in context: Context) -> VaultAIEntryWidgetEntry {
        VaultAIEntryWidgetEntry(
            date: Date(),
            snapshot: nil
        )
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (VaultAIEntryWidgetEntry) -> Void
    ) {
        completion(
            VaultAIEntryWidgetEntry(
                date: Date(),
                snapshot: storage.loadSnapshot()
            )
        )
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<VaultAIEntryWidgetEntry>) -> Void
    ) {
        let currentDate = Date()
        let entry = VaultAIEntryWidgetEntry(
            date: currentDate,
            snapshot: storage.loadSnapshot()
        )
        let refreshDate = Calendar.current.date(
            byAdding: .minute,
            value: 15,
            to: currentDate
        ) ?? currentDate.addingTimeInterval(900)

        completion(
            Timeline(
                entries: [entry],
                policy: .after(refreshDate)
            )
        )
    }
}

private struct VaultWidgetMetrics: LayoutScaleProviding {}

struct VaultAIEntryWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "VaultAIEntryWidget",
            provider: VaultAIEntryWidgetProvider()
        ) { entry in
            VaultAIEntryWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(L10n.vaultWidgetConfigurationDisplayName)
        .description(L10n.vaultWidgetConfigurationDescription)
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

private struct VaultAIEntryWidgetEntryView: View {
    @Environment(\.widgetFamily)
    private var family

    private let metrics = VaultWidgetMetrics()
    let entry: VaultAIEntryWidgetEntry

    var body: some View {
        ZStack {
            Rectangle()
                .fill(VaultWidgetAssetCatalog.backgroundPrimary.swiftUIColor)

            switch family {
            case .systemSmall:
                VaultAIEntrySmallView(entry: entry)
            case .systemMedium:
                VaultAIEntryMediumView(entry: entry)
            default:
                VaultAIEntrySmallView(entry: entry)
            }
        }
        .widgetURL(VaultRoute.home.url)
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
}

private struct VaultAIEntrySmallView: View {
    private let metrics = VaultWidgetMetrics()
    let entry: VaultAIEntryWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: metrics.spaceXXS) {
            HStack(spacing: metrics.spaceXS) {
                Image(systemName: "wallet.pass")
                    .font(.appTypography(Typography.typographySemibold16))
                    .foregroundStyle(VaultWidgetAssetCatalog.widgetAccentPrimary.swiftUIColor)

                Text(L10n.vaultWidgetBrand)
                    .font(.appTypography(Typography.typographyBold16))
                    .foregroundStyle(VaultWidgetAssetCatalog.widgetTextTertiary.swiftUIColor)
                    .textCase(.uppercase)
                    .tracking(1.2)
            }

            VStack(alignment: .leading, spacing: metrics.spaceXXS) {
                Text(L10n.vaultWidgetSpentToday)
                    .font(.appTypography(Typography.typographyMedium14))
                    .foregroundStyle(VaultWidgetAssetCatalog.widgetTextSecondary.swiftUIColor)

                Text(VaultWidgetValueFormatter.string(
                    amount: entry.snapshot?.todayAmount,
                    currency: entry.snapshot?.todayCurrency
                ))
                    .font(.appTypography(Typography.typographyBold16))
                    .foregroundStyle(VaultWidgetAssetCatalog.widgetTextPrimary.swiftUIColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            HStack(alignment: .bottom) {
                VaultWidgetDecorativeBars()

                Spacer()

                Link(destination: VaultRoute.aiEntry.url) {
                    VaultWidgetPlusButton()
                }
            }
        }
        .padding(.top, metrics.spaceXXS)
        .padding(.horizontal, metrics.spaceS)
        .padding(.bottom, metrics.spaceXXS)
    }
}

private struct VaultAIEntryMediumView: View {
    private let metrics = VaultWidgetMetrics()
    let entry: VaultAIEntryWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: metrics.spaceXXS) {
            Text(L10n.vaultWidgetTotalSpent)
                .font(.appTypography(Typography.typographyBold16))
                .foregroundStyle(VaultWidgetAssetCatalog.widgetTextTertiary.swiftUIColor)
                .tracking(1.2)

            Text(VaultWidgetValueFormatter.string(
                amount: entry.snapshot?.monthAmount,
                currency: entry.snapshot?.monthCurrency
            ))
                .font(.appTypography(Typography.typographyBold24))
                .foregroundStyle(VaultWidgetAssetCatalog.widgetTextPrimary.swiftUIColor)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            HStack(spacing: metrics.spaceS) {
                Image(systemName: "fork.knife")
                Image(systemName: "car")
                Image(systemName: "gamecontroller")
            }
            .font(.appTypography(Typography.typographyMedium18))
            .foregroundStyle(VaultWidgetAssetCatalog.widgetTextSubtle.swiftUIColor)
            .frame(maxWidth: .infinity, alignment: .trailing)

            HStack(alignment: .center, spacing: metrics.spaceXS) {
                Spacer()
                Link(destination: VaultRoute.aiEntry.url) {
                    VaultWidgetPlusButton()
                }
            }
        }
        .padding(.top, metrics.spaceS)
        .padding(.horizontal, metrics.spaceS)
        .padding(.bottom, metrics.spaceS)
    }
}

private struct VaultWidgetPlusButton: View {
    private let metrics = VaultWidgetMetrics()

    var body: some View {
        ZStack {
            Circle()
                .fill(VaultWidgetAssetCatalog.widgetAccentPrimary.swiftUIColor)
                .frame(width: metrics.sizeXL, height: metrics.sizeXL)

            Image(systemName: "plus")
                .font(.appTypography(Typography.typographyBold22))
                .foregroundStyle(VaultWidgetAssetCatalog.widgetForegroundInverted.swiftUIColor)
        }
    }
}

private struct VaultWidgetDecorativeBars: View {
    private let metrics = VaultWidgetMetrics()

    var body: some View {
        HStack(alignment: .bottom, spacing: metrics.spaceXXS) {
            Capsule().fill(VaultWidgetAssetCatalog.widgetDecorativeBar.swiftUIColor).frame(width: metrics.sizeXS, height: metrics.sizeS)
            Capsule().fill(VaultWidgetAssetCatalog.widgetDecorativeBar.swiftUIColor).frame(width: metrics.sizeXS, height: metrics.sizeL)
            Capsule().fill(VaultWidgetAssetCatalog.widgetDecorativeBar.swiftUIColor).frame(width: metrics.sizeXS, height: metrics.sizeS)
            Capsule().fill(VaultWidgetAssetCatalog.widgetDecorativeBar.swiftUIColor).frame(width: metrics.sizeXS, height: metrics.sizeM)
        }
    }
}
