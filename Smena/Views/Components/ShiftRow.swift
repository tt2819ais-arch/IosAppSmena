import SwiftUI

struct ShiftRow: View {
    let shift: Shift
    let symbol: String
    let accent: AccentTone

    var body: some View {
        GlassCard(padding: 14) {
            HStack(spacing: 14) {
                VStack(spacing: 0) {
                    Text(dayNumber)
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(accent.primary)
                    Text(monthShort)
                        .font(.system(.caption2, design: .rounded).weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                }
                .frame(width: 46)

                VStack(alignment: .leading, spacing: 3) {
                    Text("\(Fmt.clock(fromMinutes: shift.startMinutes)) – \(Fmt.clock(fromMinutes: shift.endMinutes))")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    HStack(spacing: 8) {
                        Label(Fmt.duration(hours: shift.workedHours), systemImage: "clock")
                        Label(Fmt.money(shift.hourlyRate, symbol: symbol) + "/ч", systemImage: "tag")
                    }
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
                    if !shift.note.isEmpty {
                        Text(shift.note)
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Text(Fmt.money(shift.earnings, symbol: symbol))
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(.primary)
            }
        }
    }

    private var dayNumber: String {
        let df = DateFormatter(); df.locale = Locale(identifier: "ru_RU"); df.dateFormat = "d"
        return df.string(from: shift.date)
    }
    private var monthShort: String {
        let df = DateFormatter(); df.locale = Locale(identifier: "ru_RU"); df.dateFormat = "MMM"
        return df.string(from: shift.date)
    }
}
