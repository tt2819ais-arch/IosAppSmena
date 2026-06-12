import Foundation

enum Fmt {
    /// Formats a money amount with thin-space grouping and a trailing currency symbol.
    static func money(_ value: Double, symbol: String = "₽", fraction: Bool = false) -> String {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.groupingSeparator = "\u{00A0}" // non-breaking space
        nf.maximumFractionDigits = fraction ? 2 : 0
        nf.minimumFractionDigits = 0
        let rounded = fraction ? value : value.rounded()
        let number = nf.string(from: NSNumber(value: rounded)) ?? "0"
        return "\(number)\u{00A0}\(symbol)"
    }

    /// Compact money for chart axes etc. (e.g. 12,5к).
    static func moneyShort(_ value: Double, symbol: String = "₽") -> String {
        let abs = Swift.abs(value)
        if abs >= 1_000_000 {
            return String(format: "%.1fм", value / 1_000_000).replacingOccurrences(of: ".0", with: "")
        } else if abs >= 1_000 {
            return String(format: "%.1fк", value / 1_000).replacingOccurrences(of: ".0", with: "")
        }
        return String(format: "%.0f", value)
    }

    /// "8 ч 30 мин" from a number of hours.
    static func duration(hours: Double) -> String {
        let totalMinutes = Int((hours * 60).rounded())
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        if h > 0 && m > 0 { return "\(h) ч \(m) мин" }
        if h > 0 { return "\(h) ч" }
        return "\(m) мин"
    }

    /// "9:00" from minutes-from-midnight.
    static func clock(fromMinutes minutes: Int) -> String {
        let m = ((minutes % (24 * 60)) + (24 * 60)) % (24 * 60)
        return String(format: "%d:%02d", m / 60, m % 60)
    }

    private static func ruFormatter(_ template: String) -> DateFormatter {
        let df = DateFormatter()
        df.locale = Locale(identifier: "ru_RU")
        df.setLocalizedDateFormatFromTemplate(template)
        return df
    }

    static func dayMonth(_ date: Date) -> String { ruFormatter("ddMMMM").string(from: date) }
    static func dayMonthWeekday(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "ru_RU")
        df.dateFormat = "EEE, d MMM"
        return df.string(from: date).capitalized
    }
    static func shortDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "ru_RU")
        df.dateFormat = "d MMM"
        return df.string(from: date)
    }
    static func monthYear(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "ru_RU")
        df.dateFormat = "LLLL yyyy"
        return df.string(from: date).capitalized
    }

    /// Russian plural for shifts: 1 смена / 2 смены / 5 смен.
    static func shiftsWord(_ n: Int) -> String {
        let mod10 = n % 10, mod100 = n % 100
        if mod10 == 1 && mod100 != 11 { return "смена" }
        if (2...4).contains(mod10) && !(12...14).contains(mod100) { return "смены" }
        return "смен"
    }

    static func daysWord(_ n: Int) -> String {
        let mod10 = n % 10, mod100 = n % 100
        if mod10 == 1 && mod100 != 11 { return "день" }
        if (2...4).contains(mod10) && !(12...14).contains(mod100) { return "дня" }
        return "дней"
    }
}
