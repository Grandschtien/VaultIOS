import Foundation

final class RotatingFileAppLogSink: AppLogSinkProtocol, @unchecked Sendable {
    private enum Constants {
        static let filePrefix = "app-log"
        static let fileExtension = "ndjson"
    }

    private let fileManager: FileManager
    private let baseDirectoryURL: URL
    private let maximumFileSizeInBytes: Int
    private let maximumFileCount: Int
    private let queue: DispatchQueue
    private let writeExecutionObserver: (@Sendable (Bool) -> Void)?

    init(
        fileManager: FileManager = .default,
        baseDirectoryURL: URL? = nil,
        maximumFileSizeInBytes: Int = 1_048_576,
        maximumFileCount: Int = 5,
        queue: DispatchQueue = DispatchQueue(label: "Vault.AppLogs.FileSink"),
        writeExecutionObserver: (@Sendable (Bool) -> Void)? = nil
    ) {
        self.fileManager = fileManager
        self.maximumFileSizeInBytes = maximumFileSizeInBytes
        self.maximumFileCount = maximumFileCount
        self.queue = queue
        self.writeExecutionObserver = writeExecutionObserver

        if let baseDirectoryURL {
            self.baseDirectoryURL = baseDirectoryURL
        } else {
            let applicationSupportURL = fileManager.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first ?? fileManager.temporaryDirectory

            self.baseDirectoryURL = applicationSupportURL
                .appendingPathComponent("Logs", isDirectory: true)
        }
    }

    func write(_ entry: AppLogEntry) {
        guard let line = entry.encodedLine(), let data = (line + "\n").data(using: .utf8) else {
            return
        }

        queue.async { [weak self] in
            guard let self else {
                return
            }

            self.writeExecutionObserver?(Thread.isMainThread)
            self.ensureDirectoryExists()
            self.rotateIfNeeded(forAdditionalBytes: data.count)
            self.append(data, to: self.activeFileURL())
        }
    }
}

private extension RotatingFileAppLogSink {
    func ensureDirectoryExists() {
        guard !fileManager.fileExists(atPath: baseDirectoryURL.path) else {
            return
        }

        try? fileManager.createDirectory(
            at: baseDirectoryURL,
            withIntermediateDirectories: true
        )
    }

    func rotateIfNeeded(forAdditionalBytes additionalBytes: Int) {
        let activeURL = activeFileURL()
        let currentSize = (try? fileManager.attributesOfItem(atPath: activeURL.path)[.size] as? NSNumber)?
            .intValue ?? 0

        guard currentSize + additionalBytes > maximumFileSizeInBytes else {
            return
        }

        removeOldestFileIfNeeded()

        if maximumFileCount > 1 {
            for index in stride(from: maximumFileCount - 2, through: 0, by: -1) {
                let sourceURL = fileURL(for: index)
                let destinationURL = fileURL(for: index + 1)

                guard fileManager.fileExists(atPath: sourceURL.path) else {
                    continue
                }

                try? fileManager.removeItem(at: destinationURL)
                try? fileManager.moveItem(at: sourceURL, to: destinationURL)
            }
        } else {
            try? fileManager.removeItem(at: activeURL)
        }
    }

    func removeOldestFileIfNeeded() {
        guard maximumFileCount > 0 else {
            return
        }

        let oldestFileURL = fileURL(for: maximumFileCount - 1)
        guard fileManager.fileExists(atPath: oldestFileURL.path) else {
            return
        }

        try? fileManager.removeItem(at: oldestFileURL)
    }

    func append(_ data: Data, to url: URL) {
        if !fileManager.fileExists(atPath: url.path) {
            fileManager.createFile(atPath: url.path, contents: nil)
        }

        guard let handle = try? FileHandle(forWritingTo: url) else {
            return
        }

        do {
            try handle.seekToEnd()
            try handle.write(contentsOf: data)
            try handle.close()
        } catch {
            try? handle.close()
        }
    }

    func activeFileURL() -> URL {
        fileURL(for: 0)
    }

    func fileURL(for index: Int) -> URL {
        baseDirectoryURL.appendingPathComponent(
            "\(Constants.filePrefix)-\(index).\(Constants.fileExtension)"
        )
    }
}

extension RotatingFileAppLogSink {
    enum ExportError: Error {
        case noLogFiles
        case failedToCreateExportFile
    }

    func exportLogFile(completion: @escaping (Result<URL, Error>) -> Void) {
        queue.async { [weak self] in
            guard let self else {
                return
            }

            do {
                self.ensureDirectoryExists()

                let exportURL = try self.makeExportLogFile()

                DispatchQueue.main.async {
                    completion(.success(exportURL))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
}

private extension RotatingFileAppLogSink {
    func makeExportLogFile() throws -> URL {
        let logFileURLs = existingLogFileURLsInChronologicalOrder()

        guard !logFileURLs.isEmpty else {
            throw ExportError.noLogFiles
        }

        let exportFileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(exportFileName())

        if fileManager.fileExists(atPath: exportFileURL.path) {
            try? fileManager.removeItem(at: exportFileURL)
        }

        let created = fileManager.createFile(
            atPath: exportFileURL.path,
            contents: nil
        )

        guard created else {
            throw ExportError.failedToCreateExportFile
        }

        let outputHandle = try FileHandle(forWritingTo: exportFileURL)

        do {
            for logFileURL in logFileURLs {
                let data = try Data(contentsOf: logFileURL)
                try outputHandle.write(contentsOf: data)
            }

            try outputHandle.close()
        } catch {
            try? outputHandle.close()
            throw error
        }

        return exportFileURL
    }

    func existingLogFileURLsInChronologicalOrder() -> [URL] {
        guard maximumFileCount > 0 else {
            return []
        }

        return stride(from: maximumFileCount - 1, through: 0, by: -1)
            .map { fileURL(for: $0) }
            .filter { fileManager.fileExists(atPath: $0.path) }
    }

    func exportFileName() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"

        return "vault-logs-\(formatter.string(from: Date()))Z.ndjson"
    }
}
