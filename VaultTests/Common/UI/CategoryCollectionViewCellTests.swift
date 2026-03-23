import XCTest
@testable import Vault

@MainActor
final class CategoryCollectionViewCellTests: XCTestCase {
    func testConfigureAppliesViewModel() {
        let sut = CategoryCollectionViewCell(frame: .init(x: 0, y: 0, width: 160, height: 130))
        let viewModel = CategoryCollectionViewCell.ViewModel(
            id: "1",
            iconText: "🍴",
            title: .init(text: "Food"),
            amount: .init(text: "$450.20"),
            iconBackgroundColor: .systemOrange,
            tapCommand: .any
        )

        sut.configure(with: viewModel)

        XCTAssertEqual(sut.viewModel, viewModel)
    }
}
