import Foundation

/// Computes salary pay-out dates (twice a month) and helps attribute shift
/// earnings to the pay period in which they will be paid.
struct PayoutCalculator {
    let day1: Int
    let day2: Int
    var calendar: Calendar = .current

    init(settings: AppSettings, calendar: Calendar = .current) {
        self.day1 = settings.payoutDay1
        self.day2 = settings.payoutDay2
        self.calendar = calendar
    }

    init(day1: Int, day2: Int, calendar: Calendar = .current) {
        self.day1 = day1
        self.day2 = day2
        self.calendar = calendar
    }

    /// Two pay-out days, sorted ascending and de-duplicated.
    private var sortedDays: [Int] {
        let raw = Array(Set([clamp(day1), clamp(day2)])).sorted()
        return raw.isEmpty ? [15] : raw
    }

    private func clamp(_ d: Int) -> Int { min(max(d, 1), 28) }

    /// Build a concrete pay-out date for a given year/month/day, clamped to the
    /// number of days in that month (so day 31 -> last day).
    private func date(year: Int, month: Int, day: Int) -> Date? {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = 1
        guard let first = calendar.date(from: comps),
              let range = calendar.range(of: .day, in: .month, for: first) else { return nil }
        let clampedDay = min(day, range.count)
        comps.day = clampedDay
        return calendar.startOfDay(for: calendar.date(from: comps) ?? first)
    }

    /// All pay-out dates within an inclusive day range, sorted ascending.
    func payoutDates(from start: Date, to end: Date) -> [Date] {
        let startDay = calendar.startOfDay(for: start)
        let endDay = calendar.startOfDay(for: end)
        guard startDay <= endDay else { return [] }

        var result: [Date] = []
        // Walk month by month from one month before start to end.
        guard var cursor = calendar.date(byAdding: .month, value: -1,
                                         to: calendar.dateInterval(of: .month, for: startDay)?.start ?? startDay) else { return [] }
        let stop = calendar.date(byAdding: .month, value: 2, to: endDay) ?? endDay
        while cursor <= stop {
            let comps = calendar.dateComponents([.year, .month], from: cursor)
            if let y = comps.year, let m = comps.month {
                for d in sortedDays {
                    if let pd = date(year: y, month: m, day: d), pd >= startDay, pd <= endDay {
                        result.append(pd)
                    }
                }
            }
            guard let next = calendar.date(byAdding: .month, value: 1, to: cursor) else { break }
            cursor = next
        }
        return result.sorted()
    }

    /// The next pay-out date on or after `date` (defaults to today).
    func nextPayout(onOrAfter date: Date = Date()) -> Date {
        let base = calendar.startOfDay(for: date)
        let window = payoutDates(from: base, to: calendar.date(byAdding: .month, value: 2, to: base) ?? base)
        return window.first ?? base
    }

    /// The most recent pay-out date strictly before `date` (defaults to today).
    func previousPayout(before date: Date = Date()) -> Date {
        let base = calendar.startOfDay(for: date)
        let window = payoutDates(from: calendar.date(byAdding: .month, value: -2, to: base) ?? base,
                                 to: base)
        return window.filter { $0 < base }.last
            ?? (calendar.date(byAdding: .day, value: -15, to: base) ?? base)
    }

    /// The pay-out date that will pay for work done on `date`
    /// (the first pay-out strictly after the shift day).
    func payoutDate(forShiftOn date: Date) -> Date {
        let day = calendar.startOfDay(for: date)
        let window = payoutDates(from: day, to: calendar.date(byAdding: .month, value: 2, to: day) ?? day)
        return window.first(where: { $0 > day }) ?? nextPayout(onOrAfter: day)
    }

    /// Days remaining until the next pay-out.
    func daysUntilNextPayout(from date: Date = Date()) -> Int {
        let comps = calendar.dateComponents([.day], from: calendar.startOfDay(for: date),
                                            to: nextPayout(onOrAfter: date))
        return max(comps.day ?? 0, 0)
    }
}
