import XCTest
@testable import Vylok

final class NotificationCenterServiceTests: XCTestCase {
    private var notificationCenter: NotificationCenter!

    override func setUp() {
        super.setUp()
        notificationCenter = NotificationCenter()
    }

    override func tearDown() {
        notificationCenter = nil
        super.tearDown()
    }
}

// MARK: - addObserver

extension NotificationCenterServiceTests {
    func testAddObserverWhenNotificationIsPostedCallsHandler() async {
        // Arrange
        let sut = NotificationCenterService(notificationCenter: notificationCenter)
        let handled = expectation(description: "handler")
        _ = sut.addObserver(forName: .authSessionDidLogout) {
            handled.fulfill()
        }

        // Act
        notificationCenter.post(name: .authSessionDidLogout, object: nil)

        // Assert
        await fulfillment(of: [handled], timeout: 1)
    }
}

// MARK: - removeObserver

extension NotificationCenterServiceTests {
    func testRemoveObserverStopsCallingHandler() async {
        // Arrange
        let sut = NotificationCenterService(notificationCenter: notificationCenter)
        let handled = expectation(description: "handler")
        handled.isInverted = true
        let observer = sut.addObserver(forName: .authSessionDidLogout) {
            handled.fulfill()
        }
        sut.removeObserver(observer)

        // Act
        notificationCenter.post(name: .authSessionDidLogout, object: nil)

        // Assert
        await fulfillment(of: [handled], timeout: 0.2)
    }
}
