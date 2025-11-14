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

    // Session persistence
    private let sessionKey = "claude_session_data"
    private var sessionRestoreAttempted = false

    // DOM selector fallbacks (updated dynamically if Claude changes their UI)
    private var chatInputSelectors: [String] = [
        "[contenteditable='true']",
        "div[contenteditable]",
        "textarea[placeholder*='Message']",
        "textarea[placeholder*='message']",
        ".ProseMirror",
        "[data-testid='chat-input']",
        "#prompt-textarea"
    ]

    private var sendButtonSelectors: [String] = [
        "button[aria-label*='Send']",
        "button[aria-label*='send']",
        "button[type='submit']",
        "[data-testid='send-button']",
        "button:has(svg[data-icon='send'])",
        "button.send-button"
    ]

    private var responseSelectors: [String] = [
        "[data-testid*='message']",
        ".message-content",
        "[role='article']",
        ".claude-message",
        ".assistant-message"
    ]

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

        // Add localStorage bridge for session persistence
        let localStorageScript = WKUserScript(
            source: """
            // Bridge localStorage to native app
            window.saveSessionData = function() {
                const data = {
                    cookies: document.cookie,
                    localStorage: JSON.stringify(localStorage),
                    sessionStorage: JSON.stringify(sessionStorage),
                    url: window.location.href
                };
                window.webkit.messageHandlers.sessionData.postMessage(data);
            };

            // Auto-save session data periodically
            setInterval(window.saveSessionData, 30000); // Every 30 seconds
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        contentController.addUserScript(localStorageScript)

        // Add message handler for session data
        contentController.add(self, name: "sessionData")

        config.userContentController = contentController

        // Use persistent data store with proper configuration
        let dataStore = WKWebsiteDataStore.default()
        config.websiteDataStore = dataStore

        // Enable JavaScript and modern web features
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")

        webView = WKWebView(frame: .zero, configuration: config)
        webView?.navigationDelegate = self
        webView?.allowsBackForwardNavigationGestures = false

        // Try to restore session first
        Task {
            await restoreSession()
        }

        // Load Claude.ai
        if let url = URL(string: "https://claude.ai") {
            let request = URLRequest(url: url)
            webView?.load(request)
        }

        isInitialized = true
        print("🌐 Claude WebView initialized with session persistence")
    }

    // MARK: - Session Persistence

    /// Save session data to UserDefaults
    private func saveSessionData(_ data: [String: Any]) {
        if let jsonData = try? JSONSerialization.data(withJSONObject: data),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            UserDefaults.standard.set(jsonString, forKey: sessionKey)
            print("💾 Claude session data saved")
        }
    }

    /// Restore session from UserDefaults
    private func restoreSession() async {
        guard !sessionRestoreAttempted,
              let webView = webView,
              let sessionString = UserDefaults.standard.string(forKey: sessionKey),
              let sessionData = sessionString.data(using: .utf8),
              let session = try? JSONSerialization.jsonObject(with: sessionData) as? [String: Any] else {
            print("⚠️ No Claude session to restore")
            sessionRestoreAttempted = true
            return
        }

        sessionRestoreAttempted = true

        // Restore localStorage and sessionStorage
        if let localStorageJSON = session["localStorage"] as? String,
           let sessionStorageJSON = session["sessionStorage"] as? String {

            let restoreScript = """
            (function() {
                try {
                    // Restore localStorage
                    const localData = \(localStorageJSON);
                    for (let key in localData) {
                        localStorage.setItem(key, localData[key]);
                    }

                    // Restore sessionStorage
                    const sessionData = \(sessionStorageJSON);
                    for (let key in sessionData) {
                        sessionStorage.setItem(key, sessionData[key]);
                    }

                    console.log('Session restored successfully');
                    return true;
                } catch (e) {
                    console.error('Failed to restore session:', e);
                    return false;
                }
            })();
            """

            do {
                let result = try await webView.evaluateJavaScript(restoreScript)
                if let success = result as? Bool, success {
                    print("✅ Claude session restored successfully")
                }
            } catch {
                print("⚠️ Failed to restore Claude session: \(error)")
            }
        }

        // Restore cookies are handled by WKWebsiteDataStore automatically
    }

    /// Clear saved session data
    func clearSession() async {
        UserDefaults.standard.removeObject(forKey: sessionKey)

        // Clear WebView cookies and data
        let dataStore = WKWebsiteDataStore.default()
        let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes()

        await dataStore.removeData(ofTypes: dataTypes, modifiedSince: .distantPast)

        isLoggedIn = false
        isAvailable = false
        loginStatus = "Nicht angemeldet"
        sessionRestoreAttempted = false

        print("🗑️ Claude session cleared")
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
            print("🔍 Claude login check result: \(String(describing: result))")

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

    /// Find an element using multiple fallback selectors
    private func findElementScript(selectors: [String], elementName: String) -> String {
        let selectorsList = selectors.map { "'\($0)'" }.joined(separator: ", ")

        return """
        (function() {
            const selectors = [\(selectorsList)];
            for (const selector of selectors) {
                try {
                    const element = document.querySelector(selector);
                    if (element) {
                        console.log('Found \(elementName) using selector:', selector);
                        return element;
                    }
                } catch (e) {
                    console.warn('Selector failed:', selector, e);
                }
            }
            console.error('\(elementName) not found with any selector');
            return null;
        })();
        """
    }

    private func sendPrompt(_ prompt: String) async throws -> String {
        guard let webView = webView, isLoggedIn else {
            throw CortexError.claudeNotLoggedIn
        }

        // Escape the prompt for JavaScript
        let escapedPrompt = prompt
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "'", with: "\\'")

        // Build selector lists for JavaScript
        let chatInputSelectorsList = chatInputSelectors.map { "'\($0)'" }.joined(separator: ", ")
        let sendButtonSelectorsList = sendButtonSelectors.map { "'\($0)'" }.joined(separator: ", ")
        let responseSelectorsList = responseSelectors.map { "'\($0)'" }.joined(separator: ", ")

        // JavaScript to send message to Claude with robust selectors and MutationObserver
        let script = """
        (async function() {
            // Helper: Find element with fallback selectors
            function findElement(selectors, name) {
                for (const selector of selectors) {
                    try {
                        const element = document.querySelector(selector);
                        if (element) {
                            console.log('Found', name, 'using:', selector);
                            return element;
                        }
                    } catch (e) {
                        console.warn('Selector failed:', selector, e);
                    }
                }
                throw new Error(name + ' not found with any selector');
            }

            // Find chat input with fallbacks
            const chatInputSelectors = [\(chatInputSelectorsList)];
            const chatInput = findElement(chatInputSelectors, 'chat input');

            // Count existing messages before sending
            const beforeMessageCount = document.querySelectorAll('[data-testid*="message"], .message-content, [role="article"]').length;

            // Set the prompt
            chatInput.focus();

            // For contenteditable divs
            if (chatInput.contentEditable === 'true') {
                chatInput.textContent = "\(escapedPrompt)";

                // Trigger input events
                const events = ['input', 'change', 'keyup'];
                events.forEach(eventType => {
                    chatInput.dispatchEvent(new Event(eventType, { bubbles: true }));
                });
            } else {
                // For textarea
                chatInput.value = "\(escapedPrompt)";
                chatInput.dispatchEvent(new Event('input', { bubbles: true }));
            }

            // Small delay to ensure input is processed
            await new Promise(resolve => setTimeout(resolve, 100));

            // Find and click send button with fallbacks
            const sendButtonSelectors = [\(sendButtonSelectorsList)];
            const sendButton = findElement(sendButtonSelectors, 'send button');

            // Setup MutationObserver to detect response
            const responsePromise = new Promise((resolve, reject) => {
                let timeout;
                const maxWaitTime = 60000; // 60 seconds max

                const observer = new MutationObserver((mutations) => {
                    // Check for new messages
                    const responseSelectors = [\(responseSelectorsList)];
                    let latestMessage = null;

                    for (const selector of responseSelectors) {
                        try {
                            const messages = document.querySelectorAll(selector);
                            if (messages.length > beforeMessageCount) {
                                // New message appeared
                                latestMessage = messages[messages.length - 1];
                                break;
                            }
                        } catch (e) {
                            continue;
                        }
                    }

                    if (latestMessage) {
                        clearTimeout(timeout);
                        observer.disconnect();

                        // Extract text content
                        const text = latestMessage.textContent || latestMessage.innerText || '';

                        if (text && text.trim().length > 0) {
                            resolve(text.trim());
                        } else {
                            reject(new Error('Response is empty'));
                        }
                    }
                });

                // Observe the entire document for changes
                observer.observe(document.body, {
                    childList: true,
                    subtree: true,
                    characterData: true
                });

                // Timeout fallback
                timeout = setTimeout(() => {
                    observer.disconnect();
                    reject(new Error('Response timeout after ' + (maxWaitTime / 1000) + ' seconds'));
                }, maxWaitTime);
            });

            // Click send button
            sendButton.click();
            console.log('Send button clicked, waiting for response...');

            // Wait for response
            const response = await responsePromise;
            return response;
        })();
        """

        // Execute with retry logic
        var lastError: Error?
        for attempt in 1...3 {
            do {
                let result = try await webView.evaluateJavaScript(script)

                if let response = result as? String, !response.isEmpty {
                    print("✅ Claude response received (attempt \(attempt)): \(response.prefix(100))...")
                    return response
                } else {
                    throw CortexError.claudeRequestFailed(message: "Empty response")
                }
            } catch {
                lastError = error
                print("⚠️ Claude request attempt \(attempt) failed: \(error.localizedDescription)")

                if attempt < 3 {
                    // Wait before retry
                    try await Task.sleep(for: .seconds(2))
                }
            }
        }

        throw lastError ?? CortexError.claudeRequestFailed(message: "All retry attempts failed")
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
            _ = try? await checkLoginStatus()
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
            switch message.name {
            case "claudeResponse":
                if let response = message.body as? String {
                    currentContinuation?.resume(returning: response)
                    currentContinuation = nil
                }

            case "sessionData":
                // Save session data for persistence
                if let sessionData = message.body as? [String: Any] {
                    saveSessionData(sessionData)
                }

            default:
                print("⚠️ Unknown message handler: \(message.name)")
            }
        }
    }
}
