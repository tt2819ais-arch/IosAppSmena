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

/// Maps the user-selectable accent into a pair of gradient colors plus the
/// primary accent color used across the UI.
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

extension AppTheme {
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .dark:   return .dark
        case .light:  return .light
        }
    }
}
