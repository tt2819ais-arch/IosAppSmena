import SwiftUI

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 08) & 0xFF) / 255,
            blue: Double((hex >> 00) & 0xFF) / 255,
            opacity: alpha
        )
    }
}

/// Maps the accent tone into a pair of gradient colors plus the primary color.
extension AccentTone {
    var primary: Color {
        switch self {
        case .violet: return Color(hex: 0x7C5CFF)
        case .teal:   return Color(hex: 0x18C2B4)
        case .blue:   return Color(hex: 0x2F8CFF)
        case .pink:   return Color(hex: 0xFF4D8D)
        case .orange: return Color(hex: 0xFF8A3D)
        case .green:  return Color(hex: 0x2FCB6E)
        }
    }

    var secondary: Color {
        switch self {
        case .violet: return Color(hex: 0xC04CFF)
        case .teal:   return Color(hex: 0x32E0C4)
        case .blue:   return Color(hex: 0x4FD2FF)
        case .pink:   return Color(hex: 0xFF7AA8)
        case .orange: return Color(hex: 0xFFC24B)
        case .green:  return Color(hex: 0x8BE04B)
        }
    }

    var gradient: LinearGradient {
        LinearGradient(colors: [primary, secondary],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

/// Visual configuration derived from the selected appearance.
extension Appearance {
    /// Forced color scheme for the whole app.
    var colorScheme: ColorScheme {
        switch self {
        case .light: return .light
        case .dark, .aurora: return .dark
        }
    }

    var isDarkSurface: Bool { colorScheme == .dark }

    /// Base background color behind everything (used by plain modes and as the
    /// canvas base for the animated aurora).
    var baseColor: Color {
        switch self {
        case .light:  return Color(hex: 0xF5F5F8)
        case .dark:   return Color(hex: 0x000000)
        case .aurora: return Color(hex: 0x07070C)
        }
    }

    /// Whether the background animates.
    var isAnimated: Bool { self == .aurora }

    // MARK: Card surface styling

    /// Fill used by cards. Aurora uses a translucent frosted look; plain modes
    /// use cheap solid fills (better for performance and calmer visually).
    var cardFill: Color {
        switch self {
        case .aurora: return Color.white.opacity(0.06)
        case .dark:   return Color.white.opacity(0.05)
        case .light:  return Color.white
        }
    }

    var cardBorder: Color {
        switch self {
        case .aurora: return Color.white.opacity(0.10)
        case .dark:   return Color.white.opacity(0.07)
        case .light:  return Color.black.opacity(0.05)
        }
    }

    var cardShadow: Color {
        switch self {
        case .light:  return Color.black.opacity(0.06)
        case .dark:   return Color.black.opacity(0.25)
        case .aurora: return Color.black.opacity(0.30)
        }
    }

    /// Whether cards should use the frosted material (aurora only).
    var usesMaterial: Bool { self == .aurora }
}

// MARK: - Environment plumbing

private struct AppearanceKey: EnvironmentKey {
    static let defaultValue: Appearance = .aurora
}

extension EnvironmentValues {
    var appearance: Appearance {
        get { self[AppearanceKey.self] }
        set { self[AppearanceKey.self] = newValue }
    }
}
