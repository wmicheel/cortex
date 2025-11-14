//
//  CommandPaletteView.swift
//  Cortex
//
//  Created by Claude Code
//

import SwiftUI

/// Command Palette overlay with fuzzy search and keyboard navigation
struct CommandPaletteView: View {
    // MARK: - Properties

    @Binding var isPresented: Bool
    @State private var viewModel: CommandPaletteViewModel
    @FocusState private var isSearchFocused: Bool

    let onCommandSelected: (Command) -> Void

    // MARK: - Initialization

    init(
        isPresented: Binding<Bool>,
        knowledgeService: (any KnowledgeServiceProtocol)? = nil,
        onCommandSelected: @escaping (Command) -> Void
    ) {
        self._isPresented = isPresented
        self._viewModel = State(initialValue: CommandPaletteViewModel(knowledgeService: knowledgeService))
        self.onCommandSelected = onCommandSelected
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Semi-transparent overlay
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    close()
                }

            // Command Palette Card
            VStack(spacing: 0) {
                // Search Bar
                searchBar

                // Divider
                Divider()
                    .background(Color.white.opacity(0.1))

                // Commands List
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.filteredCommands.isEmpty {
                    emptyView
                } else {
                    commandsList
                }
            }
            .frame(width: 600, height: 500)
            .background(
                ZStack {
                    Color(nsColor: .controlBackgroundColor)

                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.1),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            )
            .cornerRadius(DesignSystem.CornerRadius.xl)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .designSystemShadow(DesignSystem.Shadows.large)
            .transition(DesignSystem.Transitions.scaleAndFade)
        }
        .onAppear {
            isSearchFocused = true
            Task {
                await viewModel.onAppear()
            }
        }
        .onKeyPress(.upArrow) {
            viewModel.selectPrevious()
            return .handled
        }
        .onKeyPress(.downArrow) {
            viewModel.selectNext()
            return .handled
        }
        .onKeyPress(.return) {
            executeSelectedCommand()
            return .handled
        }
        .onKeyPress(.escape) {
            close()
            return .handled
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // Search Icon
            Image(systemName: "magnifyingglass")
                .font(DesignSystem.Typography.titleMedium)
                .foregroundColor(DesignSystem.Colors.primaryBlue)

            // Search TextField
            TextField(L10n.CommandPalette.placeholder.localized, text: $viewModel.searchQuery)
                .textFieldStyle(.plain)
                .font(DesignSystem.Typography.bodyLarge)
                .focused($isSearchFocused)

            // Clear Button
            if !viewModel.searchQuery.isEmpty {
                Button(action: {
                    withAnimation(DesignSystem.Animations.spring) {
                        viewModel.reset()
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .hoverScale()
            }

            // Keyboard Hint
            HStack(spacing: DesignSystem.Spacing.xxs) {
                KeyboardHintBadge(key: "esc")
                Text(L10n.CommandPalette.escToClose.localized)
                    .font(DesignSystem.Typography.labelSmall)
                    .foregroundColor(.secondary)
            }
        }
        .padding(DesignSystem.Spacing.lg)
    }

    // MARK: - Commands List

    private var commandsList: some View {
        ScrollView {
            ScrollViewReader { proxy in
                LazyVStack(spacing: DesignSystem.Spacing.xxs) {
                    ForEach(Array(viewModel.filteredCommands.enumerated()), id: \.element.id) { index, command in
                        CommandRow(
                            command: command,
                            isSelected: index == viewModel.selectedIndex,
                            onTap: {
                                executeCommand(command)
                            }
                        )
                        .id(index)
                    }
                }
                .padding(DesignSystem.Spacing.xs)
                .onChange(of: viewModel.selectedIndex) { oldValue, newValue in
                    withAnimation(DesignSystem.Animations.smooth) {
                        proxy.scrollTo(newValue, anchor: .center)
                    }
                }
            }
        }
        .frame(maxHeight: 400)
    }

    // MARK: - Empty View

    private var emptyView: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text(L10n.CommandPalette.noCommands.localized)
                .font(DesignSystem.Typography.titleMedium)
                .foregroundColor(.secondary)

            if !viewModel.searchQuery.isEmpty {
                Text(L10n.CommandPalette.tryDifferent.localized)
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.xxxl)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            ProgressView()
                .scaleEffect(1.2)

            Text(L10n.CommandPalette.loadingCommands.localized)
                .font(DesignSystem.Typography.bodySmall)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.xxxl)
    }

    // MARK: - Actions

    private func executeSelectedCommand() {
        guard let command = viewModel.getSelectedCommand() else { return }
        executeCommand(command)
    }

    private func executeCommand(_ command: Command) {
        onCommandSelected(command)
        close()
    }

    private func close() {
        withAnimation(DesignSystem.Animations.spring) {
            isPresented = false
        }
        viewModel.reset()
    }
}

// MARK: - Command Row

struct CommandRow: View {
    let command: Command
    let isSelected: Bool
    let onTap: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignSystem.Spacing.md) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                        .fill(command.color.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: command.icon)
                        .font(DesignSystem.Typography.titleMedium)
                        .foregroundColor(command.color)
                }

                // Content
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                    Text(command.title)
                        .font(DesignSystem.Typography.titleSmall)
                        .foregroundColor(DesignSystem.Colors.textPrimary)

                    Text(command.description)
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                // Keyboard hint for selected item
                if isSelected {
                    KeyboardHintBadge(key: "↵")
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(
                ZStack {
                    if isSelected || isHovered {
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        command.color.opacity(isSelected ? 0.2 : 0.1),
                                        command.color.opacity(isSelected ? 0.15 : 0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .strokeBorder(
                        isSelected
                            ? command.color.opacity(0.5)
                            : Color.clear,
                        lineWidth: isSelected ? 2 : 0
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(DesignSystem.Animations.spring) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Keyboard Hint Badge

struct KeyboardHintBadge: View {
    let key: String

    var body: some View {
        Text(key)
            .font(DesignSystem.Typography.labelSmall)
            .foregroundColor(.secondary)
            .padding(.horizontal, DesignSystem.Spacing.xs)
            .padding(.vertical, DesignSystem.Spacing.xxxs)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(DesignSystem.CornerRadius.xs)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xs)
                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gray.opacity(0.3)

        CommandPaletteView(
            isPresented: .constant(true),
            onCommandSelected: { command in
                print("Selected: \(command.title)")
            }
        )
    }
}
