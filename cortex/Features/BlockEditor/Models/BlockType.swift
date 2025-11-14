//
//  BlockType.swift
//  Cortex
//
//  Created by Claude Code
//

import Foundation

/// Types of content blocks available in the editor
enum BlockType: String, Codable, CaseIterable, Identifiable {
    // MARK: - Basic Text Blocks
    case text
    case heading1
    case heading2
    case heading3
    case heading4
    case heading5
    case heading6

    // MARK: - List Blocks
    case bulletList
    case numberedList
    case checkList

    // MARK: - Code & Quote
    case code
    case quote

    // MARK: - Visual Elements
    case divider
    case callout
    case toggle

    // MARK: - Media
    case image
    case file

    // MARK: - Advanced
    case table

    // MARK: - Identifiable
    var id: String { rawValue }

    // MARK: - Display Properties

    var displayName: String {
        switch self {
        case .text: return "Text"
        case .heading1: return "Heading 1"
        case .heading2: return "Heading 2"
        case .heading3: return "Heading 3"
        case .heading4: return "Heading 4"
        case .heading5: return "Heading 5"
        case .heading6: return "Heading 6"
        case .bulletList: return "Bullet List"
        case .numberedList: return "Numbered List"
        case .checkList: return "Checklist"
        case .code: return "Code"
        case .quote: return "Quote"
        case .divider: return "Divider"
        case .callout: return "Callout"
        case .toggle: return "Toggle"
        case .image: return "Image"
        case .file: return "File"
        case .table: return "Table"
        }
    }

    var icon: String {
        switch self {
        case .text: return "text.alignleft"
        case .heading1: return "textformat.size.larger"
        case .heading2: return "textformat.size.larger"
        case .heading3: return "textformat.size"
        case .heading4: return "textformat.size"
        case .heading5: return "textformat.size.smaller"
        case .heading6: return "textformat.size.smaller"
        case .bulletList: return "list.bullet"
        case .numberedList: return "list.number"
        case .checkList: return "checklist"
        case .code: return "chevron.left.forwardslash.chevron.right"
        case .quote: return "quote.opening"
        case .divider: return "minus"
        case .callout: return "exclamationmark.bubble"
        case .toggle: return "chevron.right"
        case .image: return "photo"
        case .file: return "doc"
        case .table: return "tablecells"
        }
    }

    var category: BlockCategory {
        switch self {
        case .text, .heading1, .heading2, .heading3, .heading4, .heading5, .heading6:
            return .basic
        case .bulletList, .numberedList, .checkList:
            return .lists
        case .code, .quote, .callout:
            return .formatting
        case .image, .file:
            return .media
        case .divider, .toggle, .table:
            return .advanced
        }
    }

    var placeholder: String {
        switch self {
        case .text: return "Type '/' for commands..."
        case .heading1: return "Heading 1"
        case .heading2: return "Heading 2"
        case .heading3: return "Heading 3"
        case .heading4: return "Heading 4"
        case .heading5: return "Heading 5"
        case .heading6: return "Heading 6"
        case .bulletList: return "List item"
        case .numberedList: return "List item"
        case .checkList: return "To-do"
        case .code: return "Code..."
        case .quote: return "Quote..."
        case .divider: return ""
        case .callout: return "Callout text..."
        case .toggle: return "Toggle heading..."
        case .image: return "Add image..."
        case .file: return "Add file..."
        case .table: return "Table..."
        }
    }

    /// Can this block type have children (nested blocks)?
    var supportsNesting: Bool {
        switch self {
        case .quote, .callout, .toggle, .bulletList, .numberedList, .checkList:
            return true
        default:
            return false
        }
    }

    /// Does this block type support inline formatting?
    var supportsInlineFormatting: Bool {
        switch self {
        case .text, .heading1, .heading2, .heading3, .heading4, .heading5, .heading6,
             .bulletList, .numberedList, .checkList, .quote, .callout, .toggle:
            return true
        case .code, .divider, .image, .file, .table:
            return false
        }
    }
}

/// Block categories for organization in slash menu
enum BlockCategory: String, Codable {
    case basic
    case lists
    case formatting
    case media
    case advanced

    var displayName: String {
        switch self {
        case .basic: return "Basic Blocks"
        case .lists: return "Lists"
        case .formatting: return "Formatting"
        case .media: return "Media"
        case .advanced: return "Advanced"
        }
    }
}
