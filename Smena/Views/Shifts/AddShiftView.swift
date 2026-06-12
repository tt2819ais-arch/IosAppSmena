import SwiftUI

struct AddShiftView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    var editing: Shift? = nil

    @State private var date = Date()
    @State private var start = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var end = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var rateText = ""
    @State private var breakMinutes = 0
    @State private var note = ""

    @State private var saved = false
    @State private var savedShift: Shift?

    private var rate: Double { Double(rateText.replacingOccurrences(of: ",", with: ".")) ?? store.settings.defaultHourlyRate }

    private var previewShift: Shift {
        Shift(date: date,
              startMinutes: minutes(from: start),
              endMinutes: minutes(from: end),
              hourlyRate: rate,
              breakMinutes: breakMinutes,
              note: note)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraBackground(accent: store.accent)
                if saved, let s = savedShift {
                    SavedShiftView(shift: s, store: store) { dismiss() }
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                } else {
                    form
                }
            }
            .navigationTitle(editing == nil ? "Новая смена" : "Смена")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                if let editing {
                    ToolbarItem(placement: .destructiveAction) {
                        Button(role: .destructive) {
                            store.deleteShift(editing); dismiss()
                        } label: { Image(systemName: "trash") }
                    }
                }
            }
            .onAppear(perform: prefill)
        }
    }

    private var form: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                livePreview

                GlassCard {
                    VStack(spacing: 4) {
                        DatePicker("Дата", selection: $date, displayedComponents: .date)
                            .datePickerStyle(.compact)
                        Divider().padding(.vertical, 6)
                        DatePicker("Начало", selection: $start, displayedComponents: .hourAndMinute)
                        Divider().padding(.vertical, 6)
                        DatePicker("Конец", selection: $end, displayedComponents: .hourAndMinute)
                    }
                    .font(.system(.body, design: .rounded))
                }

                GlassCard {
                    VStack(spacing: 12) {
                        HStack {
                            Label("Ставка в час", systemImage: "tag.fill")
                                .font(.system(.body, design: .rounded))
                            Spacer()
                            TextField("\(Int(store.settings.defaultHourlyRate))", text: $rateText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .font(.system(.body, design: .rounded).weight(.semibold))
                                .frame(width: 90)
                            Text(store.symbol).foregroundStyle(.secondary)
                        }
                        Divider()
                        Stepper(value: $breakMinutes, in: 0...240, step: 15) {
                            HStack {
                                Label("Перерыв", systemImage: "pause.circle.fill")
                                    .font(.system(.body, design: .rounded))
                                Spacer()
                                Text(breakMinutes == 0 ? "нет" : "\(breakMinutes) мин")
                                    .foregroundStyle(.secondary)
                                    .font(.system(.subheadline, design: .rounded))
                            }
                        }
                    }
                }

                GlassCard {
                    HStack {
                        Label("Заметка", systemImage: "text.alignleft")
                            .font(.system(.body, design: .rounded))
                        Spacer()
                        TextField("необязательно", text: $note)
                            .multilineTextAlignment(.trailing)
                            .font(.system(.subheadline, design: .rounded))
                    }
                }

                projection

                PrimaryButton(title: editing == nil ? "Сохранить смену" : "Сохранить изменения",
                              systemImage: "checkmark", gradient: store.accent.gradient) {
                    saveShift()
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
        }
    }

    private var livePreview: some View {
        GlassCard {
            HStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Отработано")
                        .font(.system(.caption, design: .rounded)).foregroundStyle(.secondary)
                    Text(Fmt.duration(hours: previewShift.workedHours))
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .contentTransition(.numericText())
                }
                Spacer()
                Rectangle().fill(Color.primary.opacity(0.1)).frame(width: 1, height: 40)
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Заработок")
                        .font(.system(.caption, design: .rounded)).foregroundStyle(.secondary)
                    Text(Fmt.money(previewShift.earnings, symbol: store.symbol))
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundStyle(store.accent.primary)
                        .contentTransition(.numericText())
                }
            }
        }
    }

    private var projection: some View {
        let current = store.earnedTowardGoal - (editing?.earnings ?? 0)
        let projected = current + previewShift.earnings
        let remaining = max(store.settings.goalAmount - projected, 0)
        let pct = store.settings.goalAmount > 0 ? min(projected / store.settings.goalAmount, 1) : 0
        return GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Label("После этой смены", systemImage: "target")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(.secondary)
                ProgressView(value: pct)
                    .tint(store.accent.primary)
                HStack {
                    Text("Заработано: \(Fmt.money(projected, symbol: store.symbol))")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    Spacer()
                    Text("осталось \(Fmt.money(remaining, symbol: store.symbol))")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Logic

    private func prefill() {
        guard let editing else {
            if rateText.isEmpty { rateText = trimmed(store.settings.defaultHourlyRate) }
            return
        }
        date = editing.date
        start = dateFrom(minutes: editing.startMinutes, on: editing.date)
        end = dateFrom(minutes: editing.endMinutes, on: editing.date)
        rateText = trimmed(editing.hourlyRate)
        breakMinutes = editing.breakMinutes
        note = editing.note
    }

    private func saveShift() {
        var shift = previewShift
        if let editing { shift.id = editing.id }
        if editing == nil { store.addShift(shift) } else { store.updateShift(shift) }
        savedShift = shift
        if editing == nil {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { saved = true }
        } else {
            dismiss()
        }
    }

    private func minutes(from date: Date) -> Int {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }
    private func dateFrom(minutes: Int, on day: Date) -> Date {
        Calendar.current.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: day) ?? day
    }
    private func trimmed(_ v: Double) -> String {
        v == v.rounded() ? String(Int(v)) : String(v)
    }
}

/// Satisfying confirmation shown right after a shift is saved.
struct SavedShiftView: View {
    let shift: Shift
    let store: AppStore
    let onDone: () -> Void

    @State private var appear = false

    var body: some View {
        VStack(spacing: 22) {
            ZStack {
                Circle().fill(store.accent.primary.opacity(0.18)).frame(width: 120, height: 120)
                Image(systemName: "checkmark")
                    .font(.system(size: 50, weight: .bold))
                    .foregroundStyle(store.accent.primary)
                    .scaleEffect(appear ? 1 : 0.4)
            }

            VStack(spacing: 6) {
                Text("Смена записана!")
                    .font(.system(.title2, design: .rounded).weight(.bold))
                Text("+\(Fmt.money(shift.earnings, symbol: store.symbol)) · \(Fmt.duration(hours: shift.workedHours))")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(store.accent.primary)
            }

            GlassCard {
                VStack(spacing: 14) {
                    row("Всего заработано", Fmt.money(store.earnedTowardGoal, symbol: store.symbol))
                    Divider()
                    row("До цели осталось", Fmt.money(store.goalRemaining, symbol: store.symbol))
                    Divider()
                    row("Выполнено цели", "\(Int((store.goalProgress * 100).rounded()))%")
                    ProgressView(value: store.goalProgress).tint(store.accent.primary)
                }
            }
            .padding(.horizontal, 18)

            PrimaryButton(title: "Готово", systemImage: "hand.thumbsup.fill", gradient: store.accent.gradient) {
                onDone()
            }
            .padding(.horizontal, 18)
        }
        .padding(.vertical, 30)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.55)) { appear = true }
            Haptics.success()
        }
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).font(.system(.subheadline, design: .rounded)).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.system(.headline, design: .rounded).weight(.bold))
        }
    }
}
