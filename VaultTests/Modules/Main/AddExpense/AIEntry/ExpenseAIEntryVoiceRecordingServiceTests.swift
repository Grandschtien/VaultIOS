import XCTest
import Speech
import AVFoundation
@testable import Vault

@MainActor
final class ExpenseAIEntryVoiceRecordingServiceTests: XCTestCase {
    func testStartRecordingFailsWhenSpeechPermissionDenied() async {
        let sut = makeSUT(speechAuthorizationStatus: .denied)

        do {
            try await sut.startRecording()
            XCTFail("Expected speech permission error")
        } catch let error as ExpenseAIEntryVoiceRecordingServiceError {
            XCTAssertEqual(error, .speechPermissionDenied)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testStartRecordingFailsWhenMicrophonePermissionDenied() async {
        let sut = makeSUT(microphonePermissionGranted: false)

        do {
            try await sut.startRecording()
            XCTFail("Expected microphone permission error")
        } catch let error as ExpenseAIEntryVoiceRecordingServiceError {
            XCTAssertEqual(error, .microphonePermissionDenied)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testStartRecordingFailsWhenRecognizerUnavailable() async {
        let sut = makeSUT(recognizer: SpeechRecognizerSpy(isAvailable: false))

        do {
            try await sut.startRecording()
            XCTFail("Expected recognizer unavailable error")
        } catch let error as ExpenseAIEntryVoiceRecordingServiceError {
            XCTAssertEqual(error, .recognizerUnavailable)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testStopRecordingReturnsLatestTranscript() async throws {
        let recognizer = SpeechRecognizerSpy(
            updatesOnFinish: [
                .init(transcript: "Coffee 5", isFinal: false),
                .init(transcript: "Coffee 5 at Starbucks", isFinal: true)
            ]
        )
        let audioSession = AudioSessionSpy()
        let audioEngine = AudioEngineSpy()
        let sut = makeSUT(
            profile: .init(
                userId: "1",
                email: "test@example.com",
                name: "Test",
                currency: "USD",
                language: "en-US"
            ),
            recognizer: recognizer,
            audioSession: audioSession,
            audioEngine: audioEngine
        )

        try await sut.startRecording()
        let transcript = try await sut.stopRecording()

        XCTAssertEqual(transcript, "Coffee 5 at Starbucks")
        XCTAssertEqual(recognizer.capturedLocale?.identifier, "en-US")
        XCTAssertEqual(audioSession.setActiveCalls, [true, false])
        XCTAssertEqual(audioEngine.startCallsCount, 1)
        XCTAssertEqual(audioEngine.stopCallsCount, 1)
    }
}

@MainActor
private extension ExpenseAIEntryVoiceRecordingServiceTests {
    func makeSUT(
        profile: UserProfileDefaults? = nil,
        speechAuthorizationStatus: SFSpeechRecognizerAuthorizationStatus = .authorized,
        microphonePermissionGranted: Bool = true,
        recognizer: SpeechRecognizerSpy? = nil,
        audioSession: AudioSessionSpy? = nil,
        audioEngine: AudioEngineSpy? = nil
    ) -> ExpenseAIEntryVoiceRecordingService {
        let resolvedRecognizer = recognizer ?? SpeechRecognizerSpy()
        let resolvedAudioSession = audioSession ?? AudioSessionSpy()
        let resolvedAudioEngine = audioEngine ?? AudioEngineSpy()

        return ExpenseAIEntryVoiceRecordingService(
            userProfileStorageService: UserProfileStorageSpy(profile: profile),
            speechAuthorizationProvider: { speechAuthorizationStatus },
            microphonePermissionProvider: { microphonePermissionGranted },
            speechRecognizerFactory: {
                resolvedRecognizer.capturedLocale = $0
                return resolvedRecognizer
            },
            audioSession: resolvedAudioSession,
            audioEngineFactory: { resolvedAudioEngine }
        )
    }
}

private final class SpeechRecognizerSpy: ExpenseAIEntrySpeechRecognizerControlling {
    var isAvailable: Bool
    var updatesOnFinish: [ExpenseAIEntrySpeechRecognitionUpdate]
    var finishError: Error?
    var capturedLocale: Locale?

    init(
        isAvailable: Bool = true,
        updatesOnFinish: [ExpenseAIEntrySpeechRecognitionUpdate] = [],
        finishError: Error? = nil
    ) {
        self.isAvailable = isAvailable
        self.updatesOnFinish = updatesOnFinish
        self.finishError = finishError
    }

    func startRecognition(
        request: SFSpeechAudioBufferRecognitionRequest,
        onUpdate: @escaping @MainActor (ExpenseAIEntrySpeechRecognitionUpdate) -> Void
    ) -> ExpenseAIEntrySpeechRecognitionTaskControlling {
        SpeechRecognitionTaskSpy(
            updatesOnFinish: updatesOnFinish,
            finishError: finishError,
            onUpdate: onUpdate
        )
    }
}

private final class SpeechRecognitionTaskSpy: ExpenseAIEntrySpeechRecognitionTaskControlling {
    private let updatesOnFinish: [ExpenseAIEntrySpeechRecognitionUpdate]
    private let finishError: Error?
    private let onUpdate: @MainActor (ExpenseAIEntrySpeechRecognitionUpdate) -> Void

    init(
        updatesOnFinish: [ExpenseAIEntrySpeechRecognitionUpdate],
        finishError: Error?,
        onUpdate: @escaping @MainActor (ExpenseAIEntrySpeechRecognitionUpdate) -> Void
    ) {
        self.updatesOnFinish = updatesOnFinish
        self.finishError = finishError
        self.onUpdate = onUpdate
    }

    func finish() async throws {
        for update in updatesOnFinish {
            await MainActor.run {
                onUpdate(update)
            }
        }

        if let finishError {
            throw finishError
        }
    }

    func cancel() {}
}

private final class AudioSessionSpy: ExpenseAIEntryAudioSessionControlling {
    private(set) var setActiveCalls: [Bool] = []

    func setCategory(
        _ category: AVAudioSession.Category,
        mode: AVAudioSession.Mode,
        options: AVAudioSession.CategoryOptions
    ) throws {}

    func setActive(_ active: Bool, options: AVAudioSession.SetActiveOptions) throws {
        setActiveCalls.append(active)
    }
}

private final class AudioEngineSpy: ExpenseAIEntryAudioEngineControlling {
    private(set) var startCallsCount = 0
    private(set) var stopCallsCount = 0

    func installTap(bufferHandler: @escaping (AVAudioPCMBuffer, AVAudioTime) -> Void) {}

    func removeTap() {}

    func prepare() {}

    func start() throws {
        startCallsCount += 1
    }

    func stop() {
        stopCallsCount += 1
    }
}

private final class UserProfileStorageSpy: UserProfileStorageServiceProtocol, @unchecked Sendable {
    private let profile: UserProfileDefaults?

    init(profile: UserProfileDefaults? = nil) {
        self.profile = profile
    }

    func saveProfile(_ profile: UserProfileDefaults) {}

    func loadProfile() -> UserProfileDefaults? {
        profile
    }

    func clearProfile() {}
}
