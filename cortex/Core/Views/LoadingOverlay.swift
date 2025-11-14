//
//  LoadingOverlay.swift
//  Cortex
//
//  Created by Claude Code
//

import SwiftUI

/// Loading overlay with spinner and optional message
struct LoadingOverlay: View {
    let message: String?

    init(message: String? = nil) {
        self.message = message
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(.circular)

                if let message = message {
                    Text(message)
                        .font(.headline)
                        .foregroundColor(.primary)
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(nsColor: .windowBackgroundColor))
                    .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
            )
        }
    }
}

// MARK: - View Extension

extension View {
    /// Show loading overlay
    func loadingOverlay(isLoading: Bool, message: String? = nil) -> some View {
        self.overlay {
            if isLoading {
                LoadingOverlay(message: message)
                    .transition(.opacity.animation(.easeInOut(duration: 0.2)))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        Text("Content behind overlay")
    }
    .frame(width: 600, height: 400)
    .loadingOverlay(isLoading: true, message: "Loading data...")
}
