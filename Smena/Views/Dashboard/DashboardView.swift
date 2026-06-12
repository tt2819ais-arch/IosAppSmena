import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var store: AppStore
    @State private var showAddShift = false
    @State private var showAddEntry = false

    var body: some View {
        ZStack {
            AppBackground(accent: store.accent)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    header
                    goalCard
                    statRow
                    addButton
                    if !store.shiftsSorted.isEmpty { recentShifts }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showAddShift) { AddShiftView() }
        .sheet(isPresented: $showAddEntry) { AddEntryView() }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                    .font(.system(.title, design: .rounded).weight(.bold))
                Text(Fmt.monthYear(Date()))
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button { Haptics.light(); showAddEntry = true } label: {
                Image(systemName: "plusminus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(store.accent.primary)
                    .frame(width: 44, height: 44)
                    .background(store.accent.primary.opacity(0.14),
                                in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(PressableStyle())
        }
        .padding(.top, 8)
    }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<12: return "Доброе утро"
        case 12..<17: return "Добрый день"
        case 17..<23: return "Добрый вечер"
        default: return "Доброй ночи"
        }
    }

    // MARK: - Goal card

    private var goalCard: some View {
        GlassCard(padding: 22) {
            VStack(spacing: 18) {
                HStack {
                    Text("Цель")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    if store.goalReached {
                        Text("Достигнута 🎉")
                            .font(.system(.caption, design: .rounded).weight(.bold))
                            .foregroundStyle(store.accent.primary)
                    } else {
                        Text(Fmt.money(store.settings.goalAmount, symbol: store.symbol))
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }

                ProgressRing(progress: store.goalProgress, gradient: store.accent.gradient, lineWidth: 16) {
                    VStack(spacing: 2) {
                        Text("\(Int((store.goalProgress * 100).rounded()))%")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .contentTransition(.numericText())
                        Text("выполнено")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 176, height: 176)

                HStack {
                    goalStat("Заработано", Fmt.money(store.earnedTowardGoal, symbol: store.symbol), store.accent.primary)
                    Divider().frame(height: 30)
                    goalStat("Осталось", Fmt.money(store.goalRemaining, symbol: store.symbol), nil)
                }
            }
        }
    }

    private func goalStat(_ title: String, _ value: String, _ tint: Color?) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundStyle(tint ?? .primary)
                .contentTransition(.numericText())
                .lineLimit(1).minimumScaleFactor(0.7)
            Text(title)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Two-up stat row

    private var statRow: some View {
        HStack(spacing: 14) {
            GlassCard(padding: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: "wallet.pass.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(store.accent.primary)
                    Text(Fmt.money(store.balance, symbol: store.symbol))
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .lineLimit(1).minimumScaleFactor(0.6)
                        .contentTransition(.numericText())
                    Text("Баланс").font(.system(.caption, design: .rounded)).foregroundStyle(.secondary)
                }
            }
            GlassCard(padding: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(store.accent.secondary)
                    Text(Fmt.dayMonth(store.nextPayoutDate))
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .lineLimit(1).minimumScaleFactor(0.6)
                    Text("Выплата · через \(store.daysUntilPayout) \(Fmt.daysWord(store.daysUntilPayout))")
                        .font(.system(.caption, design: .rounded)).foregroundStyle(.secondary)
                        .lineLimit(1).minimumScaleFactor(0.7)
                }
            }
        }
    }

    private var addButton: some View {
        PrimaryButton(title: "Добавить смену", systemImage: "plus", gradient: store.accent.gradient) {
            showAddShift = true
        }
    }

    // MARK: - Recent shifts

    private var recentShifts: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Последние смены")
                .font(.system(.headline, design: .rounded).weight(.bold))
                .padding(.leading, 4)
            ForEach(store.shiftsSorted.prefix(3)) { shift in
                ShiftRow(shift: shift, symbol: store.symbol, accent: store.accent)
            }
        }
    }
}
