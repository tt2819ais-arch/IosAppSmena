import SwiftUI

struct AddEntryView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    var editing: MoneyEntry? = nil

    @State private var kind: EntryKind = .income
    @State private var amountText = ""
    @State private var note = ""
    @State private var date = Date()

    private var amount: Double { Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0 }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground(accent: store.accent)
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        Picker("Тип", selection: $kind) {
                            ForEach(EntryKind.allCases, id: \.self) { k in
                                Text(k.title).tag(k)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: kind) { _ in Haptics.selection() }

                        GlassCard {
                            HStack {
                                Text("Сумма")
                                    .font(.system(.body, design: .rounded))
                                Spacer()
                                TextField("0", text: $amountText)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .font(.system(.title3, design: .rounded).weight(.bold))
                                    .frame(width: 130)
                                Text(store.symbol).foregroundStyle(.secondary)
                            }
                        }

                        GlassCard {
                            VStack(spacing: 4) {
                                DatePicker("Дата", selection: $date, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                Divider().padding(.vertical, 6)
                                HStack {
                                    Label("Заметка", systemImage: "text.alignleft")
                                    Spacer()
                                    TextField("например, премия", text: $note)
                                        .multilineTextAlignment(.trailing)
                                        .font(.system(.subheadline, design: .rounded))
                                }
                            }
                            .font(.system(.body, design: .rounded))
                        }

                        PrimaryButton(title: editing == nil ? "Добавить" : "Сохранить",
                                      systemImage: "checkmark", gradient: store.accent.gradient) {
                            save()
                        }
                        .disabled(amount <= 0)
                        .opacity(amount <= 0 ? 0.5 : 1)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle(editing == nil ? "Доход / расход" : "Запись")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
                if let editing {
                    ToolbarItem(placement: .destructiveAction) {
                        Button(role: .destructive) { store.deleteEntry(editing); dismiss() } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
            .onAppear(perform: prefill)
            .keyboardDoneToolbar()
        }
    }

    private func prefill() {
        guard let editing else { return }
        kind = editing.kind
        amountText = editing.amount == editing.amount.rounded() ? String(Int(editing.amount)) : String(editing.amount)
        note = editing.note
        date = editing.date
    }

    private func save() {
        guard amount > 0 else { return }
        var entry = MoneyEntry(date: date, amount: amount, kind: kind, note: note)
        if let editing {
            entry.id = editing.id
            store.updateEntry(entry)
        } else {
            store.addEntry(entry)
        }
        dismiss()
    }
}
