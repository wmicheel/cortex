//
//  BlockFormatting.swift
//  Cortex
//
//  Created by Claude Code
//

import Foundation
import SwiftUI

/// Inline text formatting options
struct InlineFormatting: Codable, Equatable, Sendable {
    var isBold: Bool = false
    var isItalic: Bool = false
    var isUnderline: Bool = false
    var isStrikethrough: Bool = false
    var isCode: Bool = false
    var textColor: String?  // Hex color
    var backgroundColor: String?  // Hex color
    var link: String?  // URL

    /// Create formatting from markdown markers
    static func from(markdown: String) -> InlineFormatting {
        var formatting = InlineFormatting()

        if markdown.hasPrefix("**") && markdown.hasSuffix("**") {
            formatting.isBold = true
        }
        if markdown.hasPrefix("*") && markdown.hasSuffix("*") {
            formatting.isItalic = true
        }
        if markdown.hasPrefix("`") && markdown.hasSuffix("`") {
            formatting.isCode = true
        }
        if markdown.hasPrefix("~~") && markdown.hasSuffix("~~") {
            formatting.isStrikethrough = true
        }

        return formatting
    }

    /// Apply formatting to AttributedString
    func apply(to attributedString: inout AttributedString) {
        if isBold {
            attributedString.font = .system(.body, design: .default, weight: .bold)
        }
        if isItalic {
            attributedString.font = .system(.body).italic()
        }
        if isUnderline {
            attributedString.underlineStyle = .single
        }
        if isStrikethrough {
            attributedString.strikethroughStyle = .single
        }
        if isCode {
            attributedString.font = .system(.body, design: .monospaced)
            attributedString.backgroundColor = Color(.systemGray).opacity(0.2)
        }
        if let colorHex = textColor, let color = Color(hex: colorHex) {
            attributedString.foregroundColor = color
        }
        if let bgColorHex = backgroundColor, let bgColor = Color(hex: bgColorHex) {
            attributedString.backgroundColor = bgColor
        }
    }
}

/// Formatted text range with style information
struct FormattedRange: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let range: NSRange
    let formatting: InlineFormatting

    init(id: UUID = UUID(), range: NSRange, formatting: InlineFormatting) {
        self.id = id
        self.range = range
        self.formatting = formatting
    }
}

/// Block-level metadata for special block types
struct BlockMetadata: Codable, Equatable, Sendable {
    // Code block
    var language: String?  // e.g., "swift", "python", "javascript"
    var showLineNumbers: Bool = false

    // Callout
    var calloutIcon: String?  // SF Symbol name
    var calloutColor: String?  // Hex color

    // Toggle
    var isExpanded: Bool = true

    // Checklist
    var isChecked: Bool = false

    // Image
    var imageURL: String?
    var imageCaption: String?
    var imageWidth: Double?
    var imageHeight: Double?

    // Table
    var columnCount: Int?
    var rowCount: Int?
    var headerRow: Bool = true

    // Indentation/Nesting
    var indentLevel: Int = 0
}

// MARK: - Color Extension

extension Color {
    /// Initialize Color from hex string
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }

    /// Convert Color to hex string
    func toHex() -> String? {
        guard let components = NSColor(self).cgColor.components else { return nil }
        let r = Int(components[0] * 255.0)
        let g = Int(components[1] * 255.0)
        let b = Int(components[2] * 255.0)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
