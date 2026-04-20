import UIKit
import SnapKit

final class AnalyticsChartSectionView  {
    struct ViewModel: Equatable {
        struct Slice: Equatable {
            let value: Double
            let color: UIColor
        }

        struct LegendItem: Equatable {
            let title: String
            let color: UIColor
        }

        let slices: [Slice]
        let legendItems: [LegendItem]
        let centerTitle: Label.LabelViewModel
        let centerValue: Label.LabelViewModel

        init(
            slices: [Slice] = [],
            legendItems: [LegendItem] = [],
            centerTitle: Label.LabelViewModel = .init(),
            centerValue: Label.LabelViewModel = .init()
        ) {
            self.slices = slices
            self.legendItems = legendItems
            self.centerTitle = centerTitle
            self.centerValue = centerValue
        }
    }
}
