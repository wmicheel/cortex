//
//  SlashMenuView.swift
//  Cortex
//
//  Slash menu for quick block type selection
//

import SwiftUI

/// Menu item for slash menu
struct SlashMenuItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
    let blockType: BlockType
    let keywords: [String]
}

/// Slash menu view for block type selection
struct SlashMenuView: View {
    // MARK: - Properties

    let searchQuery: String
    let onSelect: (BlockType) -> Void
    let onDismiss: () -> Void

    @State private var selectedIndex = 0

    // MARK: - Menu Items

    private let menuItems: [SlashMenuItem] = [
        SlashMenuItem(
            icon: "text.alignleft",
            title: "Text",
            subtitle: "Plain text paragraph",
            blockType: .text,
            keywords: ["text", "paragraph", "p"]
        ),
        SlashMenuItem(
            icon: "textformat.size.larger",
            title: "Heading 1",
            subtitle: "Large section heading",
            blockType: .heading1,
            keywords: ["heading", "h1", "title", "large"]
        ),
        SlashMenuItem(
            icon: "textformat.size",
            title: "Heading 2",
            subtitle: "Medium section heading",
            blockType: .heading2,
            keywords: ["heading", "h2", "subtitle", "medium"]
        ),
        SlashMenuItem(
            icon: "textformat",
            title: "Heading 3",
            subtitle: "Small section heading",
            blockType: .heading3,
            keywords: ["heading", "h3", "small"]
        ),
        SlashMenuItem(
            icon: "list.bullet",
            title: "Bulleted List",
            subtitle: "Create a simple bulleted list",
            blockType: .bulletList,
            keywords: ["bullet", "list", "ul", "unordered"]
        ),
        SlashMenuItem(
            icon: "list.number",
            title: "Numbered List",
            subtitle: "Create a list with numbering",
            blockType: .numberedList,
            keywords: ["number", "list", "ol", "ordered"]
        ),
        SlashMenuItem(
            icon: "quote.opening",
            title: "Quote",
            subtitle: "Capture a quote",
            blockType: .quote,
            keywords: ["quote", "blockquote", "citation"]
        ),
        SlashMenuItem(
            icon: "chevron.left.forwardslash.chevron.right",
            title: "Code",
            subtitle: "Code block with syntax highlighting",
            blockType: .code,
            keywords: ["code", "pre", "programming"]
        ),
        SlashMenuItem(
            icon: "minus",
            title: "Divider",
            subtitle: "Horizontal divider line",
            blockType: .divider,
            keywords: ["divider", "separator", "line", "hr"]
        )
    ]

    // MARK: - Computed Properties

    private var filteredItems: [SlashMenuItem] {
        guard !searchQuery.isEmpty else {
            return menuItems
        }

        let query = searchQuery.lowercased()
        return menuItems.filter { item in
            item.title.lowercased().contains(query) ||
            item.subtitle.lowercased().contains(query) ||
            item.keywords.contains { $0.contains(query) }
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header
            if !searchQuery.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.accentColor)
                        .font(.caption)

                    Text("Searching for: \(searchQuery)")
                        .font(.caption)
                        .foregroundColor(.primary)

                    Spacer()

                    Text("\(filteredItems.count)")
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.accentColor.opacity(0.15))
                        )
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        colors: [Color.accentColor.opacity(0.08), Color.accentColor.opacity(0.03)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            Divider()

            // Menu items
            if filteredItems.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                            menuItemRow(item, isSelected: index == selectedIndex)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                        selectItem(item)
                                    }
                                }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(maxHeight: 320)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .windowBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.accentColor.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.15), radius: 20, y: 8)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
        .frame(width: 340)
        .transition(.scale(scale: 0.95).combined(with: .opacity))
        .onAppear {
            selectedIndex = 0
        }
        .onChange(of: searchQuery) { _, _ in
            withAnimation(.easeOut(duration: 0.15)) {
                selectedIndex = 0
            }
        }
    }

    // MARK: - Menu Item Row

    private func menuItemRow(_ item: SlashMenuItem, isSelected: Bool) -> some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                Circle()
                    .fill(isSelected ? Color.accentColor.opacity(0.15) : Color(nsColor: .controlBackgroundColor))
                    .frame(width: 36, height: 36)

                Image(systemName: item.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .accentColor : .secondary)
            }

            // Content
            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.system(.body, design: .rounded, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(.primary)

                Text(item.subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Keyboard hint
            if isSelected {
                HStack(spacing: 3) {
                    Text("↵")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.accentColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.accentColor.opacity(0.1))
                        )
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.08) : Color.clear)
        )
        .contentShape(Rectangle())
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.title)
                .foregroundColor(.secondary)

            Text("No blocks found")
                .font(.body)
                .foregroundColor(.secondary)

            Text("Try a different search term")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Actions

    func selectItem(_ item: SlashMenuItem) {
        onSelect(item.blockType)
    }

    func selectCurrentItem() {
        guard !filteredItems.isEmpty else { return }
        let index = min(selectedIndex, filteredItems.count - 1)
        selectItem(filteredItems[index])
    }

    func moveSelectionUp() {
        if selectedIndex > 0 {
            selectedIndex -= 1
        }
    }

    func moveSelectionDown() {
        if selectedIndex < filteredItems.count - 1 {
            selectedIndex += 1
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        SlashMenuView(
            searchQuery: "",
            onSelect: { _ in },
            onDismiss: { }
        )

        Spacer().frame(height: 20)

        SlashMenuView(
            searchQuery: "head",
            onSelect: { _ in },
            onDismiss: { }
        )
    }
    .padding()
    .frame(width: 400, height: 700)
}
