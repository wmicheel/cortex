//
//  ContentBlock.swift
//  Cortex
//
//  Created by Claude Code
//

import Foundation
@preconcurrency import SwiftData

/// A single content block in the block-based editor
@Model
final class ContentBlock {
    // MARK: - Properties

    /// Unique identifier
    @Attribute(.unique) var id: UUID

    /// Block type (stored as raw string)
    var typeRawValue: String

    /// Text content (for text-based blocks)
    var content: String

    /// Order within parent or document
    var order: Int

    /// Parent block ID (for nested blocks)
    var parentID: UUID?

    /// Timestamp when created
    var createdAt: Date

    /// Timestamp when last modified
    var modifiedAt: Date

    /// Reference to owning knowledge entry
    var entryID: UUID

    // Metadata stored as simple properties for compatibility
    var language: String?
    var showLineNumbers: Bool = false
    var calloutIcon: String?
    var calloutColor: String?
    var isExpanded: Bool = true
    var isChecked: Bool = false
    var imageURL: String?
    var imageCaption: String?
    var imageWidth: Double?
    var imageHeight: Double?
    var columnCount: Int?
    var rowCount: Int?
    var headerRow: Bool = true
    var indentLevel: Int = 0

    // MARK: - Computed Properties

    /// Block type
    var type: BlockType {
        get { BlockType(rawValue: typeRawValue) ?? .text }
        set { typeRawValue = newValue.rawValue }
    }

    /// Is this a top-level block?
    var isTopLevel: Bool {
        parentID == nil
    }

    /// Plain text content (without formatting)
    var plainText: String {
        content
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        type: BlockType,
        content: String = "",
        formattedRanges: [FormattedRange] = [],
        metadata: BlockMetadata = BlockMetadata(),
        order: Int = 0,
        parentID: UUID? = nil,
        entryID: UUID
    ) {
        self.id = id
        self.typeRawValue = type.rawValue
        self.content = content
        self.order = order
        self.parentID = parentID
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.entryID = entryID

        // Copy metadata fields
        self.language = metadata.language
        self.showLineNumbers = metadata.showLineNumbers
        self.calloutIcon = metadata.calloutIcon
        self.calloutColor = metadata.calloutColor
        self.isExpanded = metadata.isExpanded
        self.isChecked = metadata.isChecked
        self.imageURL = metadata.imageURL
        self.imageCaption = metadata.imageCaption
        self.imageWidth = metadata.imageWidth
        self.imageHeight = metadata.imageHeight
        self.columnCount = metadata.columnCount
        self.rowCount = metadata.rowCount
        self.headerRow = metadata.headerRow
        self.indentLevel = metadata.indentLevel
    }

    // MARK: - Helper Methods

    /// Get current metadata as BlockMetadata struct
    func getMetadata() -> BlockMetadata {
        var metadata = BlockMetadata()
        metadata.language = language
        metadata.showLineNumbers = showLineNumbers
        metadata.calloutIcon = calloutIcon
        metadata.calloutColor = calloutColor
        metadata.isExpanded = isExpanded
        metadata.isChecked = isChecked
        metadata.imageURL = imageURL
        metadata.imageCaption = imageCaption
        metadata.imageWidth = imageWidth
        metadata.imageHeight = imageHeight
        metadata.columnCount = columnCount
        metadata.rowCount = rowCount
        metadata.headerRow = headerRow
        metadata.indentLevel = indentLevel
        return metadata
    }

    /// Update metadata from BlockMetadata struct
    func setMetadata(_ metadata: BlockMetadata) {
        language = metadata.language
        showLineNumbers = metadata.showLineNumbers
        calloutIcon = metadata.calloutIcon
        calloutColor = metadata.calloutColor
        isExpanded = metadata.isExpanded
        isChecked = metadata.isChecked
        imageURL = metadata.imageURL
        imageCaption = metadata.imageCaption
        imageWidth = metadata.imageWidth
        imageHeight = metadata.imageHeight
        columnCount = metadata.columnCount
        rowCount = metadata.rowCount
        headerRow = metadata.headerRow
        indentLevel = metadata.indentLevel
        modifiedAt = Date()
    }

    // MARK: - Methods

    /// Update content and mark as modified
    func updateContent(_ newContent: String) {
        content = newContent
        modifiedAt = Date()
    }

    /// Convert block type
    func convertTo(type: BlockType) {
        self.type = type

        // Adjust metadata based on new type
        switch type {
        case .code:
            if language == nil {
                language = "swift"
            }
        case .callout:
            if calloutIcon == nil {
                calloutIcon = "info.circle"
            }
        case .checkList:
            isChecked = false
        default:
            break
        }

        modifiedAt = Date()
    }

    /// Increase indent level
    func indent() {
        guard indentLevel < 6 else { return }
        indentLevel += 1
        modifiedAt = Date()
    }

    /// Decrease indent level
    func outdent() {
        guard indentLevel > 0 else { return }
        indentLevel -= 1
        modifiedAt = Date()
    }

    /// Export to markdown
    func toMarkdown() -> String {
        var markdown = ""

        // Add markdown prefix based on type
        switch type {
        case .heading1:
            markdown = "# \(content)"
        case .heading2:
            markdown = "## \(content)"
        case .heading3:
            markdown = "### \(content)"
        case .heading4:
            markdown = "#### \(content)"
        case .heading5:
            markdown = "##### \(content)"
        case .heading6:
            markdown = "###### \(content)"
        case .bulletList:
            markdown = "- \(content)"
        case .numberedList:
            markdown = "1. \(content)"
        case .checkList:
            markdown = isChecked ? "- [x] \(content)" : "- [ ] \(content)"
        case .quote:
            markdown = "> \(content)"
        case .code:
            let lang = language ?? ""
            markdown = "```\(lang)\n\(content)\n```"
        case .divider:
            markdown = "---"
        case .callout:
            markdown = "> **💡 \(content)**"
        default:
            markdown = content
        }

        // Add indentation
        if indentLevel > 0 {
            let indent = String(repeating: "  ", count: indentLevel)
            markdown = indent + markdown
        }

        return markdown
    }
}
