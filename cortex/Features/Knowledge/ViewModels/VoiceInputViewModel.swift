//
//  VoiceInputViewModel.swift
//  Cortex
//
//  Created by Claude Code
//

import Foundation
import Speech
import Observation

/// ViewModel for voice input and transcription
@Observable
@MainActor
final class VoiceInputViewModel {
    // MARK: - Published State

    private(set) var isRecording = false
    private(set) var transcribedText = ""
    private(set) var partialTranscript = ""
    private(set) var error: SpeechRecognitionError?
    private(set) var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined

    // MARK: - Properties

    private let speechService: SpeechRecognitionService

    // MARK: - Initialization

    init(speechService: SpeechRecognitionService = SpeechRecognitionService()) {
        self.speechService = speechService
    }

    // MARK: - Authorization

    /// Request microphone and speech recognition permissions
    func requestPermissions() async {
        let status = await speechService.requestAuthorization()
        authorizationStatus = status
    }

    /// Check if we have necessary permissions
    var hasPermissions: Bool {
        authorizationStatus == .authorized
    }

    // MARK: - Recording

    /// Start voice recording and transcription
    func startRecording() async {
        guard !isRecording else { return }

        // Request permissions if needed
        if authorizationStatus == .notDetermined {
            await requestPermissions()
        }

        guard hasPermissions else {
            error = .notAuthorized
            return
        }

        // Reset state
        transcribedText = ""
        partialTranscript = ""
        error = nil
        isRecording = true

        do {
            try await speechService.startRecording { [weak self] partial in
                Task { @MainActor in
                    self?.partialTranscript = partial
                }
            }
        } catch let speechError as SpeechRecognitionError {
            error = speechError
            isRecording = false
        } catch {
            self.error = .recordingFailed(error)
            isRecording = false
        }
    }

    /// Stop recording and get final transcription
    func stopRecording() async -> String {
        guard isRecording else { return transcribedText }

        isRecording = false

        let finalText = await speechService.stopRecording()
        transcribedText = finalText
        partialTranscript = ""

        return finalText
    }

    /// Cancel recording without saving
    func cancelRecording() async {
        guard isRecording else { return }

        isRecording = false
        _ = await speechService.stopRecording()

        transcribedText = ""
        partialTranscript = ""
    }

    /// Clear error
    func clearError() {
        error = nil
    }
}
