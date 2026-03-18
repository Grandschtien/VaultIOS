import XCTest
@testable import Vault

final class RegistrationStorageTests: XCTestCase {
    private var sut: RegistrationStorage!

    override func setUp() {
        super.setUp()
        sut = RegistrationStorage()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }
}

extension RegistrationStorageTests {
    func testLoadDraftByDefaultReturnsEmptyValues() async {
        let draft = await sut.loadDraft()

        XCTAssertEqual(draft.email, "")
        XCTAssertEqual(draft.password, "")
        XCTAssertEqual(draft.confirmPassword, "")
        XCTAssertEqual(draft.name, "")
        XCTAssertNil(draft.currencyCode)
    }
}

extension RegistrationStorageTests {
    func testSaveDraftPersistsAllValues() async {
        let draft = RegistrationDraft(
            email: "name@example.com",
            password: "12345678",
            confirmPassword: "12345678",
            name: "Egor",
            currencyCode: "USD"
        )

        await sut.saveDraft(draft)

        let storedDraft = await sut.loadDraft()
        XCTAssertEqual(storedDraft, draft)
    }
}

extension RegistrationStorageTests {
    func testClearResetsDraftToDefault() async {
        await sut.saveDraft(
            RegistrationDraft(
                email: "name@example.com",
                password: "12345678",
                confirmPassword: "12345678",
                name: "Egor",
                currencyCode: "USD"
            )
        )

        await sut.clear()

        let draft = await sut.loadDraft()
        XCTAssertEqual(draft, .init())
    }
}
