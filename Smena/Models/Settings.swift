import Foundation

enum AppTheme: String, Codable, CaseIterable {
    case system, dark, light

    var title: String {
        switch self {
        case .system: return "Система"
        case .dark: return "Тёмная"
        case .light: return "Светлая"
        }
    }
}

enum AccentTone: String, Codable, CaseIterable {
    case violet, teal, blue, pink, orange, green

    var title: String {
        switch self {
        case .violet: return "Фиолетовый"
        case .teal: return "Бирюзовый"
        case .blue: return "Синий"
        case .pink: return "Розовый"
        case .orange: return "Оранжевый"
        case .green: return "Зелёный"
        }
    }
}

struct AppSettings: Codable, Equatable {
    var currencySymbol: String = "₽"
    var defaultHourlyRate: Double = 500
    /// Two pay-out days per month (1...28). Sorted on use.
    var payoutDay1: Int = 10
    var payoutDay2: Int = 25
    var goalAmount: Double = 100_000
    var theme: AppTheme = .dark
    var accent: AccentTone = .violet

    /// Counts shift earnings + extra income − expenses toward the goal.
    var goalIncludesExtras: Bool = true
}
