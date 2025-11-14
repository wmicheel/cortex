//
//  SkeletonLoadingView.swift
//  Cortex
//
//  Created by Claude Code
//

import SwiftUI

/// Skeleton loading placeholder for content
struct SkeletonLoadingView: View {
    @State private var isAnimating = false
    let width: CGFloat?
    let height: CGFloat

    init(width: CGFloat? = nil, height: CGFloat = 20) {
        self.width = width
        self.height = height
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.gray.opacity(0.3))
            .frame(width: width, height: height)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.3),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: isAnimating ? 400 : -400)
            )
            .clipped()
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}

/// Skeleton loading row for knowledge entries
struct SkeletonEntryRow: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title
            SkeletonLoadingView(width: 200, height: 16)

            // Content preview
            SkeletonLoadingView(width: 300, height: 12)
            SkeletonLoadingView(width: 250, height: 12)

            // Tags
            HStack(spacing: 4) {
                SkeletonLoadingView(width: 60, height: 12)
                SkeletonLoadingView(width: 80, height: 12)
            }
        }
        .padding(.vertical, 8)
    }
}

/// Skeleton loading for statistics cards
struct SkeletonStatCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SkeletonLoadingView(width: 40, height: 32)
            SkeletonLoadingView(width: 80, height: 32)
            SkeletonLoadingView(width: 100, height: 16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview("Skeleton Row") {
    List {
        SkeletonEntryRow()
        SkeletonEntryRow()
        SkeletonEntryRow()
    }
}

#Preview("Skeleton Cards") {
    HStack(spacing: 16) {
        SkeletonStatCard()
        SkeletonStatCard()
        SkeletonStatCard()
    }
    .padding()
}
