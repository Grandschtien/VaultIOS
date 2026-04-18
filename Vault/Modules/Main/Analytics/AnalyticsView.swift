import SwiftUI
import Charts
import UIKit
import SkeletonView

struct AnalyticsView: View {
    @ObservedObject var viewModelStore: ViewModelStore<AnalyticsViewModel>
    private let metrics = Metrics()
    private let images = AnalyticsImages()

    var body: some View {
        Group {
            switch viewModelStore.viewModel.state {
            case .loading: loadingView
            case let .error(viewModel): errorView(viewModel)
            case let .empty(viewModel): emptyView(viewModel)
            case let .locked(viewModel): lockedView(viewModel)
            case let .loaded(viewModel): loadedView(viewModel)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(uiColor: Asset.Colors.backgroundPrimary.color))
    }

    private var loadingView: some View {
        ScrollView {
            VStack(spacing: metrics.spaceM) {
                placeholder(width: metrics.sizeXL, height: metrics.sizeS, radius: metrics.sizeS).frame(maxWidth: .infinity)
                placeholder(width: metrics.sizeXXL, height: metrics.sizeL, radius: metrics.sizeS).frame(maxWidth: .infinity)
                placeholder(radius: metrics.sizeS).aspectRatio(1, contentMode: .fit)
                placeholder(width: metrics.sizeXXL, height: metrics.sizeM, radius: metrics.sizeS).frame(maxWidth: .infinity, alignment: .leading)
                ForEach(0..<3, id: \.self) { _ in placeholder(height: metrics.sizeXL, radius: metrics.sizeM) }
            }
            .padding(.vertical, metrics.spaceS)
            .padding(.horizontal, metrics.spaceS)
        }
        .scrollIndicators(.hidden)
    }

    private func errorView(_ viewModel: FullScreenCommonErrorView.ViewModel) -> some View {
        VStack {
            SwiftUI.Button(action: { viewModel.tapCommand.execute() }) {
                text(viewModel.title)
                    .padding(metrics.spaceS)
                    .frame(maxWidth: .infinity, minHeight: metrics.sizeXL)
                    .background(Color(uiColor: Asset.Colors.interactiveInputBackground.color))
                    .clipShape(RoundedRectangle(cornerRadius: metrics.sizeM, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: metrics.sizeM, style: .continuous).stroke(Color(uiColor: Asset.Colors.textAndIconPlaceseholder.color).opacity(0.35), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .padding(metrics.spaceS)
            Spacer()
        }
    }

    private func emptyView(_ viewModel: Label.LabelViewModel) -> some View {
        VStack { Spacer(); text(viewModel).padding(.horizontal, metrics.spaceL); Spacer() }
    }

    private func lockedView(_ viewModel: AnalyticsViewModel.LockedViewModel) -> some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial)
            SwiftUI.Button(action: { viewModel.button.tapCommand.execute() }) {
                Group {
                    if viewModel.button.isLoading {
                        ProgressView().tint(Color(uiColor: viewModel.button.titleColor))
                    } else {
                        Text(viewModel.button.title)
                            .font(.system(size: viewModel.button.font.pointSize, weight: viewModel.button.font.fontWeight))
                            .foregroundStyle(Color(uiColor: viewModel.button.titleColor))
                    }
                }
                .padding(.horizontal, metrics.spaceM)
                .frame(minHeight: viewModel.button.height)
                .background(Color(uiColor: viewModel.button.backgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: viewModel.button.cornerRadius, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.button.isEnabled == false || viewModel.button.isLoading)
            .padding(.horizontal, metrics.spaceL)
        }
    }

    private func loadedView(_ viewModel: AnalyticsViewModel.ContentViewModel) -> some View {
        ScrollView {
            VStack(spacing: metrics.spaceM) {
                text(viewModel.periodTitle)
                text(viewModel.totalAmount)
                chartView(viewModel.chart)
                text(viewModel.topCategoriesTitle)
                VStack(spacing: metrics.spaceXS) {
                    ForEach(viewModel.rows, id: \.id) { rowView($0) }
                }
            }
            .padding(.vertical, metrics.spaceS)
            .padding(.horizontal, metrics.spaceS)
        }
        .scrollIndicators(.hidden)
    }

    private func chartView(_ viewModel: AnalyticsChartSectionView.ViewModel) -> some View {
        VStack(spacing: metrics.spaceS) {
            ZStack {
                Chart(Array(viewModel.slices.enumerated()), id: \.offset) { _, slice in
                    SectorMark(angle: .value("Share", slice.value), innerRadius: .ratio(0.72), angularInset: 3)
                        .foregroundStyle(Color(uiColor: slice.color))
                }
                .chartLegend(.hidden)
                .allowsHitTesting(false)
                .aspectRatio(1, contentMode: .fit)

                VStack(spacing: metrics.spaceXXS) {
                    image(
                        images.sparklesImage,
                        tintColor: Asset.Colors.interactiveElemetsPrimary.color
                    )
                    text(viewModel.centerTitle)
                    text(viewModel.centerValue)
                }
                .padding(metrics.spaceS)
            }

            LazyVGrid(columns: [.init(.flexible(), spacing: metrics.spaceS), .init(.flexible(), spacing: metrics.spaceS)], spacing: metrics.spaceS) {
                ForEach(Array(viewModel.legendItems.enumerated()), id: \.offset) { _, item in
                    HStack(spacing: metrics.spaceXS) {
                        Circle().fill(Color(uiColor: item.color)).frame(width: metrics.sizeXS, height: metrics.sizeXS)
                        Text(item.title)
                            .font(.system(size: Typography.typographyMedium14.pointSize, weight: Typography.typographyMedium14.fontWeight))
                            .foregroundStyle(Color(uiColor: Asset.Colors.textAndIconSecondary.color))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func rowView(_ viewModel: AnalyticsCategorySummaryCell.ViewModel) -> some View {
        let card = VStack(spacing: metrics.spaceS) {
            HStack(alignment: .top, spacing: metrics.spaceS) {
                Text(viewModel.iconText)
                    .font(.system(size: Typography.typographyBold18.pointSize, weight: Typography.typographyBold18.fontWeight))
                    .foregroundStyle(Color(uiColor: Asset.Colors.textAndIconSecondary.color))
                    .frame(width: metrics.sizeL, height: metrics.sizeL)
                    .background(Color(uiColor: viewModel.iconBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: metrics.sizeS, style: .continuous))
                text(viewModel.title)
                    .layoutPriority(0)
                VStack(alignment: .trailing, spacing: metrics.spaceXXS) {
                    intrinsicText(viewModel.amount)
                    intrinsicText(viewModel.share)
                }
                .fixedSize(horizontal: true, vertical: false)
                .layoutPriority(1)
                if viewModel.isInteractive {
                    image(
                        images.chevronRightImage,
                        tintColor: Asset.Colors.textAndIconPlaceseholder.color
                    )
                    .padding(.top, metrics.spaceXS)
                    .fixedSize()
                }
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(uiColor: Asset.Colors.backgroundPrimary.color))
                    Capsule().fill(Color(uiColor: viewModel.progressColor)).frame(width: proxy.size.width * max(0, min(viewModel.progress, 1)))
                }
            }
            .frame(height: metrics.spaceXS)
        }
        .padding(metrics.spaceS)
        .background(Color(uiColor: Asset.Colors.interactiveInputBackground.color))
        .clipShape(RoundedRectangle(cornerRadius: metrics.sizeM, style: .continuous))

        if viewModel.isInteractive {
            SwiftUI.Button(action: { viewModel.tapCommand.execute() }) { card }.buttonStyle(.plain)
        } else {
            card
        }
    }

    private func text(_ viewModel: Label.LabelViewModel) -> some View {
        Text(viewModel.text)
            .font(.system(size: viewModel.font.pointSize, weight: viewModel.font.fontWeight))
            .foregroundStyle(Color(uiColor: viewModel.textColor))
            .multilineTextAlignment(viewModel.alignment.textAlignment)
            .lineLimit(viewModel.numberOfLines == 0 ? nil : viewModel.numberOfLines)
            .frame(maxWidth: .infinity, alignment: viewModel.alignment.alignment)
    }

    private func intrinsicText(_ viewModel: Label.LabelViewModel) -> some View {
        Text(viewModel.text)
            .font(.system(size: viewModel.font.pointSize, weight: viewModel.font.fontWeight))
            .foregroundStyle(Color(uiColor: viewModel.textColor))
            .multilineTextAlignment(viewModel.alignment.textAlignment)
            .lineLimit(viewModel.numberOfLines == 0 ? nil : viewModel.numberOfLines)
            .fixedSize(horizontal: true, vertical: false)
    }

    private func image(_ uiImage: UIImage?, tintColor: UIColor) -> some View {
        Group {
            if let uiImage {
                Image(uiImage: uiImage)
                    .renderingMode(.template)
                    .foregroundStyle(Color(uiColor: tintColor))
            } else {
                EmptyView()
            }
        }
    }

    private func placeholder(width: CGFloat? = nil, height: CGFloat? = nil, radius: CGFloat) -> some View {
        SkeletonPlaceholderView(radius: radius)
            .frame(width: width, height: height)
    }
}

private struct Metrics: LayoutScaleProviding {}
private struct AnalyticsImages: ImageProviding {}

private struct SkeletonPlaceholderView: UIViewRepresentable {
    let radius: CGFloat

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        configure(view)
        view.showAnimatedGradientSkeleton()
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        configure(uiView)
        if uiView.sk.isSkeletonActive == false {
            uiView.showAnimatedGradientSkeleton()
        }
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: ()) {
        uiView.hideSkeleton()
    }

    private func configure(_ view: UIView) {
        view.isSkeletonable = true
        view.backgroundColor = Asset.Colors.interactiveInputBackground.color
        view.layer.cornerRadius = radius
        view.skeletonCornerRadius = Float(radius)
    }
}

private extension NSTextAlignment {
    var alignment: Alignment { self == .center ? .center : self == .right ? .trailing : .leading }
    var textAlignment: TextAlignment { self == .center ? .center : self == .right ? .trailing : .leading }
}

private extension UIFont {
    var fontWeight: Font.Weight {
        let traits = fontDescriptor.object(forKey: .traits) as? [UIFontDescriptor.TraitKey: Any]
        let value = (traits?[.weight] as? CGFloat) ?? UIFont.Weight.regular.rawValue
        switch value {
        case let value where value >= UIFont.Weight.bold.rawValue: return .bold
        case let value where value >= UIFont.Weight.semibold.rawValue: return .semibold
        case let value where value >= UIFont.Weight.medium.rawValue: return .medium
        case let value where value <= UIFont.Weight.light.rawValue: return .light
        default: return .regular
        }
    }
}
