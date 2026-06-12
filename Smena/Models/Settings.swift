import Foundation

/// Background / appearance mode.
/// - aurora: living animated background (reacts to device tilt), dark canvas
/// - light:  plain, calm white background
/// - dark:   plain, deep black background
enum Appearance: String, Codable, CaseIterable {
    case aurora, light, dark

    var title: String {
        switch self {
        case .aurora: return "Живой"
        case .light:  return "Светлый"
        case .dark:   return "Тёмный"
        }
    }

    var icon: String {
        switch self {
        case .aurora: return "sparkles"
        case .light:  return "sun.max.fill"
        case .dark:   return "moon.fill"
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

/// User-configurable settings. Decoding is resilient: any missing or
/// renamed key falls back to its default so old saved data never wipes the
/// whole settings object (e.g. when migrating the old `theme` field).
struct AppSettings: Equatable {
    var currencySymbol: String = "₽"
    var defaultHourlyRate: Double = 500
    /// Two pay-out days per month (1...28). Sorted on use.
    var payoutDay1: Int = 10
    var payoutDay2: Int = 25
    var goalAmount: Double = 100_000
    var appearance: Appearance = .aurora
    var accent: AccentTone = .violet

    /// Counts shift earnings + extra income − expenses toward the goal.
    var goalIncludesExtras: Bool = true

    init() {}
}

extension AppSettings: Codable {
    private enum CodingKeys: String, CodingKey {
        case currencySymbol, defaultHourlyRate, payoutDay1, payoutDay2
        case goalAmount, appearance, accent, goalIncludesExtras
        case theme // legacy
    }

    init(from decoder: Decoder) throws {
        self.init()
        guard let c = try? decoder.container(keyedBy: CodingKeys.self) else { return }
        if let v = try? c.decodeIfPresent(String.self, forKey: .currencySymbol) { currencySymbol = v }
        if let v = try? c.decodeIfPresent(Double.self, forKey: .defaultHourlyRate) { defaultHourlyRate = v }
        if let v = try? c.decodeIfPresent(Int.self, forKey: .payoutDay1) { payoutDay1 = v }
        if let v = try? c.decodeIfPresent(Int.self, forKey: .payoutDay2) { payoutDay2 = v }
        if let v = try? c.decodeIfPresent(Double.self, forKey: .goalAmount) { goalAmount = v }
        if let v = try? c.decodeIfPresent(AccentTone.self, forKey: .accent) { accent = v }
        if let v = try? c.decodeIfPresent(Bool.self, forKey: .goalIncludesExtras) { goalIncludesExtras = v }

        // New appearance key, with migration from the legacy `theme` field.
        if let v = try? c.decodeIfPresent(Appearance.self, forKey: .appearance) {
            appearance = v
        } else if let legacy = try? c.decodeIfPresent(String.self, forKey: .theme) {
            switch legacy {
            case "light": appearance = .light
            case "dark":  appearance = .dark
            default:      appearance = .aurora
            }
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(currencySymbol, forKey: .currencySymbol)
        try c.encode(defaultHourlyRate, forKey: .defaultHourlyRate)
        try c.encode(payoutDay1, forKey: .payoutDay1)
        try c.encode(payoutDay2, forKey: .payoutDay2)
        try c.encode(goalAmount, forKey: .goalAmount)
        try c.encode(appearance, forKey: .appearance)
        try c.encode(accent, forKey: .accent)
        try c.encode(goalIncludesExtras, forKey: .goalIncludesExtras)
    }
}
