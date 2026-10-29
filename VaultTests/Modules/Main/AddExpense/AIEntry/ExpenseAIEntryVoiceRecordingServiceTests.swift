import XCTest
import Speech
import AVFoundation
@testable import Vylok

@MainActor
final class ExpenseAIEntryVoiceRecordingServiceTests: XCTestCase {
    private var userProfileStorageService: UserProfileStorageServiceProtocolMock!
    private var recognizer: ExpenseAIEntrySpeechRecognizerControllingMock!
    private var recognitionTask: ExpenseAIEntrySpeechRecognitionTaskControllingMock!
    private var audioSession: ExpenseAIEntryAudioSessionControllingMock!
    private var audioEngine: ExpenseAIEntryAudioEngineControllingMock!

    override func setUp() {
        super.setUp()
        userProfileStorageService = UserProfileStorageServiceProtocolMock()
        recognizer = ExpenseAIEntrySpeechRecognizerControllingMock()
        recognitionTask = ExpenseAIEntrySpeechRecognitionTaskControllingMock()
        audioSession = ExpenseAIEntryAudioSessionControllingMock()
        audioEngine = ExpenseAIEntryAudioEngineControllingMock()
    }

    override func tearDown() {
        audioEngine = nil
        audioSession = nil
        recognitionTask = nil
        recognizer = nil
        userProfileStorageService = nil
        super.tearDown()
    }
}

// MARK: - startRecording

extension ExpenseAIEntryVoiceRecordingServiceTests {
    func testStartRecordingWhenSpeechPermissionDeniedThrowsSpeechPermissionError() async {
        // Arrange
        let sut = ExpenseAIEntryVoiceRecordingService(
            userProfileStorageService: userProfileStorageService,
            speechAuthorizationProvider: { .denied },
            microphonePermissionProvider: { true },
            speechRecognizerFactory: { [recognizer] _ in recognizer },
            audioSession: audioSession,
            audioEngineFactory: { [audioEngine] in audioEngine! }
        )

        // Act
        let result = await Result { try await sut.startRecording() }

        // Assert
        XCTAssertEqual(result.failure as? ExpenseAIEntryVoiceRecordingServiceError, .speechPermissionDenied)
    }

    func testStartRecordingWhenMicrophonePermissionDeniedThrowsMicrophonePermissionError() async {
        // Arrange
        let sut = ExpenseAIEntryVoiceRecordingService(
            userProfileStorageService: userProfileStorageService,
            speechAuthorizationProvider: { .authorized },
            microphonePermissionProvider: { false },
            speechRecognizerFactory: { [recognizer] _ in recognizer },
            audioSession: audioSession,
            audioEngineFactory: { [audioEngine] in audioEngine! }
        )

        // Act
        let result = await Result { try await sut.startRecording() }

        // Assert
        XCTAssertEqual(result.failure as? ExpenseAIEntryVoiceRecordingServiceError, .microphonePermissionDenied)
    }

    func testStartRecordingWhenRecognizerUnavailableThrowsRecognizerUnavailableError() async {
        // Arrange
        let sut = ExpenseAIEntryVoiceRecordingService(
            userProfileStorageService: userProfileStorageService,
            speechAuthorizationProvider: { .authorized },
            microphonePermissionProvider: { true },
            speechRecognizerFactory: { [recognizer] _ in recognizer },
            audioSession: audioSession,
            audioEngineFactory: { [audioEngine] in audioEngine! }
        )
        recognizer.isAvailable = false

        // Act
        let result = await Result { try await sut.startRecording() }

        // Assert
        XCTAssertEqual(result.failure as? ExpenseAIEntryVoiceRecordingServiceError, .recognizerUnavailable)
    }
}

// MARK: - stopRecording

extension ExpenseAIEntryVoiceRecordingServiceTests {
    func testStopRecordingReturnsLatestTranscriptAndReleasesAudio() async throws {
        // Arrange
        var requestedLocales: [Locale] = []
        let sut = ExpenseAIEntryVoiceRecordingService(
            userProfileStorageService: userProfileStorageService,
            speechAuthorizationProvider: { .authorized },
            microphonePermissionProvider: { true },
            speechRecognizerFactory: { [recognizer] locale in
                requestedLocales.append(locale)
                return recognizer
            },
            audioSession: audioSession,
            audioEngineFactory: { [audioEngine] in audioEngine! }
        )
        userProfileStorageService.loadProfileReturnValue = UserProfileDefaultsFixtures.makeProfile(language: "en-US")
        recognizer.isAvailable = true
        recognizer.startRecognitionRequestOnUpdateReturnValue = recognitionTask
        recognitionTask.finishClosure = { [recognizer] in
            let onUpdate = try XCTUnwrap(recognizer?.startRecognitionRequestOnUpdateReceivedArguments?.onUpdate)
            await onUpdate(.init(transcript: "Coffee 5", isFinal: false))
            await onUpdate(.init(transcript: "Coffee 5 at Starbucks", isFinal: true))
        }
        try await sut.startRecording()

        // Act
        let transcript = try await sut.stopRecording()

        // Assert
        XCTAssertEqual(transcript, "Coffee 5 at Starbucks")
        XCTAssertEqual(requestedLocales, [Locale(identifier: "en-US")])
        XCTAssertEqual(audioSession.setActiveOptionsReceivedInvocations.map(\.active), [true, false])
        XCTAssertEqual(audioEngine.startCallsCount, 1)
        XCTAssertTrue(audioEngine.stopCalled)
        XCTAssertFalse(recognitionTask.cancelCalled)
    }
}
