import Foundation
import Combine

/// One pay-out bucket for the chart.
struct PayoutBucket: Identifiable {
    var id: Date { date }
    let date: Date
    let amount: Double
    let isFuture: Bool
    let isNext: Bool
}

/// Single source of truth. Holds all data, persists to JSON in Documents,
/// and exposes the derived statistics the UI needs.
final class AppStore: ObservableObject {
    @Published var shifts: [Shift] = [] { didSet { save() } }
    @Published var entries: [MoneyEntry] = [] { didSet { save() } }
    @Published var settings: AppSettings = AppSettings() { didSet { save() } }

    private let calendar = Calendar.current
    private let fileURL: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("smena_data.json")
    }()

    private var isLoading = false

    init() { load() }

    // MARK: - Persistence

    private struct Snapshot: Codable {
        var shifts: [Shift]
        var entries: [MoneyEntry]
        var settings: AppSettings
    }

    private func load() {
        isLoading = true
        defer { isLoading = false }
        guard let data = try? Data(contentsOf: fileURL),
              let snap = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        shifts = snap.shifts
        entries = snap.entries
        settings = snap.settings
    }

    private func save() {
        guard !isLoading else { return }
        let snap = Snapshot(shifts: shifts, entries: entries, settings: settings)
        if let data = try? JSONEncoder().encode(snap) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    // MARK: - Mutations

    func addShift(_ shift: Shift) {
        shifts.append(shift)
        Haptics.success()
    }

    func updateShift(_ shift: Shift) {
        if let i = shifts.firstIndex(where: { $0.id == shift.id }) { shifts[i] = shift }
    }

    func deleteShift(_ shift: Shift) {
        shifts.removeAll { $0.id == shift.id }
    }

    func addEntry(_ entry: MoneyEntry) {
        entries.append(entry)
        Haptics.success()
    }

    func updateEntry(_ entry: MoneyEntry) {
        if let i = entries.firstIndex(where: { $0.id == entry.id }) { entries[i] = entry }
    }

    func deleteEntry(_ entry: MoneyEntry) {
        entries.removeAll { $0.id == entry.id }
    }

    // MARK: - Convenience

    var symbol: String { settings.currencySymbol }
    var accent: AccentTone { settings.accent }
    var payouts: PayoutCalculator { PayoutCalculator(settings: settings, calendar: calendar) }

    var shiftsSorted: [Shift] {
        shifts.sorted { lhs, rhs in
            if calendar.isDate(lhs.date, inSameDayAs: rhs.date) {
                return lhs.startMinutes > rhs.startMinutes
            }
            return lhs.date > rhs.date
        }
    }

    var entriesSorted: [MoneyEntry] { entries.sorted { $0.date > $1.date } }

    // MARK: - Totals

    var totalShiftEarnings: Double { shifts.reduce(0) { $0 + $1.earnings } }
    var totalHours: Double { shifts.reduce(0) { $0 + $1.workedHours } }
    var shiftsCount: Int { shifts.count }
    var totalIncome: Double { entries.filter { $0.kind == .income }.reduce(0) { $0 + $1.amount } }
    var totalExpenses: Double { entries.filter { $0.kind == .expense }.reduce(0) { $0 + $1.amount } }

    /// Net balance: shift earnings + extra income − expenses.
    var balance: Double { totalShiftEarnings + totalIncome - totalExpenses }

    // MARK: - Goal

    /// Money counted toward the goal.
    var earnedTowardGoal: Double {
        settings.goalIncludesExtras ? balance : totalShiftEarnings
    }

    var goalProgress: Double {
        guard settings.goalAmount > 0 else { return 0 }
        return min(max(earnedTowardGoal / settings.goalAmount, 0), 1)
    }

    var goalRemaining: Double { max(settings.goalAmount - earnedTowardGoal, 0) }
    var goalReached: Bool { settings.goalAmount > 0 && earnedTowardGoal >= settings.goalAmount }

    // MARK: - Pay periods

    /// Start (exclusive) of the current pay period = the previous pay-out date.
    var currentPeriodStart: Date { payouts.previousPayout(before: Date()) }
    var nextPayoutDate: Date { payouts.nextPayout(onOrAfter: Date()) }
    var daysUntilPayout: Int { payouts.daysUntilNextPayout() }

    /// Shift earnings attributed to the upcoming pay-out (current period).
    var currentPeriodEarnings: Double {
        let next = nextPayoutDate
        return shifts
            .filter { calendar.isDate(payouts.payoutDate(forShiftOn: $0.date), inSameDayAs: next) }
            .reduce(0) { $0 + $1.earnings }
    }

    var currentPeriodShiftCount: Int {
        let next = nextPayoutDate
        return shifts.filter { calendar.isDate(payouts.payoutDate(forShiftOn: $0.date), inSameDayAs: next) }.count
    }

    /// Buckets for the pay-out chart: a handful of past pay-outs plus the next one.
    func payoutBuckets(pastCount: Int = 5) -> [PayoutBucket] {
        let calc = payouts
        let today = calendar.startOfDay(for: Date())
        let next = calc.nextPayout(onOrAfter: today)

        // Gather distinct payout dates the shifts map to.
        var grouped: [Date: Double] = [:]
        for shift in shifts {
            let pd = calc.payoutDate(forShiftOn: shift.date)
            grouped[pd, default: 0] += shift.earnings
        }

        // Build the timeline window: a few payouts before `next` and `next` itself.
        let from = calendar.date(byAdding: .month, value: -4, to: today) ?? today
        let to = calendar.date(byAdding: .day, value: 1, to: next) ?? next
        var dates = calc.payoutDates(from: from, to: to)
        if !dates.contains(where: { calendar.isDate($0, inSameDayAs: next) }) { dates.append(next) }
        dates = Array(Set(dates.map { calendar.startOfDay(for: $0) })).sorted()

        // Keep the last `pastCount` past payouts and the next.
        let pastDates = dates.filter { $0 < next }.suffix(pastCount)
        let window = (Array(pastDates) + [next]).sorted()

        return window.map { date in
            let amount = grouped.first(where: { calendar.isDate($0.key, inSameDayAs: date) })?.value ?? 0
            let isFuture = date >= next
            return PayoutBucket(date: date, amount: amount,
                                isFuture: isFuture,
                                isNext: calendar.isDate(date, inSameDayAs: next))
        }
    }

    // MARK: - Grouping shifts by month for the list

    func shiftsByMonth() -> [(key: Date, shifts: [Shift])] {
        let groups = Dictionary(grouping: shiftsSorted) { shift -> Date in
            calendar.dateInterval(of: .month, for: shift.date)?.start ?? shift.date
        }
        return groups.map { (key: $0.key, shifts: $0.value) }.sorted { $0.key > $1.key }
    }

    func earnings(in month: Date) -> Double {
        shifts.filter { calendar.isDate($0.date, equalTo: month, toGranularity: .month) }
            .reduce(0) { $0 + $1.earnings }
    }
}
