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
    private(set) var availableDevices: [AudioDevice] = []
    var selectedDevice: AudioDevice? = nil

    // MARK: - Properties

    private var speechService: SpeechRecognitionService?

    // MARK: - Initialization

    init() {
        // Service created lazily
        print("🎤 VoiceInputViewModel: init() called")
    }

    /// Get or create speech service
    private func getService() -> SpeechRecognitionService {
        if let service = speechService {
            return service
        }
        print("🎤 VoiceInputViewModel: Creating SpeechRecognitionService")
        let service = SpeechRecognitionService()
        speechService = service
        print("🎤 VoiceInputViewModel: SpeechRecognitionService created")
        return service
    }

    // MARK: - Authorization

    /// Request microphone and speech recognition permissions
    func requestPermissions() async {
        let status = await getService().requestAuthorization()
        authorizationStatus = status
    }

    /// Check if we have necessary permissions
    var hasPermissions: Bool {
        authorizationStatus == .authorized
    }

    /// Load available audio input devices
    func loadAvailableDevices() {
        print("🎤 VoiceInputViewModel: Loading available audio devices")
        availableDevices = getService().getAvailableInputDevices()
        print("🎤 VoiceInputViewModel: Found \(availableDevices.count) devices")

        // Select first device by default if none selected
        if selectedDevice == nil, let firstDevice = availableDevices.first {
            selectedDevice = firstDevice
            print("🎤 VoiceInputViewModel: Auto-selected device: \(firstDevice.name)")
        }
    }

    /// Change the selected audio input device
    func selectDevice(_ device: AudioDevice) {
        print("🎤 VoiceInputViewModel: Selecting device: \(device.name)")
        selectedDevice = device
        getService().setInputDevice(device)
    }

    // MARK: - Recording

    /// Start voice recording and transcription
    func startRecording() async {
        print("🎤 VoiceInputViewModel: startRecording() called")
        guard !isRecording else {
            print("🎤 VoiceInputViewModel: Already recording, returning")
            return
        }

        // Request permissions if needed
        if authorizationStatus == .notDetermined {
            print("🎤 VoiceInputViewModel: Requesting permissions")
            await requestPermissions()
        }

        guard hasPermissions else {
            print("🎤 VoiceInputViewModel: No permissions, setting error")
            error = .notAuthorized
            return
        }

        print("🎤 VoiceInputViewModel: Permissions granted, starting recording")

        // Reset state
        transcribedText = ""
        partialTranscript = ""
        error = nil
        isRecording = true

        do {
            print("🎤 VoiceInputViewModel: Calling speechService.startRecording()")
            try await getService().startRecording { [weak self] partial in
                guard let self = self else { return }
                print("🎤 VoiceInputViewModel: Partial transcript: \(partial)")
                self.partialTranscript = partial
            }
            print("🎤 VoiceInputViewModel: Recording started successfully")
        } catch let speechError as SpeechRecognitionError {
            print("🎤 VoiceInputViewModel: SpeechRecognitionError: \(speechError)")
            error = speechError
            isRecording = false
        } catch {
            print("🎤 VoiceInputViewModel: Generic error: \(error)")
            self.error = .recordingFailed(error)
            isRecording = false
        }
    }

    /// Stop recording and get final transcription
    func stopRecording() -> String {
        guard isRecording else { return transcribedText }

        isRecording = false

        let finalText = getService().stopRecording()
        transcribedText = finalText
        partialTranscript = ""

        return finalText
    }

    /// Cancel recording without saving
    func cancelRecording() {
        guard isRecording else { return }

        isRecording = false
        _ = getService().stopRecording()

        transcribedText = ""
        partialTranscript = ""
    }

    /// Clear error
    func clearError() {
        error = nil
    }
}
