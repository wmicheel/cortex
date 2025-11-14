//
//  VoiceInputView.swift
//  Cortex
//
//  Created by Claude Code
//

import SwiftUI

/// View for voice input with live transcription
struct VoiceInputView: View {
    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: VoiceInputViewModel
    let onTranscriptionComplete: (String) -> Void

    // MARK: - Initialization

    init(onTranscriptionComplete: @escaping (String) -> Void) {
        print("📱 VoiceInputView: init() START")
        self.onTranscriptionComplete = onTranscriptionComplete
        _viewModel = State(initialValue: VoiceInputViewModel())
        print("📱 VoiceInputView: init() COMPLETE")
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Microphone Selection
                if !viewModel.isRecording {
                    microphoneSelector
                }

                // Waveform Animation
                if viewModel.isRecording {
                    waveformAnimation
                } else {
                    microphoneIcon
                }

                // Transcription Text
                transcriptionView

                Spacer()

                // Controls
                controlButtons
            }
            .padding(32)
            .frame(width: 500, height: viewModel.isRecording ? 400 : 460)
            .background(Color(nsColor: .windowBackgroundColor))
            .navigationTitle("Voice Input")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        viewModel.cancelRecording()
                        dismiss()
                    }
                }
            }
            .task {
                // Request permissions and load devices on appear
                await viewModel.requestPermissions()
                viewModel.loadAvailableDevices()
            }
            .errorAlert(error: Binding(
                get: { viewModel.error.map { CortexError.unknown(underlying: $0) } },
                set: { _ in viewModel.clearError() }
            ))
        }
    }

    // MARK: - Microphone Selector

    private var microphoneSelector: some View {
        HStack {
            Image(systemName: "mic.fill")
                .foregroundStyle(.secondary)

            Menu {
                ForEach(viewModel.availableDevices) { device in
                    Button(action: {
                        viewModel.selectDevice(device)
                    }) {
                        HStack {
                            Text(device.name)
                            if viewModel.selectedDevice?.id == device.id {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(viewModel.selectedDevice?.name ?? "Mikrofon auswählen")
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }

    // MARK: - Microphone Icon

    private var microphoneIcon: some View {
        Image(systemName: "mic.fill")
            .font(.system(size: 80))
            .foregroundStyle(.secondary)
            .symbolEffect(.pulse, options: .repeating, value: viewModel.isRecording)
    }

    // MARK: - Waveform Animation

    private var waveformAnimation: some View {
        HStack(spacing: 8) {
            ForEach(0..<5, id: \.self) { index in
                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: 8)
                    .frame(height: waveformHeight(for: index))
                    .animation(
                        .easeInOut(duration: 0.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.1),
                        value: viewModel.isRecording
                    )
            }
        }
        .frame(height: 100)
    }

    private func waveformHeight(for index: Int) -> CGFloat {
        guard viewModel.isRecording else { return 20 }
        let heights: [CGFloat] = [30, 60, 80, 60, 30]
        return heights[index]
    }

    // MARK: - Transcription View

    private var transcriptionView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if viewModel.isRecording {
                    // Live partial transcript
                    if !viewModel.partialTranscript.isEmpty {
                        Text(viewModel.partialTranscript)
                            .font(.body)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text("Sprich jetzt...")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                } else if !viewModel.transcribedText.isEmpty {
                    // Final transcript
                    Text(viewModel.transcribedText)
                        .font(.body)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                } else {
                    // Instruction
                    VStack(spacing: 8) {
                        Text("Bereit zur Aufnahme")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text("Drücke 'Aufnahme starten' und sprich deine Gedanken")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(12)
        }
    }

    // MARK: - Control Buttons

    private var controlButtons: some View {
        HStack(spacing: 16) {
            if viewModel.isRecording {
                // Stop button
                Button(action: {
                    let text = viewModel.stopRecording()
                    if !text.isEmpty {
                        onTranscriptionComplete(text)
                        dismiss()
                    }
                }) {
                    Label("Stopp", systemImage: "stop.circle.fill")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .controlSize(.large)

                // Cancel button
                Button(action: {
                    viewModel.cancelRecording()
                }) {
                    Text("Abbrechen")
                }
                .controlSize(.large)
            } else if !viewModel.transcribedText.isEmpty {
                // Use text button
                Button(action: {
                    onTranscriptionComplete(viewModel.transcribedText)
                    dismiss()
                }) {
                    Label("Text verwenden", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                // Retry button
                Button(action: {
                    Task {
                        await viewModel.startRecording()
                    }
                }) {
                    Label("Erneut aufnehmen", systemImage: "arrow.clockwise")
                }
                .controlSize(.large)
            } else {
                // Start button
                Button(action: {
                    Task {
                        await viewModel.startRecording()
                    }
                }) {
                    Label("Aufnahme starten", systemImage: "mic.circle.fill")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!viewModel.hasPermissions)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VoiceInputView { text in
        print("Transcribed: \(text)")
    }
}
