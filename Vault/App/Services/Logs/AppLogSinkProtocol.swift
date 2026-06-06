import Foundation

protocol AppLogSinkProtocol: Sendable {
    func write(_ entry: AppLogEntry)
    func exportLogFile(completion: @escaping (Result<URL, Error>) -> Void)
}
