//
//  MarkdownView.swift
//  Cortex
//
//  Created by Claude Code
//

import SwiftUI

/// View for rendering Markdown text
struct MarkdownView: View {
    let markdown: String

    var body: some View {
        if let attributedString = try? AttributedString(markdown: markdown) {
            Text(attributedString)
                .textSelection(.enabled)
        } else {
            Text(markdown)
                .textSelection(.enabled)
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(alignment: .leading, spacing: 16) {
            MarkdownView(markdown: """
            # Heading 1
            ## Heading 2
            ### Heading 3

            This is **bold** and this is *italic*.

            Here's a list:
            - Item 1
            - Item 2
            - Item 3

            And a numbered list:
            1. First
            2. Second
            3. Third

            > This is a quote

            `Inline code` looks like this.

            ```swift
            func hello() {
                print("Hello, World!")
            }
            ```

            [Link to Apple](https://apple.com)
            """)
        }
        .padding()
    }
}
