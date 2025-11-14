//
//  StopWords.swift
//  Cortex
//
//  Created by Claude Code
//

import Foundation

/// Common stop words in German and English to filter from auto-tagging
enum StopWords {
    // MARK: - German Stop Words

    nonisolated(unsafe) static let german: Set<String> = [
        // Articles
        "der", "die", "das", "den", "dem", "des",
        "ein", "eine", "einer", "einen", "einem", "eines",

        // Pronouns
        "ich", "du", "er", "sie", "es", "wir", "ihr",
        "mich", "dich", "sich", "uns", "euch",
        "mir", "dir", "ihm", "ihr", "ihnen",
        "mein", "dein", "sein", "unser", "euer",

        // Prepositions
        "in", "an", "auf", "aus", "bei", "mit", "nach", "von", "zu", "um",
        "über", "unter", "vor", "hinter", "neben", "zwischen", "durch",

        // Conjunctions
        "und", "oder", "aber", "denn", "sondern", "wenn", "weil", "dass", "ob",
        "als", "wie", "damit", "obwohl", "während", "bevor", "nachdem",

        // Auxiliary verbs
        "sein", "haben", "werden", "können", "müssen", "dürfen", "sollen", "wollen", "mögen",
        "ist", "sind", "war", "waren", "hat", "hatte", "wird", "wurde", "kann", "muss",

        // Common words
        "nicht", "auch", "nur", "noch", "schon", "sehr", "mehr", "weniger",
        "alle", "jeder", "keine", "nichts", "etwas", "viel", "wenig",
        "hier", "da", "dort", "heute", "morgen", "gestern",
        "ja", "nein", "doch", "mal", "wohl"
    ]

    // MARK: - English Stop Words

    nonisolated(unsafe) static let english: Set<String> = [
        // Articles
        "a", "an", "the",

        // Pronouns
        "i", "you", "he", "she", "it", "we", "they",
        "me", "him", "her", "us", "them",
        "my", "your", "his", "her", "its", "our", "their",
        "mine", "yours", "hers", "ours", "theirs",
        "this", "that", "these", "those",

        // Prepositions
        "in", "on", "at", "to", "for", "with", "from", "of", "by", "about",
        "as", "into", "through", "over", "under", "above", "below", "between",

        // Conjunctions
        "and", "or", "but", "so", "yet", "nor", "for",
        "if", "when", "where", "while", "because", "although", "unless",

        // Auxiliary verbs
        "be", "is", "am", "are", "was", "were", "been", "being",
        "have", "has", "had", "having",
        "do", "does", "did", "doing",
        "can", "could", "may", "might", "must", "shall", "should", "will", "would",

        // Common words
        "not", "no", "yes", "also", "only", "just", "very", "more", "less",
        "all", "any", "some", "none", "every", "each", "both", "few", "many",
        "here", "there", "now", "then", "today", "tomorrow", "yesterday",
        "well", "still", "even", "much"
    ]

    // MARK: - Combined

    /// Combined set of German and English stop words
    nonisolated(unsafe) static let combined: Set<String> = german.union(english)
}
