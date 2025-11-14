//
//  TagExtractionService.swift
//  Cortex
//
//  Created by Claude Code
//

import Foundation
import NaturalLanguage

/// Service for extracting relevant tags from text using NaturalLanguage framework
actor TagExtractionService {
    // MARK: - Properties

    private let tagger: NLTagger
    private let stopWords: Set<String>

    // MARK: - Initialization

    init() {
        // Configure tagger for named entity recognition and lexical analysis
        self.tagger = NLTagger(tagSchemes: [.nameType, .lexicalClass, .language])
        self.stopWords = StopWords.combined
    }

    // MARK: - Public Methods

    /// Extract relevant tags from title and content
    /// - Parameters:
    ///   - title: Entry title
    ///   - content: Entry content
    ///   - limit: Maximum number of tags to return
    /// - Returns: Array of suggested tags
    func suggestTags(title: String, content: String, limit: Int = 8) async -> [String] {
        let combinedText = "\(title) \(content)"

        // Extract different types of tags
        let namedEntities = await extractNamedEntities(from: combinedText)
        let keywords = await extractKeywords(from: combinedText)

        // Combine and deduplicate
        var allTags = Set<String>()
        allTags.formUnion(namedEntities)
        allTags.formUnion(keywords)

        // Filter out stop words and short words
        let filteredTags = allTags
            .filter { tag in
                let lowercased = tag.lowercased()
                return !stopWords.contains(lowercased) && tag.count > 2
            }

        // Sort by frequency in text (most common first)
        let sortedTags = filteredTags.sorted { tag1, tag2 in
            let count1 = combinedText.lowercased().components(separatedBy: tag1.lowercased()).count - 1
            let count2 = combinedText.lowercased().components(separatedBy: tag2.lowercased()).count - 1
            return count1 > count2
        }

        return Array(sortedTags.prefix(limit))
    }

    // MARK: - Private Methods

    /// Extract named entities (people, places, organizations)
    private func extractNamedEntities(from text: String) async -> [String] {
        guard !text.isEmpty else { return [] }

        var entities: [String] = []

        tagger.string = text

        // Detect language
        if let language = tagger.dominantLanguage {
            tagger.setLanguage(language, range: text.startIndex..<text.endIndex)
        }

        // Extract named entities
        tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                           unit: .word,
                           scheme: .nameType,
                           options: [.omitWhitespace, .omitPunctuation]) { tag, tokenRange in
            if let tag = tag {
                let entity = String(text[tokenRange])

                // Only include meaningful named entities
                switch tag {
                case .personalName, .placeName, .organizationName:
                    entities.append(entity)
                default:
                    break
                }
            }
            return true
        }

        return entities
    }

    /// Extract keywords (primarily nouns and significant words)
    private func extractKeywords(from text: String) async -> [String] {
        guard !text.isEmpty else { return [] }

        var keywords: [String] = []

        tagger.string = text

        // Detect language
        if let language = tagger.dominantLanguage {
            tagger.setLanguage(language, range: text.startIndex..<text.endIndex)
        }

        // Extract nouns and proper nouns
        tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                           unit: .word,
                           scheme: .lexicalClass,
                           options: [.omitWhitespace, .omitPunctuation]) { tag, tokenRange in
            if let tag = tag {
                let word = String(text[tokenRange])

                // Only include nouns and proper nouns
                switch tag {
                case .noun, .otherWord:
                    // Filter: must be capitalized or longer than 4 characters
                    if word.first?.isUppercase == true || word.count > 4 {
                        keywords.append(word)
                    }
                default:
                    break
                }
            }
            return true
        }

        return keywords
    }
}
