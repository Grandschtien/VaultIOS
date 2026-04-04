import XCTest
@testable import Vault

final class ExpenseAmountInputFilterTests: XCTestCase {
    func testAllowsDigits() {
        let result = ExpenseAmountInputFilter.shouldChange(
            currentText: "12",
            range: NSRange(location: 2, length: 0),
            replacementString: "3"
        )

        XCTAssertTrue(result)
    }

    func testAllowsSingleDecimalSeparator() {
        let result = ExpenseAmountInputFilter.shouldChange(
            currentText: "12",
            range: NSRange(location: 2, length: 0),
            replacementString: "."
        )

        XCTAssertTrue(result)
    }

    func testRejectsLetters() {
        let result = ExpenseAmountInputFilter.shouldChange(
            currentText: "12",
            range: NSRange(location: 2, length: 0),
            replacementString: "a"
        )

        XCTAssertFalse(result)
    }

    func testRejectsSpecialSymbols() {
        let result = ExpenseAmountInputFilter.shouldChange(
            currentText: "12",
            range: NSRange(location: 2, length: 0),
            replacementString: "$"
        )

        XCTAssertFalse(result)
    }

    func testRejectsSecondDecimalSeparator() {
        let result = ExpenseAmountInputFilter.shouldChange(
            currentText: "12.3",
            range: NSRange(location: 4, length: 0),
            replacementString: ","
        )

        XCTAssertFalse(result)
    }

    func testAllowsReplacingDecimalSeparator() {
        let result = ExpenseAmountInputFilter.shouldChange(
            currentText: "12.3",
            range: NSRange(location: 2, length: 1),
            replacementString: ","
        )

        XCTAssertTrue(result)
    }
}
