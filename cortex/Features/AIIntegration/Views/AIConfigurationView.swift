//
//  AIConfigurationView.swift
//  Cortex
//
//  Created by Claude Code
//

import SwiftUI

/// Comprehensive AI configuration view
struct AIConfigurationView: View {
    // MARK: - Properties

    @State private var config = AIConfiguration.shared
    @State private var showingClaudeLogin = false

    // MARK: - Body

    var body: some View {
        Form {
            // Service Status Section
            serviceStatusSection

            // Service Selection Section
            serviceSelectionSection

            // Feature Toggles Section
            featureTogglesSection

            // Advanced Settings Section
            advancedSettingsSection

            // Claude Login Section
            claudeLoginSection
        }
        .formStyle(.grouped)
        .navigationTitle("AI-Konfiguration")
        .task {
            await config.updateServiceStatus()
        }
        .onChange(of: config.autoTaggingService) { _, _ in config.saveConfiguration() }
        .onChange(of: config.summarizationService) { _, _ in config.saveConfiguration() }
        .onChange(of: config.linkFindingService) { _, _ in config.saveConfiguration() }
        .onChange(of: config.contentEnrichmentService) { _, _ in config.saveConfiguration() }
        .onChange(of: config.enableAutoTagging) { _, _ in config.saveConfiguration() }
        .onChange(of: config.enableSummarization) { _, _ in config.saveConfiguration() }
        .onChange(of: config.enableLinkFinding) { _, _ in config.saveConfiguration() }
        .onChange(of: config.enableContentEnrichment) { _, _ in config.saveConfiguration() }
        .sheet(isPresented: $showingClaudeLogin) {
            ClaudeLoginView()
        }
    }

    // MARK: - Service Status Section

    private var serviceStatusSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                ServiceStatusRow(
                    name: "OpenAI",
                    icon: "brain",
                    isAvailable: config.openAIConfigured,
                    description: "GPT-4o-mini für schnelle AI-Tasks"
                )

                ServiceStatusRow(
                    name: "Apple Intelligence",
                    icon: "apple.logo",
                    isAvailable: config.appleIntelligenceAvailable,
                    description: "System-integriertes ChatGPT"
                )

                ServiceStatusRow(
                    name: "Claude",
                    icon: "sparkles",
                    isAvailable: config.claudeAvailable,
                    description: "Claude.ai für komplexe Analysen"
                )
            }
        } header: {
            Label("Service Status", systemImage: "server.rack")
        } footer: {
            Button("Status aktualisieren") {
                Task {
                    await config.updateServiceStatus()
                }
            }
            .buttonStyle(.borderless)
        }
    }

    // MARK: - Service Selection Section

    private var serviceSelectionSection: some View {
        Section {
            Picker("Auto-Tagging", selection: $config.autoTaggingService) {
                ForEach(AIServiceType.allCases) { service in
                    Text(service.displayName).tag(service)
                }
            }

            Picker("Zusammenfassung", selection: $config.summarizationService) {
                ForEach(AIServiceType.allCases) { service in
                    Text(service.displayName).tag(service)
                }
            }

            Picker("Link-Finding", selection: $config.linkFindingService) {
                ForEach(AIServiceType.allCases) { service in
                    Text(service.displayName).tag(service)
                }
            }

            Picker("Content-Erweiterung", selection: $config.contentEnrichmentService) {
                ForEach(AIServiceType.allCases) { service in
                    Text(service.displayName).tag(service)
                }
            }
        } header: {
            Label("Service-Zuordnung", systemImage: "arrow.triangle.branch")
        } footer: {
            Text("Wähle welcher AI-Service für welche Aufgabe verwendet werden soll.")
                .font(.caption)
        }
    }

    // MARK: - Feature Toggles Section

    private var featureTogglesSection: some View {
        Section {
            Toggle("Auto-Tagging aktivieren", isOn: $config.enableAutoTagging)
            Toggle("Zusammenfassungen aktivieren", isOn: $config.enableSummarization)
            Toggle("Link-Finding aktivieren", isOn: $config.enableLinkFinding)
            Toggle("Content-Erweiterung aktivieren", isOn: $config.enableContentEnrichment)
        } header: {
            Label("Features", systemImage: "switch.2")
        } footer: {
            Text("Deaktiviere Features, die du nicht nutzen möchtest.")
                .font(.caption)
        }
    }

    // MARK: - Advanced Settings Section

    private var advancedSettingsSection: some View {
        Section {
            Toggle("Fallback zu OpenAI", isOn: $config.fallbackToOpenAI)
                .onChange(of: config.fallbackToOpenAI) { _, _ in config.saveConfiguration() }

            Stepper("Max Retries: \(config.maxRetries)", value: $config.maxRetries, in: 0...5)
                .onChange(of: config.maxRetries) { _, _ in config.saveConfiguration() }

            HStack {
                Text("Timeout:")
                Spacer()
                Text("\(Int(config.timeoutSeconds))s")
                    .foregroundColor(.secondary)
            }

            Slider(value: $config.timeoutSeconds, in: 10...120, step: 10)
                .onChange(of: config.timeoutSeconds) { _, _ in config.saveConfiguration() }
        } header: {
            Label("Erweitert", systemImage: "gearshape.2")
        } footer: {
            Text("Fallback ermöglicht automatisches Umschalten auf OpenAI wenn der bevorzugte Service nicht verfügbar ist.")
                .font(.caption)
        }
    }

    // MARK: - Claude Login Section

    private var claudeLoginSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "person.circle")
                        .foregroundColor(config.claudeAvailable ? .green : .orange)
                    Text(config.claudeService.loginStatus)
                        .foregroundColor(.secondary)
                }

                if !config.claudeAvailable {
                    Button("Bei Claude.ai anmelden") {
                        config.claudeService.ensureWebViewLoaded()
                        showingClaudeLogin = true
                    }
                    .buttonStyle(.bordered)

                    Text("Öffnet ein Fenster mit Claude.ai. Melde dich dort an und klicke dann auf 'Login prüfen'.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Button("Claude Status prüfen") {
                    Task {
                        await config.refreshClaudeStatus()
                    }
                }
                .buttonStyle(.borderless)
            }
        } header: {
            Label("Claude Login", systemImage: "sparkles")
        }
    }
}

// MARK: - Service Status Row

struct ServiceStatusRow: View {
    let name: String
    let icon: String
    let isAvailable: Bool
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(isAvailable ? .green : .secondary)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: isAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isAvailable ? .green : .secondary)
        }
        .padding(.vertical, 4)
    }
}


// MARK: - Preview

#Preview {
    NavigationStack {
        AIConfigurationView()
    }
}
