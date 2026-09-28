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

// MARK: - Tag enum (maps Java name())

enum Tag: String, CaseIterable, Hashable {
    case soiree        = "SOIREE"
    case restaurant    = "RESTAURANT"
    case anniversaire  = "ANNIVERSAIRE"
    case course        = "COURSE"
    case abonnement    = "ABONNEMENT"
    case transport     = "TRANSPORT"
    case investissement = "INVESTISSEMENT"
    case cinema        = "CINEMA"
    case pharmacie     = "PHARMACIE"
    case vetement      = "VETEMENT"
    case coiffeur      = "COIFFEUR"
    case logement      = "LOGEMENT"

    var label: String {
        switch self {
        case .soiree:         return "Soirée"
        case .restaurant:     return "Restaurant"
        case .anniversaire:   return "Anniversaire"
        case .course:         return "Course"
        case .abonnement:     return "Abonnement"
        case .transport:      return "Transport"
        case .investissement: return "Investissement"
        case .cinema:         return "Cinéma"
        case .pharmacie:      return "Pharmacie"
        case .vetement:       return "Vêtement"
        case .coiffeur:       return "Coiffeur"
        case .logement:       return "Logement"
        }
    }

    static func from(_ raw: String) -> Tag? {
        Tag(rawValue: raw.uppercased())
    }
}

// MARK: - Category metadata

struct CategoryMeta {
    let color: Color
    let icon: String
}

enum ExpenseCategory {
    static func meta(for label: String) -> CategoryMeta {
        switch label.lowercased() {
        case "soirée":         return CategoryMeta(color: Color(hex: "9F7AEA"), icon: "music.note")
        case "restaurant":     return CategoryMeta(color: Color(hex: "F6AD55"), icon: "fork.knife")
        case "anniversaire":   return CategoryMeta(color: Color(hex: "FC8181"), icon: "gift")
        case "course":         return CategoryMeta(color: Color(hex: "68D391"), icon: "cart")
        case "abonnement":     return CategoryMeta(color: Color(hex: "4FD1C5"), icon: "repeat")
        case "transport":      return CategoryMeta(color: Color(hex: "63B3ED"), icon: "car")
        case "investissement": return CategoryMeta(color: Color(hex: "48BB78"), icon: "chart.line.uptrend.xyaxis")
        case "cinéma":         return CategoryMeta(color: Color(hex: "ED64A6"), icon: "film")
        case "pharmacie":      return CategoryMeta(color: Color(hex: "FC8181"), icon: "cross.case")
        case "vêtement":       return CategoryMeta(color: Color(hex: "B794F4"), icon: "tshirt")
        case "coiffeur":       return CategoryMeta(color: Color(hex: "F6E05E"), icon: "scissors")
        case "logement":       return CategoryMeta(color: Color(hex: "4FD1C5"), icon: "house")
        default:               return CategoryMeta(color: Color(hex: "A0AEC0"), icon: "questionmark")
        }
    }
}

// MARK: - CategoryGroup (Expenses screen)

struct CategoryGroup: Identifiable {
    let id = UUID()
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
