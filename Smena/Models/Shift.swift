import Foundation

/// A single work shift. Times are stored as "minutes from midnight" so that
/// overnight shifts (end < start) are handled correctly by adding 24h.
struct Shift: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    /// Calendar day the shift starts on (time component ignored).
    var date: Date
    /// Minutes from midnight for the start time, e.g. 9:00 -> 540.
    var startMinutes: Int
    /// Minutes from midnight for the end time, e.g. 18:00 -> 1080.
    var endMinutes: Int
    /// Hourly rate in the chosen currency.
    var hourlyRate: Double
    /// Optional break in minutes, subtracted from worked time.
    var breakMinutes: Int = 0
    var note: String = ""

    /// Worked duration in minutes, accounting for overnight shifts and breaks.
    var workedMinutes: Int {
        var diff = endMinutes - startMinutes
        if diff <= 0 { diff += 24 * 60 } // crosses midnight
        diff -= breakMinutes
        return max(diff, 0)
    }

    var workedHours: Double { Double(workedMinutes) / 60.0 }

    var earnings: Double { workedHours * hourlyRate }
}
