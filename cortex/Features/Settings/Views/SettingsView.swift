//
//  SettingsView.swift
//  Cortex
//
//  Created by Claude Code
//

import SwiftUI

/// Settings view for app configuration
struct SettingsView: View {
    // MARK: - Properties

    @State private var context7APIKey: String = ""
    @State private var hasContext7Key: Bool = false
    @State private var openAIAPIKey: String = ""
    @State private var hasOpenAIKey: Bool = false
    @State private var showingSaveSuccess: Bool = false
    @State private var saveSuccessMessage: String = ""
    @State private var errorMessage: String?
    @State private var aiConfig = AIConfiguration.shared
    @State private var showingClaudeLogin = false

    // MARK: - Body

    var body: some View {
        Form {
            // General Section
            Section("General") {
                LabeledContent("App Version") {
                    Text("1.0.0 (Phase 2)")
                        .foregroundColor(.secondary)
                }

                LabeledContent("Build") {
                    Text("Phase 2 - Core Features")
                        .foregroundColor(.secondary)
                }
            }

            // AI Integration Section
            Section {
                NavigationLink(destination: AIConfigurationView()) {
                    Label("AI-Konfiguration", systemImage: "gearshape.2.fill")
                }

                Divider()
                    .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 12) {
                    Text("OpenAI API Key")
                        .font(.headline)

                    if hasOpenAIKey {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("API key configured")
                                .foregroundColor(.secondary)
                            Spacer()
                            Button("Remove") {
                                removeOpenAIKey()
                            }
                            .foregroundColor(.red)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            SecureField("Enter OpenAI API Key (sk-...)", text: $openAIAPIKey)
                                .textFieldStyle(.roundedBorder)

                            Button("Save API Key") {
                                saveOpenAIKey()
                            }
                            .disabled(openAIAPIKey.isEmpty)
                        }
                    }

                    Text("OpenAI powers AI features like auto-tagging, summarization, and link finding. Uses GPT-4o-mini for cost-effective processing.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Divider()
                        .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Apple Intelligence")
                            .font(.headline)

                        HStack {
                            Image(systemName: "apple.logo")
                                .foregroundColor(.secondary)
                            Text("ChatGPT via System Integration")
                            Spacer()
                            Text("Verfügbar")
                                .foregroundColor(.green)
                                .font(.caption)
                        }

                        Text("Nutzt den im System integrierten ChatGPT-Zugang (ChatGPT Business). Automatischer Fallback zu OpenAI API falls nicht verfügbar.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Divider()
                        .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Claude")
                            .font(.headline)

                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(aiConfig.claudeAvailable ? .green : .secondary)
                            Text("Claude.ai")
                            Spacer()
                            Text(aiConfig.claudeService.loginStatus)
                                .foregroundColor(aiConfig.claudeAvailable ? .green : .secondary)
                                .font(.caption)
                        }

                        if !aiConfig.claudeAvailable {
                            Button("Bei Claude.ai anmelden") {
                                aiConfig.claudeService.ensureWebViewLoaded()
                                showingClaudeLogin = true
                            }
                            .buttonStyle(.bordered)

                            Text("Klicke auf 'Anmelden' um ein Fenster mit Claude.ai zu öffnen. Melde dich dort an, dann kannst du erweiterte AI-Features nutzen.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Button("Claude Status prüfen") {
                            Task {
                                await aiConfig.refreshClaudeStatus()
                            }
                        }
                        .buttonStyle(.borderless)
                        .font(.caption)

                        Text("Claude wird für komplexe Analysen verwendet. Automatischer Fallback zu OpenAI falls nicht verfügbar.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Divider()
                        .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Service-Auswahl")
                            .font(.headline)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "tag.fill")
                                    .frame(width: 24)
                                    .foregroundColor(.secondary)
                                Text("Auto-Tagging:")
                                Spacer()
                                Text(aiConfig.autoTaggingService.displayName)
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }

                            HStack {
                                Image(systemName: "doc.text.fill")
                                    .frame(width: 24)
                                    .foregroundColor(.secondary)
                                Text("Zusammenfassung:")
                                Spacer()
                                Text(aiConfig.summarizationService.displayName)
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }

                            HStack {
                                Image(systemName: "link")
                                    .frame(width: 24)
                                    .foregroundColor(.secondary)
                                Text("Link-Finding:")
                                Spacer()
                                Text(aiConfig.linkFindingService.displayName)
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }

                            HStack {
                                Image(systemName: "text.append")
                                    .frame(width: 24)
                                    .foregroundColor(.secondary)
                                Text("Content-Erweiterung:")
                                Spacer()
                                Text(aiConfig.contentEnrichmentService.displayName)
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                        .font(.subheadline)

                        Text("Services werden automatisch je nach Aufgabe ausgewählt. Ändere die Zuordnung in der AI-Konfiguration.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                }
            } header: {
                Label("AI Integration", systemImage: "sparkles")
            }

            // Context7 Section
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("API Key")
                        .font(.headline)

                    if hasContext7Key {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("API key configured")
                                .foregroundColor(.secondary)
                            Spacer()
                            Button("Remove") {
                                removeContext7Key()
                            }
                            .foregroundColor(.red)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            SecureField("Enter Context7 API Key", text: $context7APIKey)
                                .textFieldStyle(.roundedBorder)

                            Button("Save API Key") {
                                saveContext7Key()
                            }
                            .disabled(context7APIKey.isEmpty)
                        }
                    }

                    Text("Context7 provides semantic search capabilities for your knowledge base.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } header: {
                Label("Context7 Integration", systemImage: "magnifyingglass.circle")
            }

            // CloudKit Section
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "icloud.fill")
                            .foregroundColor(.blue)
                        Text("iCloud Sync")
                        Spacer()
                        Text("Active")
                            .foregroundColor(.secondary)
                    }

                    Text("Your knowledge base is automatically synced via iCloud.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } header: {
                Label("Storage", systemImage: "externaldrive.fill.badge.icloud")
            }

            // Privacy Section
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label("All data stored locally", systemImage: "checkmark.shield.fill")
                        .foregroundColor(.green)

                    Label("No third-party analytics", systemImage: "checkmark.shield.fill")
                        .foregroundColor(.green)

                    Label("End-to-end encrypted sync", systemImage: "checkmark.shield.fill")
                        .foregroundColor(.green)

                    Text("Cortex is privacy-first. Your data never leaves your devices except through Apple's encrypted iCloud sync.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            } header: {
                Label("Privacy", systemImage: "lock.shield")
            }

            // About Section
            Section("About") {
                Link(destination: URL(string: "https://github.com/yourusername/cortex")!) {
                    Label("GitHub Repository", systemImage: "chevron.right")
                }

                Link(destination: URL(string: "https://claude.com/claude-code")!) {
                    HStack {
                        Text("Built with Claude Code")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
        .task {
            await checkAPIKeys()
        }
        .alert("Success", isPresented: $showingSaveSuccess) {
            Button("OK") { }
        } message: {
            Text(saveSuccessMessage)
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
        .sheet(isPresented: $showingClaudeLogin) {
            ClaudeLoginView()
        }
    }

    // MARK: - Actions

    private func checkAPIKeys() async {
        do {
            hasContext7Key = try await KeychainManager.shared.hasContext7APIKey()
            hasOpenAIKey = try await KeychainManager.shared.get(key: "openAIAPIKey") != nil

            // Update AI service status
            await aiConfig.updateServiceStatus()
        } catch {
            print("Error checking API keys: \(error)")
        }
    }

    private func saveOpenAIKey() {
        Task {
            do {
                try await KeychainManager.shared.save(key: "openAIAPIKey", value: openAIAPIKey)
                hasOpenAIKey = true
                openAIAPIKey = ""
                saveSuccessMessage = "OpenAI API key saved successfully"
                showingSaveSuccess = true
            } catch {
                errorMessage = "Failed to save OpenAI API key: \(error.localizedDescription)"
            }
        }
    }

    private func removeOpenAIKey() {
        Task {
            do {
                try await KeychainManager.shared.delete(key: "openAIAPIKey")
                hasOpenAIKey = false
            } catch {
                errorMessage = "Failed to remove OpenAI API key: \(error.localizedDescription)"
            }
        }
    }

    private func saveContext7Key() {
        Task {
            do {
                try await KeychainManager.shared.saveContext7APIKey(context7APIKey)
                hasContext7Key = true
                context7APIKey = ""
                saveSuccessMessage = "Context7 API key saved successfully"
                showingSaveSuccess = true
            } catch {
                errorMessage = "Failed to save Context7 API key: \(error.localizedDescription)"
            }
        }
    }

    private func removeContext7Key() {
        Task {
            do {
                try await KeychainManager.shared.deleteContext7APIKey()
                hasContext7Key = false
            } catch {
                errorMessage = "Failed to remove Context7 API key: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SettingsView()
    }
}
