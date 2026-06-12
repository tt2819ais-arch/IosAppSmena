import SwiftUI
import Charts

struct PayoutsView: View {
    @EnvironmentObject var store: AppStore

    private var buckets: [PayoutBucket] { store.payoutBuckets() }

    var body: some View {
        ZStack {
            AuroraBackground(accent: store.accent)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    header
                    nextPayoutCard
                    chartCard
                    scheduleCard
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Выплаты")
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
            Spacer()
        }
        .padding(.top, 8)
    }

    private var nextPayoutCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Label("Текущий период", systemImage: "calendar.badge.clock")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline) {
                    Text(Fmt.money(store.currentPeriodEarnings, symbol: store.symbol))
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(store.accent.primary)
                        .contentTransition(.numericText())
                    Spacer()
                }
                Text("Накоплено к выплате \(Fmt.dayMonth(store.nextPayoutDate)) · \(store.currentPeriodShiftCount) \(Fmt.shiftsWord(store.currentPeriodShiftCount))")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    Image(systemName: "hourglass")
                    Text("До выплаты \(store.daysUntilPayout) \(Fmt.daysWord(store.daysUntilPayout))")
                }
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(store.accent.primary)
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(store.accent.primary.opacity(0.14), in: Capsule())
            }
        }
    }

    private var chartCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("График выплат")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                if buckets.allSatisfy({ $0.amount == 0 }) {
                    Text("Добавь смены — здесь появится график зарплат по датам выплат.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 120, alignment: .center)
                        .multilineTextAlignment(.center)
                } else {
                    Chart(buckets) { bucket in
                        BarMark(
                            x: .value("Дата", Fmt.shortDate(bucket.date)),
                            y: .value("Сумма", bucket.amount),
                            width: .fixed(26)
                        )
                        .foregroundStyle(bucket.isNext ? store.accent.gradient
                                         : LinearGradient(colors: [store.accent.primary.opacity(0.45),
                                                                   store.accent.secondary.opacity(0.35)],
                                                          startPoint: .top, endPoint: .bottom))
                        .cornerRadius(8)
                        .annotation(position: .top) {
                            if bucket.amount > 0 {
                                Text(Fmt.moneyShort(bucket.amount, symbol: store.symbol))
                                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisGridLine().foregroundStyle(Color.primary.opacity(0.06))
                            AxisValueLabel {
                                if let v = value.as(Double.self) {
                                    Text(Fmt.moneyShort(v)).font(.system(size: 9, design: .rounded))
                                }
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks { _ in
                            AxisValueLabel().font(.system(size: 9, design: .rounded))
                        }
                    }
                    .frame(height: 190)
                }
                HStack(spacing: 16) {
                    legendDot(store.accent.primary, "Будущая выплата")
                    legendDot(store.accent.primary.opacity(0.45), "Прошлые")
                }
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.secondary)
            }
        }
    }

    private func legendDot(_ color: Color, _ text: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(text)
        }
    }

    private var scheduleCard: some View {
        let calc = store.payouts
        let upcoming = calc.payoutDates(from: Date(),
                                        to: Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date())
            .prefix(5)
        return GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Ближайшие даты выплат")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                ForEach(Array(upcoming.enumerated()), id: \.offset) { idx, date in
                    HStack {
                        Image(systemName: idx == 0 ? "circle.fill" : "circle")
                            .font(.system(size: 10))
                            .foregroundStyle(idx == 0 ? store.accent.primary : Color.secondary)
                        Text(Fmt.dayMonthWeekday(date))
                            .font(.system(.subheadline, design: .rounded).weight(idx == 0 ? .bold : .regular))
                        Spacer()
                        if idx == 0 {
                            Text("ближайшая")
                                .font(.system(.caption2, design: .rounded).weight(.semibold))
                                .foregroundStyle(store.accent.primary)
                        }
                    }
                    if idx < upcoming.count - 1 { Divider() }
                }
                Text("Выплаты 2 раза в месяц: \(store.settings.payoutDay1) и \(store.settings.payoutDay2) числа. Изменить — в Настройках.")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
    }
}
