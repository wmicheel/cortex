//
//  MarkdownParser.swift
//  Cortex
//
//  Created by Claude Code
//

import Foundation

/// Parser for converting markdown text into content blocks
@MainActor
final class MarkdownParser {
    // MARK: - Parse Markdown to Blocks

    /// Parse markdown string into content blocks
    func parse(markdown: String, for entryID: UUID) -> [ContentBlock] {
        let lines = markdown.components(separatedBy: .newlines)
        var blocks: [ContentBlock] = []
        var currentOrder = 0

        var i = 0
        while i < lines.count {
            let line = lines[i]

            // Skip empty lines
            guard !line.trimmingCharacters(in: .whitespaces).isEmpty else {
                i += 1
                continue
            }

            // Parse line into block
            if let block = parseLine(line, order: currentOrder, entryID: entryID, lines: lines, index: &i) {
                blocks.append(block)
                currentOrder += 1
            }

            i += 1
        }

        // If no blocks were created, create a single text block
        if blocks.isEmpty {
            blocks.append(ContentBlock(
                type: .text,
                content: markdown,
                order: 0,
                entryID: entryID
            ))
        }

        return blocks
    }

    // MARK: - Parse Individual Lines

    private func parseLine(
        _ line: String,
        order: Int,
        entryID: UUID,
        lines: [String],
        index: inout Int
    ) -> ContentBlock? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        // Heading 1-6
        if trimmed.hasPrefix("#") {
            return parseHeading(trimmed, order: order, entryID: entryID)
        }

        // Code block
        if trimmed.hasPrefix("```") {
            return parseCodeBlock(lines: lines, startIndex: &index, order: order, entryID: entryID)
        }

        // Bullet list
        if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
            return parseBulletList(trimmed, order: order, entryID: entryID)
        }

        // Numbered list
        if let match = trimmed.range(of: #"^\d+\.\s"#, options: .regularExpression) {
            let content = String(trimmed[match.upperBound...])
            return ContentBlock(type: .numberedList, content: content, order: order, entryID: entryID)
        }

        // Checklist
        if trimmed.hasPrefix("- [ ]") || trimmed.hasPrefix("- [x]") || trimmed.hasPrefix("- [X]") {
            return parseChecklist(trimmed, order: order, entryID: entryID)
        }

        // Quote
        if trimmed.hasPrefix("> ") {
            let content = String(trimmed.dropFirst(2))
            return ContentBlock(type: .quote, content: content, order: order, entryID: entryID)
        }

        // Divider
        if trimmed == "---" || trimmed == "***" || trimmed == "___" {
            return ContentBlock(type: .divider, content: "", order: order, entryID: entryID)
        }

        // Default: text block
        return ContentBlock(type: .text, content: trimmed, order: order, entryID: entryID)
    }

    // MARK: - Specialized Parsers

    private func parseHeading(_ line: String, order: Int, entryID: UUID) -> ContentBlock {
        var level = 0
        var content = line

        // Count heading level
        for char in line {
            if char == "#" {
                level += 1
            } else {
                break
            }
        }

        // Extract content after #
        content = String(line.dropFirst(level)).trimmingCharacters(in: .whitespaces)

        // Determine block type
        let type: BlockType
        switch level {
        case 1: type = .heading1
        case 2: type = .heading2
        case 3: type = .heading3
        case 4: type = .heading4
        case 5: type = .heading5
        case 6: type = .heading6
        default: type = .text
        }

        return ContentBlock(type: type, content: content, order: order, entryID: entryID)
    }

    private func parseCodeBlock(lines: [String], startIndex: inout Int, order: Int, entryID: UUID) -> ContentBlock {
        let startLine = lines[startIndex]
        var language: String?

        // Extract language if specified
        let langStart = startLine.dropFirst(3).trimmingCharacters(in: .whitespaces)
        if !langStart.isEmpty {
            language = langStart
        }

        // Collect code content until closing ```
        var codeLines: [String] = []
        startIndex += 1

        while startIndex < lines.count {
            let line = lines[startIndex]
            if line.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                break
            }
            codeLines.append(line)
            startIndex += 1
        }

        let content = codeLines.joined(separator: "\n")

        var metadata = BlockMetadata()
        metadata.language = language

        return ContentBlock(
            type: .code,
            content: content,
            metadata: metadata,
            order: order,
            entryID: entryID
        )
    }

    private func parseBulletList(_ line: String, order: Int, entryID: UUID) -> ContentBlock {
        // Remove "- " or "* " prefix
        var content = line
        if line.hasPrefix("- ") {
            content = String(line.dropFirst(2))
        } else if line.hasPrefix("* ") {
            content = String(line.dropFirst(2))
        }

        return ContentBlock(type: .bulletList, content: content, order: order, entryID: entryID)
    }

    private func parseChecklist(_ line: String, order: Int, entryID: UUID) -> ContentBlock {
        let isChecked = line.contains("[x]") || line.contains("[X]")

        // Remove "- [ ] " or "- [x] " prefix
        var content = line
        if let range = content.range(of: #"^-\s\[[xX\s]\]\s"#, options: .regularExpression) {
            content = String(content[range.upperBound...])
        }

        var metadata = BlockMetadata()
        metadata.isChecked = isChecked

        return ContentBlock(
            type: .checkList,
            content: content,
            metadata: metadata,
            order: order,
            entryID: entryID
        )
    }
}
