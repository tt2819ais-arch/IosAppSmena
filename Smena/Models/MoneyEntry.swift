import Foundation

enum EntryKind: String, Codable, CaseIterable {
    case income
    case expense

    var title: String {
        switch self {
        case .income: return "Доход"
        case .expense: return "Расход"
        }
    }

    var systemImage: String {
        switch self {
        case .income: return "arrow.down.circle.fill"
        case .expense: return "arrow.up.circle.fill"
        }
    }
}

/// An arbitrary extra income or expense (not tied to a shift).
struct MoneyEntry: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var date: Date
    var amount: Double          // always stored positive
    var kind: EntryKind
    var note: String = ""

    /// Signed contribution to the balance.
    var signedAmount: Double {
        kind == .income ? amount : -amount
    }
}
