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
        XCTAssertTrue(sut.hasTriggeredDelete)
    }
}

extension DeleteTableViewCellWrapperTests {
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
        XCTAssertTrue(sut.hasTriggeredDelete)

        sut.prepareForReuse()

        XCTAssertEqual(sut.currentRevealOffset, .zero)
        XCTAssertFalse(sut.hasTriggeredDelete)
        XCTAssertEqual(sut.deleteViewModel.id, "")
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
