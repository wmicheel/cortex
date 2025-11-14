//
//  OpenAIService.swift
//  Cortex
//
//  Created by Claude Code
//

import Foundation

/// Service for OpenAI API integration
actor OpenAIService {
    // MARK: - Properties

    private let baseURL = "https://api.openai.com/v1"
    private let model = "gpt-4o-mini"  // Fast and cost-effective
    private let keychainManager: KeychainManager
    private var apiKey: String?

    // MARK: - Initialization

    init(keychainManager: KeychainManager = .shared) {
        self.keychainManager = keychainManager
    }

    // MARK: - Configuration

    /// Load API key from Keychain
    func loadAPIKey() async throws {
        self.apiKey = try await keychainManager.get(key: "openAIAPIKey")
    }

    /// Save API key to Keychain
    func saveAPIKey(_ key: String) async throws {
        try await keychainManager.save(key: "openAIAPIKey", value: key)
        self.apiKey = key
    }

    /// Check if API key is configured
    func isConfigured() async -> Bool {
        if apiKey == nil {
            apiKey = try? await keychainManager.get(key: "openAIAPIKey")
        }
        return apiKey != nil
    }

    // MARK: - AI Tasks

    /// Generate tags for content
    func generateTags(for content: String, title: String? = nil) async throws -> [String] {
        let prompt = buildTaggingPrompt(title: title, content: content)
        let response = try await callOpenAI(prompt: prompt, maxTokens: 100)

        // Parse comma-separated tags
        let tags = response
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return Array(tags.prefix(10))  // Max 10 tags
    }

    /// Generate summary of content
    func generateSummary(for content: String, title: String? = nil) async throws -> String {
        let prompt = buildSummaryPrompt(title: title, content: content)
        let response = try await callOpenAI(prompt: prompt, maxTokens: 300)
        return response.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Find similar entries by semantic similarity
    func findSimilarEntries(
        for content: String,
        among candidates: [(id: String, title: String, content: String)],
        limit: Int = 5
    ) async throws -> [String] {
        guard !candidates.isEmpty else { return [] }

        let prompt = buildSimilarityPrompt(content: content, candidates: candidates)
        let response = try await callOpenAI(prompt: prompt, maxTokens: 200)

        // Parse response - expecting entry IDs or indices
        let ids = parseEntryIDs(from: response, candidates: candidates)
        return Array(ids.prefix(limit))
    }

    /// Enrich content with additional information
    func enrichContent(_ content: String, title: String? = nil) async throws -> String {
        let prompt = buildEnrichmentPrompt(title: title, content: content)
        let response = try await callOpenAI(prompt: prompt, maxTokens: 500, temperature: 0.7)
        return response.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - OpenAI API Call

    private func callOpenAI(
        prompt: String,
        maxTokens: Int = 500,
        temperature: Double = 0.3
    ) async throws -> String {
        if apiKey == nil {
            apiKey = try? await keychainManager.get(key: "openAIAPIKey")
        }

        guard let apiKey = apiKey else {
            throw CortexError.openAINotConfigured
        }

        let url = URL(string: "\(baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "max_tokens": maxTokens,
            "temperature": temperature
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CortexError.openAIRequestFailed(message: "Invalid response")
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw CortexError.openAIRequestFailed(message: "HTTP \(httpResponse.statusCode): \(errorMessage)")
        }

        // Parse response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw CortexError.openAIInvalidResponse
        }

        return content
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

    private func buildSimilarityPrompt(
        content: String,
        candidates: [(id: String, title: String, content: String)]
    ) -> String {
        var prompt = "Finde die thematisch ähnlichsten Einträge zu folgendem Text:\n\n"
        prompt += "\(content)\n\n"
        prompt += "Vergleiche mit diesen Einträgen:\n\n"

        for (index, candidate) in candidates.enumerated() {
            prompt += "\(index + 1). [\(candidate.id)] \(candidate.title)\n"
            let preview = String(candidate.content.prefix(200))
            prompt += "   \(preview)...\n\n"
        }

        prompt += "Antworte NUR mit den IDs der ähnlichsten Einträge (max. 5), kommasepariert."

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

    // MARK: - Response Parsing

    private func parseEntryIDs(
        from response: String,
        candidates: [(id: String, title: String, content: String)]
    ) -> [String] {
        // Try to extract IDs from response
        var foundIDs: [String] = []

        // Method 1: Look for IDs in square brackets [id]
        let idPattern = #"\[([^\]]+)\]"#
        if let regex = try? NSRegularExpression(pattern: idPattern) {
            let matches = regex.matches(
                in: response,
                range: NSRange(response.startIndex..., in: response)
            )

            for match in matches {
                if let range = Range(match.range(at: 1), in: response) {
                    let id = String(response[range])
                    if candidates.contains(where: { $0.id == id }) {
                        foundIDs.append(id)
                    }
                }
            }
        }

        // Method 2: If no IDs found, try to match by numbers (indices)
        if foundIDs.isEmpty {
            let numberPattern = #"\b(\d+)\b"#
            if let regex = try? NSRegularExpression(pattern: numberPattern) {
                let matches = regex.matches(
                    in: response,
                    range: NSRange(response.startIndex..., in: response)
                )

                for match in matches {
                    if let range = Range(match.range(at: 1), in: response),
                       let index = Int(String(response[range])),
                       index > 0 && index <= candidates.count {
                        foundIDs.append(candidates[index - 1].id)
                    }
                }
            }
        }

        return foundIDs
    }
}
