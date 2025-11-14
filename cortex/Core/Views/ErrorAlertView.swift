//
//  ErrorAlertView.swift
//  Cortex
//
//  Created by Claude Code
//

import SwiftUI

/// Custom error alert with better UX
struct ErrorAlertView: View {
    let error: CortexError
    let onDismiss: () -> Void
    let onRetry: (() -> Void)?

    var body: some View {
        VStack(spacing: 20) {
            // Icon
            Image(systemName: errorIcon)
                .font(.system(size: 48))
                .foregroundColor(errorColor)

            // Title
            Text("Error")
                .font(.title2)
                .fontWeight(.bold)

            // Description
            Text(error.localizedDescription)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)

            // Recovery Suggestion
            if let suggestion = error.recoverySuggestion {
                Text(suggestion)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Actions
            HStack(spacing: 12) {
                Button("Dismiss") {
                    onDismiss()
                }
                .keyboardShortcut(.cancelAction)

                if let retry = onRetry {
                    Button("Retry") {
                        retry()
                        onDismiss()
                    }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.top, 8)
        }
        .padding(32)
        .frame(width: 400)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
    }

    private var errorIcon: String {
        switch error {
        case .cloudKitNotAvailable, .cloudKitAccountNotFound:
            return "icloud.slash"
        case .keychainError:
            return "key.slash"
        case .cloudKitFetchFailed, .cloudKitSaveFailed, .cloudKitDeleteFailed, .cloudKitQueryFailed:
            return "wifi.slash"
        default:
            return "exclamationmark.triangle"
        }
    }

    private var errorColor: Color {
        switch error {
        case .cloudKitNotAvailable, .cloudKitAccountNotFound:
            return .orange
        case .cloudKitFetchFailed, .cloudKitSaveFailed, .cloudKitDeleteFailed, .cloudKitQueryFailed:
            return .orange
        default:
            return .red
        }
    }
}

// MARK: - View Extension

extension View {
    /// Show custom error alert
    func errorAlert(
        error: Binding<CortexError?>,
        onRetry: (() -> Void)? = nil
    ) -> some View {
        self.overlay {
            if let currentError = error.wrappedValue {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        error.wrappedValue = nil
                    }

                ErrorAlertView(
                    error: currentError,
                    onDismiss: {
                        error.wrappedValue = nil
                    },
                    onRetry: onRetry
                )
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ErrorAlertView(
        error: .cloudKitNotAvailable,
        onDismiss: {},
        onRetry: {}
    )
}
