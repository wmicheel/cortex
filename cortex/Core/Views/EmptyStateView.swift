//
//  EmptyStateView.swift
//  Cortex
//
//  Created by Claude Code
//

import SwiftUI

/// Reusable empty state view with icon, title, message, and optional action
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
                .symbolRenderingMode(.hierarchical)

            // Text content
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 32)

            // Action button
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Label(actionTitle, systemImage: "plus.circle.fill")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
    }
}

// MARK: - Preview

#Preview("No Data") {
    EmptyStateView(
        icon: "brain.head.profile",
        title: "No Knowledge Entries",
        message: "Start building your second brain by adding your first knowledge entry",
        actionTitle: "Add First Entry",
        action: {}
    )
}

#Preview("No Search Results") {
    EmptyStateView(
        icon: "magnifyingglass",
        title: "No Results Found",
        message: "Try adjusting your search query or filters",
        actionTitle: nil,
        action: nil
    )
}

#Preview("Error State") {
    EmptyStateView(
        icon: "exclamationmark.triangle",
        title: "Something Went Wrong",
        message: "We couldn't load your data. Please try again.",
        actionTitle: "Retry",
        action: {}
    )
}
