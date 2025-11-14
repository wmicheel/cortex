//
//  FormattingToolbar.swift
//  Cortex
//
//  Formatting toolbar for block editor
//

import SwiftUI

/// Formatting toolbar for text formatting
struct FormattingToolbar: View {
    // MARK: - Properties

    @Binding var text: String
    let onFormatApplied: () -> Void

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            // Bold
            Button(action: {
                applyFormatting(prefix: "**", suffix: "**")
            }) {
                Image(systemName: "bold")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .keyboardShortcut("b", modifiers: .command)
            .help("Bold (⌘B)")

            // Italic
            Button(action: {
                applyFormatting(prefix: "_", suffix: "_")
            }) {
                Image(systemName: "italic")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .keyboardShortcut("i", modifiers: .command)
            .help("Italic (⌘I)")

            // Code
            Button(action: {
                applyFormatting(prefix: "`", suffix: "`")
            }) {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .keyboardShortcut("e", modifiers: .command)
            .help("Inline Code (⌘E)")

            Divider()
                .frame(height: 16)

            // Strikethrough
            Button(action: {
                applyFormatting(prefix: "~~", suffix: "~~")
            }) {
                Image(systemName: "strikethrough")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .keyboardShortcut("x", modifiers: [.command, .shift])
            .help("Strikethrough (⌘⇧X)")

            // Link
            Button(action: {
                applyFormatting(prefix: "[", suffix: "](url)")
            }) {
                Image(systemName: "link")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .keyboardShortcut("k", modifiers: .command)
            .help("Link (⌘K)")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(6)
    }

    // MARK: - Formatting

    private func applyFormatting(prefix: String, suffix: String) {
        // For now, just append the formatting markers
        // In a real implementation, we would need to:
        // 1. Get text selection
        // 2. Wrap selection with prefix/suffix
        // 3. Or insert prefix/suffix at cursor if no selection

        // Simple implementation: append to end
        if !text.isEmpty {
            text = prefix + text + suffix
        } else {
            text = prefix + "text" + suffix
        }

        onFormatApplied()
    }
}

// MARK: - Preview

#Preview {
    VStack {
        FormattingToolbar(text: .constant("Sample text")) {
            print("Format applied")
        }

        Spacer()
    }
    .padding()
    .frame(width: 400, height: 200)
}
