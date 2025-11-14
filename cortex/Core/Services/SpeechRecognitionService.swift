//
//  SpeechRecognitionService.swift
//  Cortex
//
//  Created by Claude Code
//

import Foundation
import Speech
import AVFoundation
import CoreAudio

/// Service for speech recognition and audio recording
@MainActor
final class SpeechRecognitionService {
    // MARK: - Properties

    private let speechRecognizer: SFSpeechRecognizer
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var lastTranscription: String = ""

    // MARK: - Initialization

    init(locale: Locale = Locale(identifier: "de-DE")) {
        print("🎙️ SpeechRecognitionService: init() START")
        print("🎙️ SpeechRecognitionService: Requested locale: \(locale.identifier)")

        // Try to create recognizer with requested locale (default: de-DE)
        if let recognizer = SFSpeechRecognizer(locale: locale) {
            print("🎙️ SpeechRecognitionService: ✅ Created recognizer with locale: \(locale.identifier)")
            self.speechRecognizer = recognizer
        } else if let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "de-DE")) {
            print("🎙️ SpeechRecognitionService: ✅ Fallback: Created recognizer with de-DE locale")
            self.speechRecognizer = recognizer
        } else if let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")) {
            print("🎙️ SpeechRecognitionService: ⚠️ Fallback: Created recognizer with en-US locale")
            self.speechRecognizer = recognizer
        } else {
            print("🎙️ SpeechRecognitionService: ❌ ERROR - Could not create recognizer with any locale")
            fatalError("SFSpeechRecognizer could not be initialized")
        }

        print("🎙️ SpeechRecognitionService: init() COMPLETE - Using locale: \(speechRecognizer.locale.identifier)")
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

    // MARK: - Audio Device Management

    /// Get list of available audio input devices
    func getAvailableInputDevices() -> [AudioDevice] {
        var devices: [AudioDevice] = []

        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        let status = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &dataSize
        )

        guard status == kAudioHardwareNoError else { return devices }

        let deviceCount = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = [AudioDeviceID](repeating: 0, count: deviceCount)

        AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &dataSize,
            &deviceIDs
        )

        for deviceID in deviceIDs {
            // Check if device has input streams
            var inputPropertyAddress = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyStreams,
                mScope: kAudioDevicePropertyScopeInput,
                mElement: kAudioObjectPropertyElementMain
            )

            var inputDataSize: UInt32 = 0
            AudioObjectGetPropertyDataSize(
                deviceID,
                &inputPropertyAddress,
                0,
                nil,
                &inputDataSize
            )

            // Only include devices with input streams
            guard inputDataSize > 0 else { continue }

            // Get device name
            var namePropertyAddress = AudioObjectPropertyAddress(
                mSelector: kAudioObjectPropertyName,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )

            var deviceName: CFString = "" as CFString
            var nameSize = UInt32(MemoryLayout<CFString>.size)

            AudioObjectGetPropertyData(
                deviceID,
                &namePropertyAddress,
                0,
                nil,
                &nameSize,
                &deviceName
            )

            devices.append(AudioDevice(
                id: String(deviceID),
                name: deviceName as String,
                deviceID: deviceID
            ))
        }

        return devices
    }

    /// Set the audio input device to use for recording
    func setInputDevice(_ device: AudioDevice) {
        print("🎙️ SpeechRecognitionService: Setting input device to: \(device.name)")

        // Set the device as the input device for the audio engine
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var deviceID = device.deviceID
        let size = UInt32(MemoryLayout<AudioDeviceID>.size)

        AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            size,
            &deviceID
        )
    }

    // MARK: - Recording

    /// Start recording and live transcription
    /// - Parameter onPartialResult: Callback for partial transcription updates
    /// - Returns: Recording session ID
    func startRecording(onPartialResult: @escaping (String) -> Void) async throws {
        print("🎙️ SpeechRecognitionService: startRecording() called")

        // Cancel any ongoing recognition
        print("🎙️ SpeechRecognitionService: Stopping any existing recording")
        _ = stopRecording()

        // Check authorization
        print("🎙️ SpeechRecognitionService: Checking authorization - isAuthorized: \(isAuthorized)")
        guard isAuthorized else {
            print("🎙️ SpeechRecognitionService: NOT AUTHORIZED - throwing error")
            throw SpeechRecognitionError.notAuthorized
        }

        print("🎙️ SpeechRecognitionService: Checking availability - isAvailable: \(isAvailable)")
        guard isAvailable else {
            print("🎙️ SpeechRecognitionService: NOT AVAILABLE - throwing error")
            throw SpeechRecognitionError.notAvailable
        }

        print("🎙️ SpeechRecognitionService: Authorization and availability checks passed")

        // Note: AVAudioSession is iOS-only. macOS handles audio automatically.

        print("🎙️ SpeechRecognitionService: Creating recognition request")
        // Create recognition request
        let request = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest = request
        request.shouldReportPartialResults = true
        print("🎙️ SpeechRecognitionService: Recognition request created")

        // Configure audio engine
        print("🎙️ SpeechRecognitionService: Configuring audio engine")
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        print("🎙️ SpeechRecognitionService: Recording format: \(recordingFormat)")

        print("🎙️ SpeechRecognitionService: Installing audio tap")
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        print("🎙️ SpeechRecognitionService: Preparing audio engine")
        audioEngine.prepare()

        print("🎙️ SpeechRecognitionService: Starting audio engine")
        try audioEngine.start()
        print("🎙️ SpeechRecognitionService: Audio engine started successfully")

        // Start recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                let transcription = result.bestTranscription.formattedString

                // Store last transcription
                Task { @MainActor in
                    self.lastTranscription = transcription
                    onPartialResult(transcription)
                }
            }

            if error != nil || result?.isFinal == true {
                // Recognition finished
            }
        }
    }

    /// Stop recording and return final transcription
    /// - Returns: Final transcribed text
    func stopRecording() -> String {
        // Finish recognition request first
        recognitionRequest?.endAudio()

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

// MARK: - Audio Device Model

/// Represents an audio input device
struct AudioDevice: Identifiable, Hashable {
    let id: String
    let name: String
    let deviceID: AudioDeviceID

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: AudioDevice, rhs: AudioDevice) -> Bool {
        lhs.id == rhs.id
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
