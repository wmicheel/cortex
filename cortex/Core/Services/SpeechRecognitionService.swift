//
//  SpeechRecognitionService.swift
//  Cortex
//
//  Created by Claude Code
//

import Foundation
import Speech
import AVFoundation

/// Service for speech recognition and audio recording
actor SpeechRecognitionService {
    // MARK: - Properties

    private let speechRecognizer: SFSpeechRecognizer
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var lastTranscription: String = ""

    // MARK: - Initialization

    init(locale: Locale = .current) {
        self.speechRecognizer = SFSpeechRecognizer(locale: locale) ?? SFSpeechRecognizer(locale: Locale(identifier: "de-DE"))!
    }

    // MARK: - Authorization

    /// Request speech recognition authorization
    func requestAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }

    /// Check if authorized for speech recognition
    var isAuthorized: Bool {
        SFSpeechRecognizer.authorizationStatus() == .authorized
    }

    /// Check if speech recognition is available
    var isAvailable: Bool {
        speechRecognizer.isAvailable
    }

    // MARK: - Recording

    /// Start recording and live transcription
    /// - Parameter onPartialResult: Callback for partial transcription updates
    /// - Returns: Recording session ID
    func startRecording(onPartialResult: @escaping @Sendable (String) -> Void) async throws {
        // Cancel any ongoing recognition
        _ = await stopRecording()

        // Check authorization
        guard isAuthorized else {
            throw SpeechRecognitionError.notAuthorized
        }

        guard isAvailable else {
            throw SpeechRecognitionError.notAvailable
        }

        // Note: AVAudioSession is iOS-only. macOS handles audio automatically.

        // Create recognition request
        let request = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest = request
        request.shouldReportPartialResults = true

        // Configure audio engine
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        // Start recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            if let result = result {
                let transcription = result.bestTranscription.formattedString

                // Store last transcription
                Task {
                    await self?.updateTranscription(transcription)
                }

                // Notify UI
                Task { @MainActor in
                    onPartialResult(transcription)
                }
            }

            if error != nil || result?.isFinal == true {
                // Recognition finished
            }
        }
    }

    private func updateTranscription(_ text: String) {
        lastTranscription = text
    }

    /// Stop recording and return final transcription
    /// - Returns: Final transcribed text
    func stopRecording() async -> String {
        // Finish recognition request first
        recognitionRequest?.endAudio()

        // Wait a bit for final result
        try? await Task.sleep(for: .milliseconds(500))

        // Get final transcription
        let finalText = lastTranscription

        // Cancel task
        if let task = recognitionTask {
            task.cancel()
        }

        // Stop audio engine
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        // Cleanup
        recognitionRequest = nil
        recognitionTask = nil
        lastTranscription = ""

        return finalText
    }
}

// MARK: - Errors

enum SpeechRecognitionError: LocalizedError {
    case notAuthorized
    case notAvailable
    case recordingFailed(Error)

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Spracherkennung nicht autorisiert. Bitte erlauben Sie den Zugriff in den Systemeinstellungen."
        case .notAvailable:
            return "Spracherkennung ist momentan nicht verfügbar. Bitte überprüfen Sie Ihre Internetverbindung."
        case .recordingFailed(let error):
            return "Aufnahme fehlgeschlagen: \(error.localizedDescription)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .notAuthorized:
            return "Öffnen Sie Systemeinstellungen → Datenschutz & Sicherheit → Mikrofon/Spracherkennung"
        case .notAvailable:
            return "Versuchen Sie es später erneut oder überprüfen Sie Ihre Netzwerkverbindung."
        case .recordingFailed:
            return "Stellen Sie sicher, dass Ihr Mikrofon richtig angeschlossen ist."
        }
    }
}
