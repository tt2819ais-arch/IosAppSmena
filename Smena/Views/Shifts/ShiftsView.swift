import SwiftUI

struct ShiftsView: View {
    @EnvironmentObject var store: AppStore
    @State private var showAdd = false
    @State private var editing: Shift?

    var body: some View {
        ZStack {
            AppBackground(accent: store.accent)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    headerStats
                    if store.shifts.isEmpty {
                        EmptyState(icon: "calendar.badge.plus",
                                   title: "Пока нет смен",
                                   subtitle: "Добавь первую смену — приложение посчитает часы и заработок.")
                            .padding(.top, 40)
                    } else {
                        ForEach(store.shiftsByMonth(), id: \.key) { group in
                            monthSection(group.key, group.shifts)
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }

            floatingAdd
        }
        .sheet(isPresented: $showAdd) { AddShiftView() }
        .sheet(item: $editing) { shift in AddShiftView(editing: shift) }
    }

    private var headerStats: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Смены")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                Spacer()
            }
            HStack(spacing: 14) {
                miniStat("\(store.shiftsCount)", Fmt.shiftsWord(store.shiftsCount))
                miniStat(Fmt.duration(hours: store.totalHours), "часов")
                miniStat(Fmt.money(store.totalShiftEarnings, symbol: store.symbol), "заработок")
            }
        }
        .padding(.top, 8)
    }

    private func miniStat(_ value: String, _ caption: String) -> some View {
        GlassCard(padding: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .lineLimit(1).minimumScaleFactor(0.6)
                Text(caption)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func monthSection(_ month: Date, _ shifts: [Shift]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(Fmt.monthYear(month))
                    .font(.system(.headline, design: .rounded).weight(.bold))
                Spacer()
                Text(Fmt.money(store.earnings(in: month), symbol: store.symbol))
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(store.accent.primary)
            }
            .padding(.horizontal, 4)

            ForEach(shifts) { shift in
                Button { Haptics.light(); editing = shift } label: {
                    ShiftRow(shift: shift, symbol: store.symbol, accent: store.accent)
                }
                .buttonStyle(PressableStyle())
                .contextMenu {
                    Button(role: .destructive) { store.deleteShift(shift) } label: {
                        Label("Удалить", systemImage: "trash")
                    }
                }
            }
        }
    }

    private var floatingAdd: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button { Haptics.light(); showAdd = true } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 60, height: 60)
                        .background(store.accent.gradient, in: Circle())
                        .shadow(color: store.accent.primary.opacity(0.5), radius: 14, y: 8)
                }
                .buttonStyle(PressableStyle())
                .padding(.trailing, 22)
                .padding(.bottom, 18)
            }
        }
    }
}

struct EmptyState: View {
    let icon: String
    let title: String
    let subtitle: String
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 46, weight: .light))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.system(.title3, design: .rounded).weight(.bold))
            Text(subtitle)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
    }
}
