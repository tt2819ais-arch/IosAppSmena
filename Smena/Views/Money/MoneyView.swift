import SwiftUI

struct MoneyView: View {
    @EnvironmentObject var store: AppStore
    @State private var showAdd = false
    @State private var editing: MoneyEntry?

    var body: some View {
        ZStack {
            AppBackground(accent: store.accent)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    header
                    summary
                    if store.entries.isEmpty {
                        EmptyState(icon: "tray",
                                   title: "Нет доходов и расходов",
                                   subtitle: "Добавляй премии, чаевые, налоги, транспорт — всё, что влияет на баланс.")
                            .padding(.top, 30)
                    } else {
                        ForEach(store.entriesSorted) { entry in
                            Button { Haptics.light(); editing = entry } label: {
                                EntryRow(entry: entry, symbol: store.symbol)
                            }
                            .buttonStyle(PressableStyle())
                            .contextMenu {
                                Button(role: .destructive) { store.deleteEntry(entry) } label: {
                                    Label("Удалить", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }

            floatingAdd
        }
        .sheet(isPresented: $showAdd) { AddEntryView() }
        .sheet(item: $editing) { e in AddEntryView(editing: e) }
    }

    private var header: some View {
        HStack {
            Text("Деньги")
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
            Spacer()
        }
        .padding(.top, 8)
    }

    private var summary: some View {
        HStack(spacing: 14) {
            StatTile(icon: "arrow.down.circle.fill", value: Fmt.money(store.totalIncome, symbol: store.symbol),
                     caption: "Доходы", tint: Color(hex: 0x2FCB6E))
            StatTile(icon: "arrow.up.circle.fill", value: Fmt.money(store.totalExpenses, symbol: store.symbol),
                     caption: "Расходы", tint: Color(hex: 0xFF5C6E))
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
                .padding(.trailing, 22).padding(.bottom, 18)
            }
        }
    }
}

struct EntryRow: View {
    let entry: MoneyEntry
    let symbol: String
    private var tint: Color { entry.kind == .income ? Color(hex: 0x2FCB6E) : Color(hex: 0xFF5C6E) }

    var body: some View {
        GlassCard(padding: 14) {
            HStack(spacing: 14) {
                Image(systemName: entry.kind.systemImage)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 42, height: 42)
                    .background(tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.note.isEmpty ? entry.kind.title : entry.note)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .lineLimit(1)
                    Text(Fmt.dayMonthWeekday(entry.date))
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(entry.kind == .income ? "+" : "−")\(Fmt.money(entry.amount, symbol: symbol))")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(tint)
            }
        }
    }
}
