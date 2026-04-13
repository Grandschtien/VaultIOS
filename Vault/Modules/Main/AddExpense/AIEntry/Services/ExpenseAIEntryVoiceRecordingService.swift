import Foundation
import AVFoundation
import Speech

protocol ExpenseAIEntryVoiceRecordingServicing: Sendable {
    @MainActor
    func startRecording() async throws
    @MainActor
    func stopRecording() async throws -> String
}

enum ExpenseAIEntryVoiceRecordingServiceError: Error, Equatable {
    case speechPermissionDenied
    case microphonePermissionDenied
    case recognizerUnavailable
    case invalidState
}

struct ExpenseAIEntrySpeechRecognitionUpdate: Equatable {
    let transcript: String
    let isFinal: Bool
}

protocol ExpenseAIEntrySpeechRecognizerControlling: AnyObject {
    var isAvailable: Bool { get }

    func startRecognition(
        request: SFSpeechAudioBufferRecognitionRequest,
        onUpdate: @escaping @MainActor (ExpenseAIEntrySpeechRecognitionUpdate) -> Void
    ) -> ExpenseAIEntrySpeechRecognitionTaskControlling
}

protocol ExpenseAIEntrySpeechRecognitionTaskControlling: AnyObject {
    func finish() async throws
    func cancel()
}

protocol ExpenseAIEntryAudioSessionControlling: AnyObject {
    func setCategory(
        _ category: AVAudioSession.Category,
        mode: AVAudioSession.Mode,
        options: AVAudioSession.CategoryOptions
    ) throws
    func setActive(_ active: Bool, options: AVAudioSession.SetActiveOptions) throws
}

protocol ExpenseAIEntryAudioEngineControlling: AnyObject {
    func installTap(bufferHandler: @escaping (AVAudioPCMBuffer, AVAudioTime) -> Void)
    func removeTap()
    func prepare()
    func start() throws
    func stop()
}

final class ExpenseAIEntryVoiceRecordingService: ExpenseAIEntryVoiceRecordingServicing, @unchecked Sendable {
    private let userProfileStorageService: UserProfileStorageServiceProtocol
    private let speechAuthorizationProvider: @Sendable () async -> SFSpeechRecognizerAuthorizationStatus
    private let microphonePermissionProvider: @Sendable () async -> Bool
    private let speechRecognizerFactory: (Locale) -> ExpenseAIEntrySpeechRecognizerControlling?
    private let audioSession: ExpenseAIEntryAudioSessionControlling
    private let audioEngineFactory: () -> ExpenseAIEntryAudioEngineControlling

    private var audioEngine: ExpenseAIEntryAudioEngineControlling?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: ExpenseAIEntrySpeechRecognitionTaskControlling?
    private var latestTranscription: String = ""

    init(
        userProfileStorageService: UserProfileStorageServiceProtocol,
        speechAuthorizationProvider: @escaping @Sendable () async -> SFSpeechRecognizerAuthorizationStatus = ExpenseAIEntryVoiceRecordingService.requestSpeechAuthorization,
        microphonePermissionProvider: @escaping @Sendable () async -> Bool = ExpenseAIEntryVoiceRecordingService.requestMicrophonePermission,
        speechRecognizerFactory: @escaping (Locale) -> ExpenseAIEntrySpeechRecognizerControlling? = {
            guard let recognizer = SFSpeechRecognizer(locale: $0) else {
                return nil
            }

            return ExpenseAIEntrySpeechRecognizerController(recognizer: recognizer)
        },
        audioSession: ExpenseAIEntryAudioSessionControlling = ExpenseAIEntryAudioSessionController(
            session: .sharedInstance()
        ),
        audioEngineFactory: @escaping () -> ExpenseAIEntryAudioEngineControlling = {
            ExpenseAIEntryAudioEngineController(engine: AVAudioEngine())
        }
    ) {
        self.userProfileStorageService = userProfileStorageService
        self.speechAuthorizationProvider = speechAuthorizationProvider
        self.microphonePermissionProvider = microphonePermissionProvider
        self.speechRecognizerFactory = speechRecognizerFactory
        self.audioSession = audioSession
        self.audioEngineFactory = audioEngineFactory
    }

    @MainActor
    func startRecording() async throws {
        guard recognitionTask == nil else {
            throw ExpenseAIEntryVoiceRecordingServiceError.invalidState
        }

        guard await speechAuthorizationProvider() == .authorized else {
            throw ExpenseAIEntryVoiceRecordingServiceError.speechPermissionDenied
        }

        guard await microphonePermissionProvider() else {
            throw ExpenseAIEntryVoiceRecordingServiceError.microphonePermissionDenied
        }

        guard let recognizer = speechRecognizerFactory(resolveLocale()),
              recognizer.isAvailable else {
            throw ExpenseAIEntryVoiceRecordingServiceError.recognizerUnavailable
        }

        let audioEngine = audioEngineFactory()
        let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest.shouldReportPartialResults = true
        latestTranscription = ""

        do {
            try audioSession.setCategory(
                .record,
                mode: .measurement,
                options: [.duckOthers]
            )
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

            audioEngine.installTap { [weak recognitionRequest] buffer, _ in
                recognitionRequest?.append(buffer)
            }

            let recognitionTask = recognizer.startRecognition(
                request: recognitionRequest
            ) { [weak self] update in
                self?.latestTranscription = update.transcript
            }

            audioEngine.prepare()
            try audioEngine.start()

            self.audioEngine = audioEngine
            self.recognitionRequest = recognitionRequest
            self.recognitionTask = recognitionTask
        } catch {
            audioEngine.removeTap()
            audioEngine.stop()
            recognitionRequest.endAudio()
            try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            throw error
        }
    }

    @MainActor
    func stopRecording() async throws -> String {
        guard let recognitionTask,
              let recognitionRequest else {
            throw ExpenseAIEntryVoiceRecordingServiceError.invalidState
        }

        audioEngine?.removeTap()
        audioEngine?.stop()
        recognitionRequest.endAudio()

        do {
            try await recognitionTask.finish()
            let transcript = latestTranscription.trimmingCharacters(in: .whitespacesAndNewlines)
            cleanup(cancelTask: false)
            return transcript
        } catch {
            cleanup(cancelTask: true)
            throw error
        }
    }
}

private extension ExpenseAIEntryVoiceRecordingService {
    func resolveLocale() -> Locale {
        guard let language = userProfileStorageService.loadProfile()?.language,
              !language.isEmpty else {
            return .current
        }

        return Locale(identifier: language)
    }

    func cleanup(cancelTask: Bool) {
        if cancelTask {
            recognitionTask?.cancel()
        }

        audioEngine?.removeTap()
        audioEngine?.stop()
        recognitionRequest?.endAudio()
        try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)

        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil
    }

    static func requestSpeechAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
        }
    }

    static func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            if #available(iOS 17.0, *) {
                AVAudioApplication.requestRecordPermission {
                    continuation.resume(returning: $0)
                }
            } else {
                AVAudioSession.sharedInstance().requestRecordPermission {
                    continuation.resume(returning: $0)
                }
            }
        }
    }
}

private final class ExpenseAIEntrySpeechRecognizerController: ExpenseAIEntrySpeechRecognizerControlling {
    private let recognizer: SFSpeechRecognizer

    var isAvailable: Bool {
        recognizer.isAvailable
    }

    init(recognizer: SFSpeechRecognizer) {
        self.recognizer = recognizer
    }

    func startRecognition(
        request: SFSpeechAudioBufferRecognitionRequest,
        onUpdate: @escaping @MainActor (ExpenseAIEntrySpeechRecognitionUpdate) -> Void
    ) -> ExpenseAIEntrySpeechRecognitionTaskControlling {
        let controller = ExpenseAIEntrySpeechRecognitionTaskController()
        let task = recognizer.recognitionTask(with: request) { result, error in
            if let result {
                let update = ExpenseAIEntrySpeechRecognitionUpdate(
                    transcript: result.bestTranscription.formattedString,
                    isFinal: result.isFinal
                )

                Task { @MainActor in
                    onUpdate(update)
                }
                controller.handle(update: update)
            }

            if let error {
                controller.handle(error: error)
            }
        }

        controller.attach(task)
        return controller
    }
}

private final class ExpenseAIEntrySpeechRecognitionTaskController: ExpenseAIEntrySpeechRecognitionTaskControlling {
    private var task: SFSpeechRecognitionTask?
    private var result: Result<Void, Error>?
    private var continuation: CheckedContinuation<Void, Error>?

    func attach(_ task: SFSpeechRecognitionTask) {
        self.task = task
    }

    func handle(update: ExpenseAIEntrySpeechRecognitionUpdate) {
        guard update.isFinal else {
            return
        }

        complete(with: .success(()))
    }

    func handle(error: Error) {
        complete(with: .failure(error))
    }

    func finish() async throws {
        if let result {
            return try result.get()
        }

        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
        }
    }

    func cancel() {
        task?.cancel()
        complete(with: .success(()))
    }
}

private extension ExpenseAIEntrySpeechRecognitionTaskController {
    func complete(with result: Result<Void, Error>) {
        guard self.result == nil else {
            return
        }

        self.result = result
        continuation?.resume(with: result)
        continuation = nil
    }
}

private final class ExpenseAIEntryAudioSessionController: ExpenseAIEntryAudioSessionControlling {
    private let session: AVAudioSession

    init(session: AVAudioSession) {
        self.session = session
    }

    func setCategory(
        _ category: AVAudioSession.Category,
        mode: AVAudioSession.Mode,
        options: AVAudioSession.CategoryOptions
    ) throws {
        try session.setCategory(category, mode: mode, options: options)
    }

    func setActive(_ active: Bool, options: AVAudioSession.SetActiveOptions) throws {
        try session.setActive(active, options: options)
    }
}

private final class ExpenseAIEntryAudioEngineController: ExpenseAIEntryAudioEngineControlling {
    private enum Constants {
        static let inputBus: AVAudioNodeBus = 0
        static let bufferSize: AVAudioFrameCount = 1024
    }

    private let engine: AVAudioEngine

    init(engine: AVAudioEngine) {
        self.engine = engine
    }

    func installTap(bufferHandler: @escaping (AVAudioPCMBuffer, AVAudioTime) -> Void) {
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: Constants.inputBus)

        inputNode.removeTap(onBus: Constants.inputBus)
        inputNode.installTap(
            onBus: Constants.inputBus,
            bufferSize: Constants.bufferSize,
            format: format,
            block: bufferHandler
        )
    }

    func removeTap() {
        engine.inputNode.removeTap(onBus: Constants.inputBus)
    }

    func prepare() {
        engine.prepare()
    }

    func start() throws {
        try engine.start()
    }

    func stop() {
        engine.stop()
    }
}
