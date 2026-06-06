import Foundation

final class ConsoleAppLogSink: AppLogSinkProtocol, @unchecked Sendable {
    func exportLogFile(completion: @escaping (Result<URL, any Error>) -> Void) { }
    
    func write(_ entry: AppLogEntry) {
        guard let line = entry.encodedLine() else {
            return
        }

        print(line)
    }
}
