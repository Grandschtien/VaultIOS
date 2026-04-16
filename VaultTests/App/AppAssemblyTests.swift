import XCTest
import Swinject
@testable import Vault

final class AppAssemblyTests: XCTestCase {
    func testAssembleResolvesSharedToastPresenter() {
        let container = Container()
        let sut = AppAssembly()

        sut.assemble(container: container)

        let firstPresenter = container.resolve(ToastPresenting.self) as AnyObject?
        let secondPresenter = container.resolve(ToastPresenting.self) as AnyObject?

        XCTAssertNotNil(firstPresenter)
        XCTAssertTrue(firstPresenter === secondPresenter)
    }
}
