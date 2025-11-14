//
//  ClaudeWebService.swift
//  Cortex
//
//  Created by Claude Code
//

import Foundation
import WebKit
import Combine

/// Claude.ai web integration using WKWebView and JavaScript injection
/// Note: This is a web-based integration, not an official API
@MainActor
final class ClaudeWebService: NSObject, ObservableObject {
    // MARK: - Properties

    private(set) var webView: WKWebView?
    private var isLoggedIn = false
    private var isInitialized = false

    @Published var isAvailable: Bool = false
    @Published var loginStatus: String = "Nicht angemeldet"

    // Continuation for async/await bridge
    private var currentContinuation: CheckedContinuation<String, Error>?

    // MARK: - Initialization

    override init() {
        super.init()
    }

    // MARK: - Setup

    /// Initialize WKWebView for Claude.ai
    func initialize() {
        guard !isInitialized else { return }

        let config = WKWebViewConfiguration()
        let contentController = WKUserContentController()

        // Add message handler for receiving responses from Claude
        contentController.add(self, name: "claudeResponse")

        config.userContentController = contentController
        config.websiteDataStore = .default() // Use persistent cookies

        webView = WKWebView(frame: .zero, configuration: config)
        webView?.navigationDelegate = self

        // Load Claude.ai
        if let url = URL(string: "https://claude.ai") {
            let request = URLRequest(url: url)
            webView?.load(request)
        }

        isInitialized = true
        print("🌐 Claude WebView initialized")
    }

    /// Check if user is logged into Claude.ai
    func checkLoginStatus() async throws -> Bool {
        guard let webView = webView else {
            throw CortexError.claudeNotAvailable
        }

        // Enhanced script with better detection and debugging
        let script = """
        (function() {
            // Multiple detection methods for Claude.ai interface

            // Method 1: Check for chat input (various selectors)
            const chatInput = document.querySelector('[contenteditable="true"]') ||
                            document.querySelector('div[contenteditable]') ||
                            document.querySelector('textarea[placeholder*="Message"]') ||
                            document.querySelector('textarea[placeholder*="message"]');

            // Method 2: Check for conversation area
            const conversationArea = document.querySelector('[role="main"]') ||
                                   document.querySelector('main') ||
                                   document.querySelector('.conversation');

            // Method 3: Check URL - logged in users are typically on /chat or have projects
            const url = window.location.pathname;
            const isOnChatPage = url.includes('/chat') || url.includes('/project');

            // Method 4: Check for user menu or profile indicator
            const userMenu = document.querySelector('[data-test-id="user-menu"]') ||
                           document.querySelector('button[aria-label*="menu"]') ||
                           document.querySelector('[role="menubutton"]');

            // Method 5: Check if we're NOT on login page
            const notOnLoginPage = !url.includes('/login') &&
                                  !url.includes('/auth') &&
                                  !document.querySelector('input[type="email"]');

            // Combine checks
            const isLoggedIn = (chatInput !== null || isOnChatPage) &&
                             notOnLoginPage &&
                             (conversationArea !== null || userMenu !== null);

            // Debug output
            console.log('Claude Login Check:', {
                chatInput: chatInput !== null,
                conversationArea: conversationArea !== null,
                isOnChatPage: isOnChatPage,
                userMenu: userMenu !== null,
                notOnLoginPage: notOnLoginPage,
                url: url,
                finalResult: isLoggedIn
            });

            return isLoggedIn;
        })();
        """

        do {
            let result = try await webView.evaluateJavaScript(script)
            print("🔍 Claude login check result: \(result)")

            if let isLoggedIn = result as? Bool {
                self.isLoggedIn = isLoggedIn
                self.isAvailable = isLoggedIn
                self.loginStatus = isLoggedIn ? "Angemeldet" : "Nicht angemeldet"

                print("✅ Claude login status updated: \(isLoggedIn ? "Logged in" : "Not logged in")")
                return isLoggedIn
            }

            print("⚠️ Unexpected result type from login check")
            return false
        } catch {
            print("❌ Error checking Claude login status: \(error)")
            self.loginStatus = "Fehler beim Prüfen"
            throw error
        }
    }

    /// Open Claude.ai login window (opens ClaudeLoginView sheet)
    /// This should be called from SwiftUI with a sheet presentation
    func openForLogin() {
        // This is a placeholder - actual implementation is handled by SwiftUI sheet
        // The ClaudeLoginView will be presented as a sheet in the Settings
        print("🌐 Opening Claude login window")
    }

    /// Show Claude.ai in the embedded WebView for login
    func ensureWebViewLoaded() {
        if !isInitialized {
            initialize()
        }
    }

    // MARK: - AI Operations

    func generateTags(for content: String, title: String? = nil) async throws -> [String] {
        guard isAvailable else {
            throw CortexError.claudeNotAvailable
        }

        let prompt = buildTaggingPrompt(title: title, content: content)
        let response = try await sendPrompt(prompt)

        // Parse tags from response
        let tags = response
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return Array(tags.prefix(10))
    }

    func generateSummary(for content: String, title: String? = nil) async throws -> String {
        guard isAvailable else {
            throw CortexError.claudeNotAvailable
        }

        let prompt = buildSummaryPrompt(title: title, content: content)
        return try await sendPrompt(prompt)
    }

    func enrichContent(_ content: String, title: String? = nil) async throws -> String {
        guard isAvailable else {
            throw CortexError.claudeNotAvailable
        }

        let prompt = buildEnrichmentPrompt(title: title, content: content)
        return try await sendPrompt(prompt)
    }

    // MARK: - Web Interaction

    private func sendPrompt(_ prompt: String) async throws -> String {
        guard let webView = webView, isLoggedIn else {
            throw CortexError.claudeNotLoggedIn
        }

        // Escape the prompt for JavaScript
        let escapedPrompt = prompt
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")

        // JavaScript to send message to Claude
        let script = """
        (async function() {
            // Find the chat input
            const chatInput = document.querySelector('[contenteditable="true"]');
            if (!chatInput) {
                throw new Error('Chat input not found');
            }

            // Set the prompt
            chatInput.textContent = "\(escapedPrompt)";

            // Trigger input event
            const inputEvent = new Event('input', { bubbles: true });
            chatInput.dispatchEvent(inputEvent);

            // Find and click send button
            const sendButton = document.querySelector('button[aria-label*="Send"]') ||
                             document.querySelector('button:has(svg)');

            if (!sendButton) {
                throw new Error('Send button not found');
            }

            sendButton.click();

            // Wait for response (this is simplified - in production, use MutationObserver)
            await new Promise(resolve => setTimeout(resolve, 2000));

            // Get the last response
            const responses = document.querySelectorAll('[data-testid*="message"]');
            const lastResponse = responses[responses.length - 1];

            if (lastResponse) {
                return lastResponse.textContent;
            }

            return '';
        })();
        """

        return try await withCheckedThrowingContinuation { continuation in
            self.currentContinuation = continuation

            Task { @MainActor in
                do {
                    let result = try await webView.evaluateJavaScript(script)
                    if let response = result as? String, !response.isEmpty {
                        continuation.resume(returning: response)
                    } else {
                        continuation.resume(throwing: CortexError.claudeRequestFailed(message: "Empty response"))
                    }
                } catch {
                    continuation.resume(throwing: CortexError.claudeRequestFailed(message: error.localizedDescription))
                }
                self.currentContinuation = nil
            }
        }
    }

    // MARK: - Prompt Building

    private func buildTaggingPrompt(title: String?, content: String) -> String {
        var prompt = "Analysiere folgenden Knowledge Entry und generiere 3-5 relevante Tags auf Deutsch.\n\n"

        if let title = title {
            prompt += "Titel: \(title)\n\n"
        }

        prompt += "Inhalt:\n\(content)\n\n"
        prompt += "Antworte NUR mit den Tags, kommasepariert. Keine Erklärungen."

        return prompt
    }

    private func buildSummaryPrompt(title: String?, content: String) -> String {
        var prompt = "Erstelle eine prägnante Zusammenfassung (2-3 Sätze) auf Deutsch für folgenden Knowledge Entry:\n\n"

        if let title = title {
            prompt += "Titel: \(title)\n\n"
        }

        prompt += "Inhalt:\n\(content)\n\n"
        prompt += "Antworte NUR mit der Zusammenfassung, keine Einleitung."

        return prompt
    }

    private func buildEnrichmentPrompt(title: String?, content: String) -> String {
        var prompt = "Erweitere folgenden Knowledge Entry mit relevanten Zusatzinformationen, Kontext oder verwandten Konzepten auf Deutsch:\n\n"

        if let title = title {
            prompt += "Titel: \(title)\n\n"
        }

        prompt += "Inhalt:\n\(content)\n\n"
        prompt += "Füge hilfreiche Ergänzungen hinzu, aber behalte die ursprüngliche Information bei."

        return prompt
    }
}

// MARK: - WKNavigationDelegate

extension ClaudeWebService: WKNavigationDelegate {
    nonisolated func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Task { @MainActor in
            print("🌐 Claude.ai page loaded")
            // Check login status after page load
            try? await checkLoginStatus()
        }
    }

    nonisolated func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        Task { @MainActor in
            print("❌ Claude.ai failed to load: \(error.localizedDescription)")
            self.loginStatus = "Fehler beim Laden"
            self.isAvailable = false
        }
    }
}

// MARK: - WKScriptMessageHandler

extension ClaudeWebService: WKScriptMessageHandler {
    nonisolated func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        Task { @MainActor in
            if message.name == "claudeResponse", let response = message.body as? String {
                currentContinuation?.resume(returning: response)
                currentContinuation = nil
            }
        }
    }
}
