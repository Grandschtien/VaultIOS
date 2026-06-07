import XCTest
import UIKit
@testable import Vault

@MainActor
final class DeleteTableViewCellWrapperTests: XCTestCase {
    func testConfigureAppliesWrappedAndDeleteViewModels() {
        let sut = makeSut()
        let wrappedViewModel = WrappedViewSpy.ViewModel(text: "Coffee")
        let deleteViewModel = DeleteTableViewCellWrapper<WrappedViewSpy>.DeleteViewModel(
            id: "exp-1",
            title: makeDeleteLabelViewModel(),
            icon: nil,
            state: .idle,
            deleteCommand: .any
        )

        sut.configure(
            with: .init(
                wrappedViewModel: wrappedViewModel,
                deleteViewModel: deleteViewModel
            )
        )

        XCTAssertEqual(sut.wrappedView.viewModel, wrappedViewModel)
        XCTAssertEqual(sut.deleteViewModel, deleteViewModel)
    }
}

extension DeleteTableViewCellWrapperTests {
    func testTriggerDeleteIfPossibleExecutesCommandOnlyOnce() {
        let sut = makeSut()

        let expectation = expectation(description: "Delete command called")
        expectation.expectedFulfillmentCount = 1

        sut.configure(
            with: .init(
                wrappedViewModel: .init(text: "Coffee"),
                deleteViewModel: .init(
                    id: "exp-1",
                    deleteCommand: Command {
                        expectation.fulfill()
                    }
                )
            )
        )

        sut.triggerDeleteIfPossible()
        sut.triggerDeleteIfPossible()

        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(sut.deleteViewModel.state, .idle)
        XCTAssertGreaterThan(sut.currentRevealOffset, .zero)
    }

    func testSettleSwipePositionDoesNotExecuteDeleteCommandForFastSwipe() {
        let sut = makeSut()

        let expectation = expectation(description: "Delete command should not be called")
        expectation.isInverted = true

        sut.configure(
            with: .init(
                wrappedViewModel: .init(text: "Coffee"),
                deleteViewModel: .init(
                    id: "exp-1",
                    deleteCommand: Command {
                        expectation.fulfill()
                    }
                )
            )
        )

        sut.setRevealOffset(.greatestFiniteMagnitude, animated: false)
        let maxRevealOffset = sut.currentRevealOffset
        sut.setRevealOffset(maxRevealOffset * 2, animated: false, allowsRubberBand: true)

        sut.settleSwipePosition(horizontalVelocity: -2_000)

        wait(for: [expectation], timeout: 0.2)
        XCTAssertEqual(sut.currentRevealOffset, maxRevealOffset)
        XCTAssertEqual(sut.deleteViewModel.state, .idle)
    }
}

extension DeleteTableViewCellWrapperTests {
    func testSetRevealOffsetAppliesRubberBandBeyondMaximumRevealOffset() {
        let sut = makeSut()

        sut.setRevealOffset(.greatestFiniteMagnitude, animated: false)
        let maxRevealOffset = sut.currentRevealOffset

        sut.setRevealOffset(maxRevealOffset * 2, animated: false, allowsRubberBand: true)

        XCTAssertGreaterThan(sut.currentRevealOffset, maxRevealOffset)
        XCTAssertLessThan(sut.currentRevealOffset, maxRevealOffset * 2)
    }

    func testSettleSwipePositionClosesCellWhenRevealOffsetIsBelowThreshold() {
        let sut = makeSut()

        sut.setRevealOffset(1, animated: false)

        sut.settleSwipePosition(horizontalVelocity: .zero)

        XCTAssertEqual(sut.currentRevealOffset, .zero)
    }

    func testPrepareForReuseResetsSwipeState() {
        let sut = makeSut()

        sut.configure(
            with: .init(
                wrappedViewModel: .init(text: "Coffee"),
                deleteViewModel: .init(
                    id: "exp-1",
                    deleteCommand: .any
                )
            )
        )

        sut.triggerDeleteIfPossible()

        XCTAssertGreaterThan(sut.currentRevealOffset, .zero)
        XCTAssertEqual(sut.deleteViewModel.state, .idle)

        sut.prepareForReuse()

        XCTAssertEqual(sut.currentRevealOffset, .zero)
        XCTAssertEqual(sut.deleteViewModel.id, "")
        XCTAssertEqual(sut.deleteViewModel.state, .idle)
    }
}

private extension DeleteTableViewCellWrapperTests {
    func makeSut() -> DeleteTableViewCellWrapper<WrappedViewSpy> {
        let cell = DeleteTableViewCellWrapper<WrappedViewSpy>(
            style: .default,
            reuseIdentifier: nil
        )
        cell.frame = CGRect(x: .zero, y: .zero, width: 375, height: 64)
        cell.layoutIfNeeded()
        return cell
    }

    func makeDeleteLabelViewModel() -> Label.LabelViewModel {
        .init(
            text: L10n.categoryDelete,
            font: Typography.typographyBold10,
            textColor: .white,
            alignment: .center
        )
    }
}

@MainActor
private final class WrappedViewSpy: UIView, ConfigurableCellWrappedView {
    struct ViewModel: Equatable {
        let text: String
    }

    private(set) var viewModel: ViewModel = .init(text: "")

    func configure(with viewModel: ViewModel) {
        self.viewModel = viewModel
    }
}
