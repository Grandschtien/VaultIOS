import XCTest
import UIKit
@testable import Vault

@MainActor
final class CategoryEditorPresenterTests: XCTestCase {
    private var sut: CategoryEditorPresenter!
    private var colorProvider: CategoryColorProvider!

    override func setUp() {
        super.setUp()
        colorProvider = CategoryColorProvider()
        sut = CategoryEditorPresenter(
            viewModel: .init(),
            presetProvider: CategoryEditorPresetProvider(),
            colorProvider: colorProvider
        )
    }

    override func tearDown() {
        sut = nil
        colorProvider = nil
        super.tearDown()
    }

    func testPresentFetchedDataPinsPrefilledCustomEmojiFirst() {
        sut.presentFetchedData(
            .init(
                mode: .edit(id: "food"),
                loadingState: .loaded,
                draft: .init(
                    name: "Food",
                    emoji: "🎁",
                    colorHex: "#A0E7E5"
                ),
                prefilledCustomEmoji: "🎁",
                isDeleteVisible: true
            )
        )

        guard case let .loaded(content) = sut.viewModel.state else {
            return XCTFail("Expected loaded state")
        }

        XCTAssertEqual(content.emojiItems.count, 8)
        XCTAssertEqual(content.emojiItems.first?.content, .emoji("🎁"))
        XCTAssertEqual(content.emojiItems.last?.content, .symbol("plus"))
    }

    func testPresentFetchedDataShowsNewCustomEmojiInsidePlusSlot() {
        sut.presentFetchedData(
            .init(
                mode: .edit(id: "food"),
                loadingState: .loaded,
                draft: .init(
                    name: "Food",
                    emoji: "🎁",
                    colorHex: "#A0E7E5"
                ),
                prefilledCustomEmoji: "🧾",
                isDeleteVisible: true
            )
        )

        guard case let .loaded(content) = sut.viewModel.state else {
            return XCTFail("Expected loaded state")
        }

        XCTAssertEqual(content.emojiItems.first?.content, .emoji("🍽️"))
        XCTAssertEqual(content.emojiItems.last?.content, .emoji("🎁"))
        XCTAssertEqual(content.emojiItems.last?.borderWidth, 2)
    }

    func testPresentFetchedDataPinsPrefilledCustomColorFirst() {
        sut.presentFetchedData(
            .init(
                mode: .edit(id: "food"),
                loadingState: .loaded,
                draft: .init(
                    name: "Food",
                    emoji: "🍔",
                    colorHex: "#123456"
                ),
                prefilledCustomColorHex: "#123456",
                isDeleteVisible: true
            )
        )

        guard case let .loaded(content) = sut.viewModel.state else {
            return XCTFail("Expected loaded state")
        }

        XCTAssertEqual(content.colorItems.count, 8)
        XCTAssertEqual(colorProvider.hexString(from: content.colorItems[0].backgroundColor), "#123456")
        XCTAssertEqual(content.colorItems.last?.content, .symbol("plus"))
    }

    func testPresentFetchedDataShowsNewCustomColorInsidePlusSlot() {
        sut.presentFetchedData(
            .init(
                mode: .edit(id: "food"),
                loadingState: .loaded,
                draft: .init(
                    name: "Food",
                    emoji: "🍔",
                    colorHex: "#123456"
                ),
                prefilledCustomColorHex: "#FFE6A7",
                isDeleteVisible: true
            )
        )

        guard case let .loaded(content) = sut.viewModel.state else {
            return XCTFail("Expected loaded state")
        }

        XCTAssertEqual(
            colorProvider.hexString(from: content.colorItems[0].backgroundColor),
            "#FFE6A7"
        )
        XCTAssertEqual(
            colorProvider.hexString(from: content.colorItems.last?.backgroundColor ?? .clear),
            "#123456"
        )
        XCTAssertEqual(content.colorItems.last?.borderWidth, 2)
    }
}
