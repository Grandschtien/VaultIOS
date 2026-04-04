import Nivelir
import UIKit

struct AddExpenseBottomSheetConfiguration: LayoutScaleProviding {
    static func chooser() -> BottomSheet {
        make(detents: [.content], selectedDetentKey: .content)
    }

    static func aiEntry() -> BottomSheet {
        make(detents: [.content], selectedDetentKey: .content)
    }

    static func manualEntry() -> BottomSheet {
        make(detents: [.content], selectedDetentKey: .content)
    }

    static func categoryPicker() -> BottomSheet {
        make(detents: [.content], selectedDetentKey: .content)
    }

    static func applyChooser(to bottomSheet: BottomSheetController) {
        apply(
            detents: [.content],
            selectedDetentKey: .content,
            to: bottomSheet
        )
    }

    static func applyAiEntry(to bottomSheet: BottomSheetController) {
        apply(
            detents: [.content],
            selectedDetentKey: .content,
            to: bottomSheet
        )
    }

    static func applyManualEntry(to bottomSheet: BottomSheetController) {
        apply(
            detents: [.content],
            selectedDetentKey: .content,
            to: bottomSheet
        )
    }

    private static func make(
        detents: [BottomSheetDetent],
        selectedDetentKey: BottomSheetDetentKey
    ) -> BottomSheet {
        let configuration = Self()

        return BottomSheet(
            detents: detents,
            selectedDetentKey: selectedDetentKey,
            preferredCard: BottomSheetCard(cornerRadius: configuration.sizeL),
            preferredGrabber: nil,
            prefersScrollingExpandsHeight: false
        )
    }

    private static func apply(
        detents: [BottomSheetDetent],
        selectedDetentKey: BottomSheetDetentKey,
        to bottomSheet: BottomSheetController
    ) {
        let configuration = Self()

        MainActor.assumeIsolated {
            bottomSheet.detents = detents
            bottomSheet.selectedDetentKey = selectedDetentKey
            bottomSheet.preferredCard = BottomSheetCard(cornerRadius: configuration.sizeL)
            bottomSheet.preferredGrabber = nil
            bottomSheet.prefersScrollingExpandsHeight = false
        }
    }
}
