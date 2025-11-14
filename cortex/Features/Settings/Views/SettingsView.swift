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
    @State private var showingSaveSuccess: Bool = false
    @State private var errorMessage: String?

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
            await checkContext7Key()
        }
        .alert("Success", isPresented: $showingSaveSuccess) {
            Button("OK") { }
        } message: {
            Text("Context7 API key saved successfully")
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
    }

    // MARK: - Actions

    private func checkContext7Key() async {
        do {
            hasContext7Key = try await KeychainManager.shared.hasContext7APIKey()
        } catch {
            print("Error checking Context7 key: \(error)")
        }
    }

    private func saveContext7Key() {
        Task {
            do {
                try await KeychainManager.shared.saveContext7APIKey(context7APIKey)
                hasContext7Key = true
                context7APIKey = ""
                showingSaveSuccess = true
            } catch {
                errorMessage = "Failed to save API key: \(error.localizedDescription)"
            }
        }
    }

    private func removeContext7Key() {
        Task {
            do {
                try await KeychainManager.shared.deleteContext7APIKey()
                hasContext7Key = false
            } catch {
                errorMessage = "Failed to remove API key: \(error.localizedDescription)"
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
