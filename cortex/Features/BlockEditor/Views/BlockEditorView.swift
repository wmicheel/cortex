//
//  BlockEditorView.swift
//  Cortex
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData

/// Main block-based editor view
struct BlockEditorView: View {
    // MARK: - Properties

    @Bindable var entry: KnowledgeEntry
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel: BlockEditorViewModel?
    @FocusState private var focusedBlockID: UUID?

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                if let viewModel = viewModel {
                    ForEach(viewModel.blocks) { block in
                        BlockRow(
                            block: block,
                            isFocused: focusedBlockID == block.id,
                            viewModel: viewModel
                        )
                        .focused($focusedBlockID, equals: block.id)
                        .id(block.id)
                        .draggable(block.id.uuidString)
                        .dropDestination(for: String.self) { items, location in
                            guard let draggedIDString = items.first,
                                  let draggedID = UUID(uuidString: draggedIDString) else {
                                return false
                            }
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                viewModel.moveBlock(withID: draggedID, before: block.id)
                            }
                            return true
                        }
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                    }

                    // Add block button
                    Button(action: {
                        if let lastBlock = viewModel.blocks.last {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                viewModel.addBlockAfter(lastBlock)
                            }
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.body)
                            Text("Neuer Block")
                                .font(.body)
                        }
                        .foregroundColor(.accentColor)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.accentColor.opacity(0.05))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5, 3]))
                                .foregroundColor(Color.accentColor.opacity(0.2))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel?.blocks.count)
        }
        .onAppear {
            setupViewModel()
        }
    }

    // MARK: - Setup

    private func setupViewModel() {
        if viewModel == nil {
            viewModel = BlockEditorViewModel(entry: entry, modelContext: modelContext)
        }
    }
}

// MARK: - Block Row

private struct BlockRow: View {
    @Bindable var block: ContentBlock
    let isFocused: Bool
    @Bindable var viewModel: BlockEditorViewModel

    @State private var text: String = ""
    @State private var showingMenu = false
    @State private var showSlashMenu = false
    @State private var slashMenuQuery = ""
    @State private var isHovered = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Block type indicator / drag handle
            Menu {
                ForEach(BlockType.allCases) { type in
                    Button(action: {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            viewModel.convertBlock(block, to: type)
                        }
                    }) {
                        Label(type.displayName, systemImage: type.icon)
                    }
                }

                Divider()

                Button(role: .destructive, action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.deleteBlock(block)
                    }
                }) {
                    Label("Löschen", systemImage: "trash")
                }
            } label: {
                ZStack {
                    // Drag handle background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isHovered || isFocused ? Color.accentColor.opacity(0.1) : Color.clear)
                        .frame(width: 28, height: 28)

                    Image(systemName: block.type.icon)
                        .foregroundColor(isFocused ? .accentColor : .secondary)
                        .font(.system(size: 14))
                }
            }
            .menuStyle(.borderlessButton)
            .opacity(isHovered || isFocused ? 1.0 : 0.4)
            .animation(.easeInOut(duration: 0.15), value: isHovered)
            .animation(.easeInOut(duration: 0.15), value: isFocused)

            // Content editor
            VStack(alignment: .leading, spacing: 0) {
                blockContentView
            }

            Spacer()

            // Actions
            if isFocused || isHovered {
                HStack(spacing: 6) {
                    // Indent
                    Button(action: {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            viewModel.indentBlock(block)
                        }
                    }) {
                        Image(systemName: "increase.indent")
                            .font(.system(size: 13))
                            .frame(width: 24, height: 24)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(nsColor: .controlBackgroundColor))
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(block.indentLevel >= 6)
                    .opacity(block.indentLevel >= 6 ? 0.4 : 1.0)

                    // Outdent
                    Button(action: {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            viewModel.outdentBlock(block)
                        }
                    }) {
                        Image(systemName: "decrease.indent")
                            .font(.system(size: 13))
                            .frame(width: 24, height: 24)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(nsColor: .controlBackgroundColor))
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(block.indentLevel == 0)
                    .opacity(block.indentLevel == 0 ? 0.4 : 1.0)
                }
                .foregroundColor(.secondary)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.leading, CGFloat(block.indentLevel) * 28)
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isFocused ? Color.accentColor.opacity(0.08) : (isHovered ? Color(nsColor: .controlBackgroundColor) : Color.clear))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    isFocused ? Color.accentColor.opacity(0.3) : Color.clear,
                    lineWidth: 1.5
                )
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .onAppear {
            text = block.content
        }
    }

    @ViewBuilder
    private var blockContentView: some View {
        switch block.type {
        case .text, .heading1, .heading2, .heading3, .heading4, .heading5, .heading6:
            ZStack(alignment: .topLeading) {
                TextField(block.type.placeholder, text: $text, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(fontForBlock)
                    .lineLimit(1...20)
                    .onChange(of: text) { oldValue, newValue in
                        handleTextChange(oldValue: oldValue, newValue: newValue)
                    }
                    .onSubmit {
                        viewModel.addBlockAfter(block)
                    }

                // Slash menu overlay
                if showSlashMenu {
                    VStack {
                        Spacer().frame(height: 24)
                        SlashMenuView(
                            searchQuery: slashMenuQuery,
                            onSelect: { blockType in
                                convertToBlockType(blockType)
                            },
                            onDismiss: {
                                showSlashMenu = false
                            }
                        )
                        Spacer()
                    }
                    .zIndex(1000)
                }
            }

        case .bulletList, .numberedList:
            HStack(alignment: .top, spacing: 8) {
                Text(block.type == .bulletList ? "•" : "1.")
                    .foregroundColor(.secondary)

                TextField(block.type.placeholder, text: $text, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...20)
                    .onChange(of: text) { _, newValue in
                        viewModel.updateBlockContent(block, content: newValue)
                    }
                    .onSubmit {
                        viewModel.addBlockAfter(block, type: block.type)
                    }
            }

        case .checkList:
            HStack(alignment: .top, spacing: 8) {
                Button(action: {
                    block.isChecked.toggle()
                }) {
                    Image(systemName: block.isChecked ? "checkmark.square.fill" : "square")
                        .foregroundColor(block.isChecked ? .blue : .secondary)
                }
                .buttonStyle(.plain)

                TextField(block.type.placeholder, text: $text, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...20)
                    .strikethrough(block.isChecked)
                    .foregroundColor(block.isChecked ? .secondary : .primary)
                    .onChange(of: text) { _, newValue in
                        viewModel.updateBlockContent(block, content: newValue)
                    }
                    .onSubmit {
                        viewModel.addBlockAfter(block, type: .checkList)
                    }
            }

        case .code:
            VStack(alignment: .leading, spacing: 4) {
                // Language selector
                HStack {
                    Menu {
                        ForEach(["swift", "python", "javascript", "json", "markdown"], id: \.self) { lang in
                            Button(lang.capitalized) {
                                block.language = lang
                            }
                        }
                    } label: {
                        Text(block.language?.capitalized ?? "Code")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .menuStyle(.borderlessButton)

                    Spacer()
                }

                TextEditor(text: $text)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 60)
                    .padding(8)
                    .background(Color(.textBackgroundColor).opacity(0.5))
                    .cornerRadius(6)
                    .onChange(of: text) { _, newValue in
                        viewModel.updateBlockContent(block, content: newValue)
                    }
            }

        case .quote:
            HStack(alignment: .top, spacing: 12) {
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: 4)

                TextField(block.type.placeholder, text: $text, axis: .vertical)
                    .textFieldStyle(.plain)
                    .italic()
                    .lineLimit(1...20)
                    .onChange(of: text) { _, newValue in
                        viewModel.updateBlockContent(block, content: newValue)
                    }
                    .onSubmit {
                        viewModel.addBlockAfter(block)
                    }
            }

        case .divider:
            Divider()
                .padding(.vertical, 8)

        case .callout:
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: block.calloutIcon ?? "info.circle")
                    .foregroundColor(.blue)

                TextField(block.type.placeholder, text: $text, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...20)
                    .onChange(of: text) { _, newValue in
                        viewModel.updateBlockContent(block, content: newValue)
                    }
            }
            .padding(12)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)

        default:
            TextField(block.type.placeholder, text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .onChange(of: text) { _, newValue in
                    viewModel.updateBlockContent(block, content: newValue)
                }
        }
    }

    private var fontForBlock: Font {
        switch block.type {
        case .heading1: return .system(size: 32, weight: .bold)
        case .heading2: return .system(size: 28, weight: .bold)
        case .heading3: return .system(size: 24, weight: .semibold)
        case .heading4: return .system(size: 20, weight: .semibold)
        case .heading5: return .system(size: 18, weight: .medium)
        case .heading6: return .system(size: 16, weight: .medium)
        default: return .body
        }
    }

    // MARK: - Text Handling

    private func handleTextChange(oldValue: String, newValue: String) {
        // Update block content
        viewModel.updateBlockContent(block, content: newValue)

        // Check for slash menu trigger
        if newValue.hasPrefix("/") && !oldValue.hasPrefix("/") {
            showSlashMenu = true
            slashMenuQuery = String(newValue.dropFirst())
        } else if newValue.hasPrefix("/") {
            slashMenuQuery = String(newValue.dropFirst())
        } else if showSlashMenu {
            showSlashMenu = false
            slashMenuQuery = ""
        }

        // Markdown auto-formatting (only if not showing slash menu)
        if !showSlashMenu && !newValue.isEmpty {
            applyMarkdownFormatting(newValue)
        }
    }

    private func applyMarkdownFormatting(_ text: String) {
        // Only apply at start of line
        guard text.count >= 2 else { return }

        // Heading patterns
        if text.hasPrefix("# ") && block.type != .heading1 {
            convertToBlockType(.heading1)
            self.text = String(text.dropFirst(2))
        } else if text.hasPrefix("## ") && block.type != .heading2 {
            convertToBlockType(.heading2)
            self.text = String(text.dropFirst(3))
        } else if text.hasPrefix("### ") && block.type != .heading3 {
            convertToBlockType(.heading3)
            self.text = String(text.dropFirst(4))
        }
        // Bulleted list
        else if (text.hasPrefix("- ") || text.hasPrefix("* ")) && block.type != .bulletList {
            convertToBlockType(.bulletList)
            self.text = String(text.dropFirst(2))
        }
        // Numbered list
        else if text.range(of: "^\\d+\\. ", options: .regularExpression) != nil && block.type != .numberedList {
            convertToBlockType(.numberedList)
            if let spaceIndex = text.firstIndex(of: " ") {
                self.text = String(text[text.index(after: spaceIndex)...])
            }
        }
        // Quote
        else if text.hasPrefix("> ") && block.type != .quote {
            convertToBlockType(.quote)
            self.text = String(text.dropFirst(2))
        }
        // Code block
        else if text.hasPrefix("```") && block.type != .code {
            convertToBlockType(.code)
            self.text = String(text.dropFirst(3))
        }
        // Checkbox
        else if (text.hasPrefix("[ ] ") || text.hasPrefix("[x] ")) && block.type != .checkList {
            convertToBlockType(.checkList)
            if text.hasPrefix("[x] ") {
                block.isChecked = true
            }
            self.text = String(text.dropFirst(4))
        }
        // Divider
        else if (text == "---" || text == "***") && block.type != .divider {
            convertToBlockType(.divider)
            self.text = ""
        }
    }

    private func convertToBlockType(_ type: BlockType) {
        viewModel.convertBlock(block, to: type)
        showSlashMenu = false
        slashMenuQuery = ""
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: KnowledgeEntry.self, ContentBlock.self, configurations: config)

    let entry = KnowledgeEntry(
        title: "Test Entry",
        content: "Test content",
        isBlockBased: true
    )
    container.mainContext.insert(entry)

    return BlockEditorView(entry: entry)
        .modelContainer(container)
        .frame(width: 800, height: 600)
}
