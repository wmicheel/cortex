//
//  ClaudeLoginView.swift
//  Cortex
//
//  Created by Claude Code
//

import SwiftUI
import WebKit

/// View for logging into Claude.ai via embedded WebView
struct ClaudeLoginView: View {
    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @State private var config = AIConfiguration.shared
    @State private var isCheckingStatus = false
    @State private var showSuccess = false
    @State private var debugInfo: String = "Warte auf Login-Check..."

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bei Claude.ai anmelden")
                        .font(.headline)

                    Text(config.claudeService.loginStatus)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button("Fertig") {
                    // Check status before dismissing
                    Task {
                        await config.refreshClaudeStatus()
                        await MainActor.run {
                            dismiss()
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // WebView
            ClaudeWebViewRepresentable(webView: config.claudeService.webView)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            // Footer with status check
            VStack(spacing: 8) {
                HStack {
                    if isCheckingStatus {
                        ProgressView()
                            .scaleEffect(0.8)
                            .padding(.trailing, 4)
                    }

                    Text("Melde dich oben an, dann klicke auf 'Login prüfen'")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Button("Login prüfen") {
                        checkLoginStatus()
                    }
                    .disabled(isCheckingStatus)
                }

                // Debug info
                Text(debugInfo)
                    .font(.caption2)
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
        }
        .frame(width: 900, height: 700)
        .alert("Erfolgreich angemeldet!", isPresented: $showSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Du bist jetzt bei Claude.ai angemeldet und kannst die AI-Features nutzen.")
        }
    }

    // MARK: - Actions

    private func checkLoginStatus() {
        isCheckingStatus = true
        debugInfo = "Prüfe Login-Status..."

        Task {
            do {
                // Use refreshClaudeStatus which properly updates both service and config
                await config.refreshClaudeStatus()

                await MainActor.run {
                    isCheckingStatus = false

                    if config.claudeAvailable {
                        debugInfo = "✅ Login erfolgreich! Claude verfügbar."
                        showSuccess = true
                    } else {
                        debugInfo = "❌ Nicht eingeloggt. Status: \(config.claudeService.loginStatus)"
                    }
                }
            } catch {
                await MainActor.run {
                    isCheckingStatus = false
                    debugInfo = "❌ Fehler beim Prüfen: \(error.localizedDescription)"
                }
                print("❌ Login check failed: \(error)")
            }
        }
    }
}

// MARK: - WebView Representable

struct ClaudeWebViewRepresentable: NSViewRepresentable {
    let webView: WKWebView?

    func makeNSView(context: Context) -> WKWebView {
        guard let webView = webView else {
            // Fallback if webView is nil
            let config = WKWebViewConfiguration()
            let fallbackWebView = WKWebView(frame: .zero, configuration: config)
            if let url = URL(string: "https://claude.ai") {
                fallbackWebView.load(URLRequest(url: url))
            }
            return fallbackWebView
        }
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        // No updates needed
    }
}

// MARK: - Preview

#Preview {
    ClaudeLoginView()
}
