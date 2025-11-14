//
//  DesignSystem.swift
//  Cortex
//
//  Created by Claude Code
//

import SwiftUI

/// Central design system for Cortex with modern design tokens
enum DesignSystem {

    // MARK: - Colors

    enum Colors {
        // Primary Brand Colors
        static let primaryBlue = Color(hexString: "#3B82F6")
        static let primaryPurple = Color(hexString: "#8B5CF6")
        static let accentGradientStart = Color(hexString: "#6366F1")
        static let accentGradientEnd = Color(hexString: "#8B5CF6")

        // Semantic Colors
        static let success = Color(hexString: "#10B981")
        static let warning = Color(hexString: "#F59E0B")
        static let error = Color(hexString: "#EF4444")
        static let info = Color(hexString: "#3B82F6")

        // Neutral Colors (Light Mode)
        static let textPrimary = Color(hexString: "#1F2937")
        static let textSecondary = Color(hexString: "#6B7280")
        static let textTertiary = Color(hexString: "#9CA3AF")

        // Background Colors
        static let backgroundPrimary = Color(nsColor: .windowBackgroundColor)
        static let backgroundSecondary = Color(nsColor: .controlBackgroundColor)
        static let backgroundTertiary = Color(hexString: "#F9FAFB")

        // Glass-Morphism Colors
        static let glassLight = Color.white.opacity(0.7)
        static let glassDark = Color.black.opacity(0.3)
        static let glassBlur = Color.white.opacity(0.1)

        // Gradient Presets
        static let primaryGradient = LinearGradient(
            colors: [accentGradientStart, accentGradientEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let successGradient = LinearGradient(
            colors: [success, success.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let warningGradient = LinearGradient(
            colors: [warning, warning.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Typography

    enum Typography {
        // Display
        static let displayLarge = Font.system(size: 57, weight: .bold, design: .rounded)
        static let displayMedium = Font.system(size: 45, weight: .bold, design: .rounded)
        static let displaySmall = Font.system(size: 36, weight: .bold, design: .rounded)

        // Headline
        static let headlineLarge = Font.system(size: 32, weight: .semibold, design: .rounded)
        static let headlineMedium = Font.system(size: 28, weight: .semibold, design: .rounded)
        static let headlineSmall = Font.system(size: 24, weight: .semibold, design: .rounded)

        // Title
        static let titleLarge = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let titleMedium = Font.system(size: 16, weight: .medium, design: .rounded)
        static let titleSmall = Font.system(size: 14, weight: .medium, design: .rounded)

        // Body
        static let bodyLarge = Font.system(size: 16, weight: .regular, design: .default)
        static let bodyMedium = Font.system(size: 14, weight: .regular, design: .default)
        static let bodySmall = Font.system(size: 12, weight: .regular, design: .default)

        // Label
        static let labelLarge = Font.system(size: 14, weight: .medium, design: .default)
        static let labelMedium = Font.system(size: 12, weight: .medium, design: .default)
        static let labelSmall = Font.system(size: 11, weight: .medium, design: .default)

        // Code
        static let codeLarge = Font.system(size: 14, weight: .regular, design: .monospaced)
        static let codeMedium = Font.system(size: 12, weight: .regular, design: .monospaced)
        static let codeSmall = Font.system(size: 10, weight: .regular, design: .monospaced)
    }

    // MARK: - Spacing

    enum Spacing {
        static let xxxs: CGFloat = 2
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 40
        static let huge: CGFloat = 48
    }

    // MARK: - Corner Radius

    enum CornerRadius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let round: CGFloat = 999
    }

    // MARK: - Shadows

    enum Shadows {
        static let small = Shadow(
            color: Color.black.opacity(0.05),
            radius: 4,
            x: 0,
            y: 2
        )

        static let medium = Shadow(
            color: Color.black.opacity(0.1),
            radius: 8,
            x: 0,
            y: 4
        )

        static let large = Shadow(
            color: Color.black.opacity(0.15),
            radius: 16,
            x: 0,
            y: 8
        )

        static let glow = Shadow(
            color: Colors.accentGradientStart.opacity(0.3),
            radius: 20,
            x: 0,
            y: 0
        )
    }

    // MARK: - Animations

    enum Animations {
        static let spring = Animation.spring(response: 0.3, dampingFraction: 0.7)
        static let springBouncy = Animation.spring(response: 0.4, dampingFraction: 0.6)
        static let easeInOut = Animation.easeInOut(duration: 0.3)
        static let smooth = Animation.smooth(duration: 0.3)
    }

    // MARK: - Transitions

    enum Transitions {
        static let fadeInOut = AnyTransition.opacity.animation(Animations.easeInOut)
        static let scaleAndFade = AnyTransition.scale.combined(with: .opacity).animation(Animations.spring)
        static let slideUp = AnyTransition.move(edge: .bottom).combined(with: .opacity).animation(Animations.spring)
    }
}

// MARK: - Shadow Helper

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Color Extension

extension Color {
    init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Extension for Shadows

extension View {
    func designSystemShadow(_ shadow: Shadow) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}
