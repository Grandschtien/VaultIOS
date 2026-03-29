import XCTest
@testable import Vault

@MainActor
final class ExpenseCollectionViewCellTests: XCTestCase {
    func testConfigureAppliesViewModel() {
        let sut = ExpenseCollectionViewCell(frame: .init(x: 0, y: 0, width: 320, height: 66))
        let viewModel = ExpenseView.ViewModel(
            id: "1",
            iconText: "🍴",
            title: .init(text: "Coffee"),
            subtitle: .init(text: "Today, 08:30 AM"),
            amount: .init(text: "-$4.50", textColor: .systemRed, alignment: .right),
            iconBackgroundColor: .systemGray5,
            tapCommand: .any
        )

        sut.configure(with: viewModel)

        XCTAssertEqual(sut.viewModel, viewModel)
    }
}
