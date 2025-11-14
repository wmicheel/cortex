//
//  EmbeddingService.swift
//  Cortex
//
//  Created by Claude Code
//

import Foundation

/// Service for generating embeddings using OpenAI API
actor EmbeddingService {
    // MARK: - Singleton

    static let shared = EmbeddingService()

    // MARK: - Properties

    private let baseURL = "https://api.openai.com/v1/embeddings"
    private let model = "text-embedding-3-small" // 1536 dimensions, cost-effective
    private let session: URLSession

    // MARK: - Models

    struct EmbeddingRequest: Codable {
        let input: String
        let model: String
        let encoding_format: String = "float"
    }

    struct EmbeddingResponse: Codable {
        let object: String
        let data: [EmbeddingData]
        let model: String
        let usage: Usage

        struct EmbeddingData: Codable {
            let object: String
            let embedding: [Double]
            let index: Int
        }

        struct Usage: Codable {
            let prompt_tokens: Int
            let total_tokens: Int
        }
    }

    // MARK: - Initialization

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: config)
    }

    // MARK: - Public Methods

    /// Generate embedding for a single text
    func generateEmbedding(for text: String) async throws -> [Double] {
        guard !text.isEmpty else {
            throw CortexError.invalidData
        }

        // Get API key from Keychain
        guard let apiKey = try await KeychainManager.shared.get(key: "openai_api_key") else {
            throw CortexError.openAINotConfigured
        }

        // Prepare request
        let requestBody = EmbeddingRequest(
            input: text,
            model: model
        )

        guard let url = URL(string: baseURL) else {
            throw CortexError.invalidData
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(requestBody)

        // Make request
        let (data, response) = try await session.data(for: request)

        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CortexError.openAIRequestFailed(message: "Invalid response")
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw CortexError.openAIRequestFailed(message: "HTTP \(httpResponse.statusCode): \(errorMessage)")
        }

        // Parse response
        let decoder = JSONDecoder()
        let embeddingResponse = try decoder.decode(EmbeddingResponse.self, from: data)

        guard let embeddingData = embeddingResponse.data.first else {
            throw CortexError.openAIInvalidResponse
        }

        print("✅ Generated embedding: \(embeddingData.embedding.count) dimensions, \(embeddingResponse.usage.total_tokens) tokens used")

        return embeddingData.embedding
    }

    /// Generate embedding for a knowledge entry (title + content)
    func generateEmbedding(for entry: KnowledgeEntry) async throws -> [Double] {
        // Combine title and content for richer semantic representation
        let text = "\(entry.title)\n\n\(entry.getContentText())"

        // Truncate if too long (max ~8000 tokens for embedding model)
        let truncatedText = String(text.prefix(30000)) // Rough estimate: ~8000 tokens

        return try await generateEmbedding(for: truncatedText)
    }

    /// Generate embeddings for multiple entries (batched for efficiency)
    func generateEmbeddings(for entries: [KnowledgeEntry]) async throws -> [String: [Double]] {
        var results: [String: [Double]] = [:]

        // Process in batches to avoid rate limits
        let batchSize = 10
        let batches = stride(from: 0, to: entries.count, by: batchSize).map {
            Array(entries[$0..<min($0 + batchSize, entries.count)])
        }

        for batch in batches {
            // Process batch concurrently
            try await withThrowingTaskGroup(of: (String, [Double]).self) { group in
                for entry in batch {
                    group.addTask {
                        let embedding = try await self.generateEmbedding(for: entry)
                        return (entry.id, embedding)
                    }
                }

                for try await (id, embedding) in group {
                    results[id] = embedding
                }
            }

            // Small delay between batches to respect rate limits
            if batches.count > 1 {
                try await Task.sleep(for: .milliseconds(200))
            }
        }

        print("✅ Generated \(results.count) embeddings")

        return results
    }

    /// Calculate cosine similarity between two embedding vectors
    func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
        guard a.count == b.count, !a.isEmpty else { return 0.0 }

        var dotProduct = 0.0
        var magnitudeA = 0.0
        var magnitudeB = 0.0

        for i in 0..<a.count {
            dotProduct += a[i] * b[i]
            magnitudeA += a[i] * a[i]
            magnitudeB += b[i] * b[i]
        }

        let denominator = sqrt(magnitudeA) * sqrt(magnitudeB)
        guard denominator > 0 else { return 0.0 }

        return dotProduct / denominator
    }

    /// Find most similar entries to a query embedding
    func findSimilar(
        to queryEmbedding: [Double],
        in entries: [KnowledgeEntry],
        limit: Int = 10,
        threshold: Double = 0.5
    ) -> [(entry: KnowledgeEntry, similarity: Double)] {
        var results: [(KnowledgeEntry, Double)] = []

        for entry in entries {
            guard let embedding = entry.embedding else { continue }

            let similarity = cosineSimilarity(queryEmbedding, embedding)

            if similarity >= threshold {
                results.append((entry, similarity))
            }
        }

        // Sort by similarity (highest first) and limit
        return results
            .sorted { $0.1 > $1.1 }
            .prefix(limit)
            .map { $0 }
    }

    /// Search entries semantically by query text
    func search(
        query: String,
        in entries: [KnowledgeEntry],
        limit: Int = 10,
        threshold: Double = 0.5
    ) async throws -> [(entry: KnowledgeEntry, similarity: Double)] {
        // Generate embedding for query
        let queryEmbedding = try await generateEmbedding(for: query)

        // Find similar entries
        return findSimilar(
            to: queryEmbedding,
            in: entries,
            limit: limit,
            threshold: threshold
        )
    }
}
