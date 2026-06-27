import XCTest
@testable import Vylok

final class RotatingFileAppLogSinkTests: XCTestCase {
    func testWritePersistsEntryOffMainThread() async throws {
        let directoryURL = makeDirectoryURL()
        let writeExpectation = expectation(description: "write observer")
        var didRunOnMainThread = true
        let sut = RotatingFileAppLogSink(
            baseDirectoryURL: directoryURL,
            queue: DispatchQueue(label: "RotatingFileAppLogSinkTests.write"),
            writeExecutionObserver: { isMainThread in
                didRunOnMainThread = isMainThread
                writeExpectation.fulfill()
            }
        )

        sut.write(makeEntry(name: "first", payload: ["message": .string("hello")]))

        await fulfillment(of: [writeExpectation], timeout: 1.0)
        let activeFileURL = directoryURL.appendingPathComponent("app-log-0.ndjson")
        try await waitForFile(at: activeFileURL)

        let contents = try String(contentsOf: activeFileURL, encoding: .utf8)
        XCTAssertFalse(didRunOnMainThread)
        XCTAssertTrue(contents.contains(#""name":"first""#))
    }

    func testWriteRotatesFilesWhenMaximumSizeIsExceeded() async throws {
        let directoryURL = makeDirectoryURL()
        let firstWriteExpectation = expectation(description: "first write")
        firstWriteExpectation.expectedFulfillmentCount = 1
        let secondWriteExpectation = expectation(description: "second write")
        secondWriteExpectation.expectedFulfillmentCount = 1
        var observerCalls = 0
        let sut = RotatingFileAppLogSink(
            baseDirectoryURL: directoryURL,
            maximumFileSizeInBytes: 180,
            maximumFileCount: 2,
            queue: DispatchQueue(label: "RotatingFileAppLogSinkTests.rotate"),
            writeExecutionObserver: { _ in
                observerCalls += 1
                if observerCalls == 1 {
                    firstWriteExpectation.fulfill()
                } else if observerCalls == 2 {
                    secondWriteExpectation.fulfill()
                }
            }
        )

        sut.write(makeEntry(name: "first", payload: ["message": .string(String(repeating: "a", count: 80))]))
        await fulfillment(of: [firstWriteExpectation], timeout: 1.0)

        sut.write(makeEntry(name: "second", payload: ["message": .string(String(repeating: "b", count: 80))]))
        await fulfillment(of: [secondWriteExpectation], timeout: 1.0)

        let activeFileURL = directoryURL.appendingPathComponent("app-log-0.ndjson")
        let rotatedFileURL = directoryURL.appendingPathComponent("app-log-1.ndjson")
        try await waitForFile(at: activeFileURL)
        try await waitForFile(at: rotatedFileURL)

        let activeContents = try String(contentsOf: activeFileURL, encoding: .utf8)
        let rotatedContents = try String(contentsOf: rotatedFileURL, encoding: .utf8)

        XCTAssertTrue(activeContents.contains(#""name":"second""#))
        XCTAssertTrue(rotatedContents.contains(#""name":"first""#))
    }
}

private extension RotatingFileAppLogSinkTests {
    func makeDirectoryURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString.lowercased(), isDirectory: true)
    }

    func makeEntry(name: String, payload: [String: AppLogValue]) -> AppLogEntry {
        AppLogEntry(
            timestamp_utc: "2026-06-06T00:00:00.000Z",
            session_id: "session-test",
            category: .app,
            name: name,
            source: "RotatingFileAppLogSinkTests",
            payload: payload,
            request_id: nil,
            subscription_attempt_id: nil
        )
    }

    func waitForFile(at url: URL) async throws {
        for _ in 0..<100 {
            if FileManager.default.fileExists(atPath: url.path),
               let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
               let size = attributes[.size] as? NSNumber,
               size.intValue > 0 {
                return
            }

            try await Task.sleep(nanoseconds: 10_000_000)
        }

        XCTFail("Expected file at \(url.path)")
    }
}
