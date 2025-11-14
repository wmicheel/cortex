//
//  GlassMorphism.swift
//  Cortex
//
//  Created by Claude Code
//

import SwiftUI

// MARK: - Glass Card

struct GlassCard<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = DesignSystem.CornerRadius.lg
    var padding: CGFloat = DesignSystem.Spacing.lg

    init(
        cornerRadius: CGFloat = DesignSystem.CornerRadius.lg,
        padding: CGFloat = DesignSystem.Spacing.lg,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                ZStack {
                    // Base background
                    Color(nsColor: .controlBackgroundColor)

                    // Glass effect overlay
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
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .designSystemShadow(DesignSystem.Shadows.medium)
    }
}

// MARK: - Glass Button

struct GlassButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var style: GlassButtonStyle = .primary

    @State private var isHovered = false
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(DesignSystem.Typography.labelMedium)
                }

                Text(title)
                    .font(DesignSystem.Typography.labelLarge)
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(backgroundForStyle)
            .foregroundColor(foregroundForStyle)
            .cornerRadius(DesignSystem.CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .strokeBorder(borderForStyle, lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.95 : (isHovered ? 1.02 : 1.0))
            .designSystemShadow(isHovered ? DesignSystem.Shadows.medium : DesignSystem.Shadows.small)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(DesignSystem.Animations.spring) {
                isHovered = hovering
            }
        }
        .pressAction {
            withAnimation(DesignSystem.Animations.spring) {
                isPressed = true
            }
        } onRelease: {
            withAnimation(DesignSystem.Animations.spring) {
                isPressed = false
            }
        }
    }

    private var backgroundForStyle: some View {
        Group {
            switch style {
            case .primary:
                DesignSystem.Colors.primaryGradient
            case .secondary:
                Color(nsColor: .controlBackgroundColor)
            case .success:
                DesignSystem.Colors.successGradient
            case .warning:
                DesignSystem.Colors.warningGradient
            case .destructive:
                LinearGradient(
                    colors: [DesignSystem.Colors.error, DesignSystem.Colors.error.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }

    private var foregroundForStyle: Color {
        switch style {
        case .primary, .success, .warning, .destructive:
            return .white
        case .secondary:
            return DesignSystem.Colors.textPrimary
        }
    }

    private var borderForStyle: some ShapeStyle {
        switch style {
        case .primary, .success, .warning, .destructive:
            return Color.white.opacity(0.2)
        case .secondary:
            return Color(nsColor: .separatorColor)
        }
    }

    enum GlassButtonStyle {
        case primary
        case secondary
        case success
        case warning
        case destructive
    }
}

// MARK: - Glass Badge

struct GlassBadge: View {
    let text: String
    var color: Color = DesignSystem.Colors.primaryBlue
    var icon: String? = nil

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xxs) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(DesignSystem.Typography.labelSmall)
            }

            Text(text)
                .font(DesignSystem.Typography.labelSmall)
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.xxs)
        .background(
            ZStack {
                color.opacity(0.15)

                LinearGradient(
                    colors: [
                        Color.white.opacity(0.1),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .foregroundColor(color)
        .cornerRadius(DesignSystem.CornerRadius.sm)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                .strokeBorder(color.opacity(0.3), lineWidth: 0.5)
        )
    }
}

// MARK: - Glass Section

struct GlassSection<Content: View>: View {
    let title: String
    let icon: String?
    let content: Content

    init(
        title: String,
        icon: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(DesignSystem.Typography.titleMedium)
                        .foregroundColor(DesignSystem.Colors.primaryBlue)
                }

                Text(title)
                    .font(DesignSystem.Typography.titleLarge)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignSystem.Spacing.lg)
        .background(
            ZStack {
                Color(nsColor: .controlBackgroundColor)

                LinearGradient(
                    colors: [
                        Color.white.opacity(0.05),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
        )
        .designSystemShadow(DesignSystem.Shadows.small)
    }
}

// MARK: - Animated Gradient Background

struct AnimatedGradientBackground: View {
    @State private var animate = false

    var body: some View {
        LinearGradient(
            colors: [
                DesignSystem.Colors.accentGradientStart.opacity(0.3),
                DesignSystem.Colors.accentGradientEnd.opacity(0.2),
                DesignSystem.Colors.primaryBlue.opacity(0.1)
            ],
            startPoint: animate ? .topLeading : .bottomLeading,
            endPoint: animate ? .bottomTrailing : .topTrailing
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
    }
}

// MARK: - Press Action Modifier

struct PressActions: ViewModifier {
    var onPress: () -> Void
    var onRelease: () -> Void

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged({ _ in
                        onPress()
                    })
                    .onEnded({ _ in
                        onRelease()
                    })
            )
    }
}

extension View {
    func pressAction(onPress: @escaping (() -> Void), onRelease: @escaping (() -> Void)) -> some View {
        modifier(PressActions(onPress: onPress, onRelease: onRelease))
    }
}

// MARK: - Shimmer Effect

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        Color.white.opacity(0.3),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: -200 + phase)
            )
            .onAppear {
                withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 400
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
}

// MARK: - Hover Scale Effect

struct HoverScaleEffect: ViewModifier {
    @State private var isHovered = false
    let scale: CGFloat

    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? scale : 1.0)
            .animation(DesignSystem.Animations.spring, value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

extension View {
    func hoverScale(_ scale: CGFloat = 1.05) -> some View {
        modifier(HoverScaleEffect(scale: scale))
    }
}
