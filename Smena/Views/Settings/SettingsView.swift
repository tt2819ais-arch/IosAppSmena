import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: AppStore
    @State private var goalText = ""
    @State private var rateText = ""
    @State private var showResetConfirm = false

    private let currencyPresets = ["₽", "$", "€", "₸", "₴", "£", "¥", "Br"]

    var body: some View {
        ZStack {
            AppBackground(accent: store.accent)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    header
                    appearanceCard
                    goalCard
                    rateCurrencyCard
                    payoutCard
                    dataCard
                    aboutFooter
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .keyboardDoneToolbar()
        .onAppear {
            goalText = trimmed(store.settings.goalAmount)
            rateText = trimmed(store.settings.defaultHourlyRate)
        }
        .alert("Удалить все данные?", isPresented: $showResetConfirm) {
            Button("Отмена", role: .cancel) {}
            Button("Удалить", role: .destructive) {
                store.shifts = []; store.entries = []
                Haptics.warning()
            }
        } message: {
            Text("Будут удалены все смены, доходы и расходы. Настройки сохранятся.")
        }
    }

    private var header: some View {
        HStack {
            Text("Настройки")
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
            Spacer()
        }
        .padding(.top, 8)
    }

    // MARK: Appearance

    private var appearanceCard: some View {
        SettingsCard(title: "Оформление", icon: "paintbrush.fill") {
            VStack(alignment: .leading, spacing: 16) {
                Picker("Фон", selection: $store.settings.appearance) {
                    ForEach(Appearance.allCases, id: \.self) { a in
                        Label(a.title, systemImage: a.icon).tag(a)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: store.settings.appearance) { _ in Haptics.selection() }

                Text(store.settings.appearance == .aurora
                     ? "Живой фон мягко реагирует на наклон телефона."
                     : "Спокойный однотонный фон.")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)

                Divider()

                Text("Акцент").font(.system(.subheadline, design: .rounded)).foregroundStyle(.secondary)
                HStack(spacing: 14) {
                    ForEach(AccentTone.allCases, id: \.self) { tone in
                        Button {
                            Haptics.selection(); store.settings.accent = tone
                        } label: {
                            Circle()
                                .fill(tone.gradient)
                                .frame(width: 32, height: 32)
                                .overlay(Circle().strokeBorder(Color.primary.opacity(0.9),
                                                               lineWidth: store.accent == tone ? 3 : 0))
                        }
                        .buttonStyle(PressableStyle())
                    }
                }
            }
        }
    }

    // MARK: Goal

    private var goalCard: some View {
        SettingsCard(title: "Денежная цель", icon: "target") {
            VStack(spacing: 14) {
                HStack {
                    Text("Сумма цели").font(.system(.body, design: .rounded))
                    Spacer()
                    TextField("0", text: $goalText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .frame(width: 130)
                        .onChange(of: goalText) { v in
                            store.settings.goalAmount = Double(v.filter(\.isNumber)) ?? 0
                        }
                    Text(store.symbol).foregroundStyle(.secondary)
                }
                Divider()
                Toggle(isOn: $store.settings.goalIncludesExtras) {
                    Text("Учитывать доходы/расходы").font(.system(.subheadline, design: .rounded))
                }
                .tint(store.accent.primary)
            }
        }
    }

    // MARK: Rate + currency

    private var rateCurrencyCard: some View {
        SettingsCard(title: "Ставка и валюта", icon: "tag.fill") {
            VStack(spacing: 14) {
                HStack {
                    Text("Ставка по умолчанию").font(.system(.body, design: .rounded))
                    Spacer()
                    TextField("0", text: $rateText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .frame(width: 100)
                        .onChange(of: rateText) { v in
                            store.settings.defaultHourlyRate = Double(v.replacingOccurrences(of: ",", with: ".")) ?? 0
                        }
                    Text("\(store.symbol)/ч").foregroundStyle(.secondary)
                }
                Divider()
                VStack(alignment: .leading, spacing: 10) {
                    Text("Валюта").font(.system(.body, design: .rounded))
                    HStack(spacing: 8) {
                        ForEach(currencyPresets, id: \.self) { sym in
                            Button {
                                Haptics.selection(); store.settings.currencySymbol = sym
                            } label: {
                                Text(sym)
                                    .font(.system(.headline, design: .rounded).weight(.semibold))
                                    .frame(width: 36, height: 36)
                                    .background(store.symbol == sym ? store.accent.primary.opacity(0.18) : Color.primary.opacity(0.05),
                                                in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    .foregroundStyle(store.symbol == sym ? store.accent.primary : .primary)
                            }
                            .buttonStyle(PressableStyle())
                        }
                    }
                }
            }
        }
    }

    // MARK: Payout days

    private var payoutCard: some View {
        SettingsCard(title: "График выплат · 2 раза в месяц", icon: "calendar.badge.clock") {
            VStack(spacing: 14) {
                dayPicker("Первая выплата", selection: $store.settings.payoutDay1)
                Divider()
                dayPicker("Вторая выплата", selection: $store.settings.payoutDay2)
                Text("Если в месяце меньше дней, выплата сместится на последний день.")
                    .font(.system(.caption, design: .rounded)).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func dayPicker(_ title: String, selection: Binding<Int>) -> some View {
        HStack {
            Text(title).font(.system(.body, design: .rounded))
            Spacer()
            Picker(title, selection: selection) {
                ForEach(1...28, id: \.self) { d in Text("\(d) число").tag(d) }
            }
            .pickerStyle(.menu)
            .tint(store.accent.primary)
        }
    }

    // MARK: Data

    private var dataCard: some View {
        SettingsCard(title: "Данные", icon: "externaldrive.fill") {
            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                HStack {
                    Label("Удалить все смены и записи", systemImage: "trash")
                        .font(.system(.body, design: .rounded))
                    Spacer()
                }
                .foregroundStyle(Color(hex: 0xFF5C6E))
            }
        }
    }

    private var aboutFooter: some View {
        VStack(spacing: 4) {
            Text("Аванс").font(.system(.subheadline, design: .rounded).weight(.bold))
            Text("Учёт смен и зарплаты · v1.0")
                .font(.system(.caption, design: .rounded)).foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }

    private func trimmed(_ v: Double) -> String { v == v.rounded() ? String(Int(v)) : String(v) }
}

struct SettingsCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
            GlassCard { content() }
        }
    }
}
