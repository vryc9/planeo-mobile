//
//  PlaneoModels.swift
//  planeo-app
//

import SwiftUI

// MARK: - Expense

struct Expense: Identifiable {
    let id: Int
    let amount: Double
    let cat: String
    let status: ExpenseStatus
    let date: String   // ISO "2026-06-15"
    let label: String
    var recurring: Bool = false
    var catIcon: String = ""
    var categoryId: Int? = nil
    var accountId: Int? = nil
}

enum ExpenseStatus {
    case pending, paid

    static func from(_ value: String) -> ExpenseStatus {
        switch value.uppercased() {
        case "PROCESSED": return .paid
        case "PENDING":   return .pending
        default:          return .pending
        }
    }
}

// MARK: - Catégorie (catégories dynamiques, propres à chaque utilisateur)

struct PlaneoCategory: Identifiable, Hashable {
    let id: Int
    let name: String
    let icon: String
}

// MARK: - Account (banque)

struct Account: Identifiable, Hashable {
    let id: Int
    let label: String
    let amount: Double
    let logo: String
}

// MARK: - Category metadata

struct CategoryMeta {
    let color: Color
    let icon: String
}

/// Icônes proposées à la création d'une catégorie : clé stockée côté API → SF Symbol.
enum CategoryIcon {
    static let options: [(key: String, symbol: String)] = [
        ("restaurant", "fork.knife"), ("course", "cart"), ("transport", "car"),
        ("logement", "house"), ("abonnement", "repeat"), ("cinema", "film"),
        ("soiree", "music.note"), ("anniversaire", "gift"), ("pharmacie", "cross.case"),
        ("vetement", "tshirt"), ("coiffeur", "scissors"), ("investissement", "chart.line.uptrend.xyaxis"),
        ("sante", "heart"), ("sport", "figure.run"), ("voyage", "airplane"),
        ("loisirs", "gamecontroller"), ("education", "book"), ("cadeau", "gift.fill"),
        ("animaux", "pawprint"), ("telephone", "phone"), ("cafe", "cup.and.saucer"),
        ("factures", "doc.text"), ("epargne", "banknote"), ("autre", "tag"),
    ]

    /// SF Symbol correspondant à la valeur `icon` renvoyée par l'API (clé connue ou nom de symbole valide).
    static func symbol(for raw: String) -> String? {
        let key = raw.trimmingCharacters(in: .whitespaces)
        guard !key.isEmpty else { return nil }
        if let match = options.first(where: { $0.key == key.lowercased() }) { return match.symbol }
        if UIImage(systemName: key) != nil { return key }
        return nil
    }

    static func isEmoji(_ raw: String) -> Bool {
        guard let first = raw.unicodeScalars.first else { return false }
        return first.properties.isEmojiPresentation || (first.properties.isEmoji && first.value > 0x238C)
    }
}

enum ExpenseCategory {
    private static let palette = ["9F7AEA", "F6AD55", "FC8181", "68D391", "4FD1C5", "63B3ED",
                                  "ED64A6", "B794F4", "F6E05E", "48BB78", "F687B3", "7F9CF5"]

    /// Couleur stable dérivée du nom (les catégories n'étant plus une liste fixe).
    private static func color(for label: String) -> Color {
        let h = label.lowercased().unicodeScalars.reduce(UInt(5381)) { ($0 &* 33) &+ UInt($1.value) }
        return Color(hex: palette[Int(h % UInt(palette.count))])
    }

    static func meta(for label: String, icon: String? = nil) -> CategoryMeta {
        let symbol = icon.flatMap(CategoryIcon.symbol(for:))
            ?? CategoryIcon.symbol(for: label.folding(options: .diacriticInsensitive, locale: nil))
            ?? "tag"
        return CategoryMeta(color: color(for: label), icon: symbol)
    }
}

// MARK: - CategoryGroup (Expenses screen)

struct CategoryGroup: Identifiable {
    var id: String { label }
    let label: String
    let expenses: [Expense]
    var count: Int { expenses.count }
    var total: Double { expenses.reduce(0) { $0 + $1.amount } }
}

// MARK: - Format helpers

enum Format {
    static func eur(_ n: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        f.groupingSeparator = " "
        f.decimalSeparator = ","
        return (f.string(from: NSNumber(value: n)) ?? "0,00") + " €"
    }

    static func eurCompact(_ n: Double) -> String {
        if abs(n) >= 1000 {
            let k = n / 1000
            let f = NumberFormatter()
            f.minimumFractionDigits = 0
            f.maximumFractionDigits = 1
            f.decimalSeparator = ","
            return (f.string(from: NSNumber(value: k)) ?? "0") + "k €"
        }
        return eur(n)
    }

    static func dateShortFR(_ iso: String) -> String {
        let parts = iso.split(separator: "-")
        guard parts.count == 3 else { return iso }
        let months = ["jan","fév","mar","avr","mai","jun","jul","aoû","sep","oct","nov","déc"]
        let m = Int(parts[1]) ?? 1
        return "\(parts[2]) \(months[max(0, m-1)]) \(parts[0])"
    }

    static func dateFullFR(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "EEEE d MMMM yyyy"
        return f.string(from: date).capitalized
    }

    static func isoDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    static func donutColor(index: Int) -> Color {
        let palette: [String] = ["4fd1c5","81e6d9","2c9c92","38b2ac","4fd1c5",
                                 "68d8d1","9decdf","b2f5ea","2b8280","1a6b69"]
        return Color(hex: palette[index % palette.count])
    }
}

// MARK: - Mock data (dev / preview)

enum MockData {
    static let expenses: [Expense] = [
        Expense(id: 1, amount: 42.50, cat: "Restaurant", status: .paid,    date: "2026-06-10", label: "Déjeuner Léa"),
        Expense(id: 2, amount: 9.99,  cat: "Abonnement", status: .paid,    date: "2026-06-01", label: "Netflix"),
        Expense(id: 3, amount: 120.0, cat: "Vêtement",   status: .pending, date: "2026-06-25", label: "Commande Zara"),
        Expense(id: 4, amount: 55.0,  cat: "Transport",  status: .paid,    date: "2026-06-08", label: "Essence"),
        Expense(id: 5, amount: 200.0, cat: "Logement",   status: .pending, date: "2026-07-01", label: "Loyer juillet"),
    ]
}
