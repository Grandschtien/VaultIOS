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

    func testAssembleResolvesSharedAnalyticsCoreManager() {
        let container = Container()
        let sut = AppAssembly()

        sut.assemble(container: container)

        let firstManager = container.resolve(AnalyticsCoreManaging.self) as AnyObject?
        let secondManager = container.resolve(AnalyticsCoreManaging.self) as AnyObject?

        XCTAssertNotNil(firstManager)
        XCTAssertTrue(firstManager === secondManager)
    }

    func testAnalyticsAssemblyResolvesSharedAnalyticsCoreManager() {
        let container = Container()
        let sut = AnalyticsAssembly()

        sut.assemble(container: container)

        let firstManager = container.resolve(AnalyticsCoreManaging.self) as AnyObject?
        let secondManager = container.resolve(AnalyticsCoreManaging.self) as AnyObject?

        XCTAssertNotNil(firstManager)
        XCTAssertTrue(firstManager === secondManager)
    }
}
