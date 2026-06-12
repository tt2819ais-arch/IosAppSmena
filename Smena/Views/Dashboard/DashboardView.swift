import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var store: AppStore
    @State private var showAddShift = false
    @State private var showAddEntry = false

    var body: some View {
        ZStack {
            AuroraBackground(accent: store.accent)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    header
                    goalCard
                    statsGrid
                    payoutCard
                    quickActions
                    if !store.shiftsSorted.isEmpty { recentShifts }
                }
                .padding(.horizontal, 18)
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
            Image(systemName: "clock.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 46, height: 46)
                .background(store.accent.gradient, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: store.accent.primary.opacity(0.5), radius: 10, y: 4)
        }
        .padding(.top, 8)
    }

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        switch h {
        case 5..<12: return "Доброе утро"
        case 12..<17: return "Добрый день"
        case 17..<23: return "Добрый вечер"
        default: return "Доброй ночи"
        }
    }

    // MARK: - Goal card

    private var goalCard: some View {
        GlassCard {
            VStack(spacing: 16) {
                HStack {
                    Label("Цель", systemImage: "target")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    if store.goalReached {
                        Text("Достигнута 🎉")
                            .font(.system(.caption, design: .rounded).weight(.bold))
                            .foregroundStyle(store.accent.primary)
                    }
                }

                ProgressRing(progress: store.goalProgress, gradient: store.accent.gradient, lineWidth: 18) {
                    VStack(spacing: 2) {
                        Text("\(Int((store.goalProgress * 100).rounded()))%")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .contentTransition(.numericText())
                        Text("выполнено")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 190, height: 190)
                .padding(.vertical, 4)

                HStack {
                    goalStat(title: "Заработано", value: Fmt.money(store.earnedTowardGoal, symbol: store.symbol), tint: store.accent.primary)
                    Spacer()
                    Divider().frame(height: 34)
                    Spacer()
                    goalStat(title: "Осталось", value: Fmt.money(store.goalRemaining, symbol: store.symbol), tint: .secondary)
                }
                HStack {
                    Spacer()
                    Text("Цель: \(Fmt.money(store.settings.goalAmount, symbol: store.symbol))")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
        }
    }

    private func goalStat(title: String, value: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundStyle(tint == .secondary ? Color.primary : tint)
                .contentTransition(.numericText())
            Text(title)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Stats grid

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
            StatTile(icon: "wallet.pass.fill", value: Fmt.money(store.balance, symbol: store.symbol),
                     caption: "Баланс", tint: store.accent.primary)
            StatTile(icon: "calendar", value: "\(store.shiftsCount) \(Fmt.shiftsWord(store.shiftsCount))",
                     caption: "Всего смен", tint: store.accent.secondary)
            StatTile(icon: "clock.fill", value: Fmt.duration(hours: store.totalHours),
                     caption: "Отработано", tint: store.accent.primary)
            StatTile(icon: "banknote.fill", value: Fmt.money(store.totalShiftEarnings, symbol: store.symbol),
                     caption: "За смены", tint: store.accent.secondary)
        }
    }

    // MARK: - Payout card

    private var payoutCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("Ближайшая выплата", systemImage: "calendar.badge.clock")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Fmt.dayMonth(store.nextPayoutDate))
                            .font(.system(.title2, design: .rounded).weight(.bold))
                        Text("через \(store.daysUntilPayout) \(Fmt.daysWord(store.daysUntilPayout))")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(Fmt.money(store.currentPeriodEarnings, symbol: store.symbol))
                            .font(.system(.title2, design: .rounded).weight(.bold))
                            .foregroundStyle(store.accent.primary)
                            .contentTransition(.numericText())
                        Text("за период · \(store.currentPeriodShiftCount) \(Fmt.shiftsWord(store.currentPeriodShiftCount))")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Quick actions

    private var quickActions: some View {
        HStack(spacing: 14) {
            PrimaryButton(title: "Добавить смену", systemImage: "plus", gradient: store.accent.gradient) {
                showAddShift = true
            }
            Button {
                Haptics.light(); showAddEntry = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plusminus")
                    Text("Доход/расход").fontWeight(.semibold)
                }
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1))
            }
            .buttonStyle(PressableStyle())
        }
    }

    // MARK: - Recent shifts

    private var recentShifts: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Последние смены")
                .font(.system(.headline, design: .rounded).weight(.bold))
                .padding(.leading, 4)
            ForEach(store.shiftsSorted.prefix(3)) { shift in
                ShiftRow(shift: shift, symbol: store.symbol, accent: store.accent)
            }
        }
    }
}
