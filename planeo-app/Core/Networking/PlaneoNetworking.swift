//
//  PlaneoNetworking.swift
//  planeo-app
//
//  DTOs — nonisolated pour éviter les warnings @MainActor Swift 6.
//

import Foundation

// MARK: - Auth

// Le gateway ne renvoie plus de JWT : uniquement l'utilisateur, la session est dans un cookie.
struct LoginResponse: Decodable {
    let username: String
    let role: String
}

// MARK: - Balance

nonisolated struct BalanceDTO: Decodable {
    let id: Int?
    let currentBalance: Double
    let futureBalance: Double
    let pendingExpense: Double
}

// MARK: - Expense

nonisolated struct ExpenseDTO: Decodable {
    let id: Int
    let amount: Double
    let tag: String
    let status: String
    let date: String
    let label: String
    let recurring: Bool

    func toExpense() -> Expense {
        let cat = Tag.from(tag)?.label ?? tag
        return Expense(
            id: id,
            amount: amount,
            cat: cat,
            status: ExpenseStatus.from(status),
            date: date,
            label: label,
            recurring: recurring
        )
    }
}

nonisolated struct ExpensePerMonthDTO: Decodable {
    let month: Int
    let amount: Double
}

nonisolated struct ExpenseAmountByTagDTO: Decodable {
    let tag: String
    let total: Double
}

nonisolated struct ExpensesByTagsDTO: Decodable {
    let tag: String
    let expenses: [ExpenseDTO]
}

// MARK: - Create expense body

nonisolated struct ExpenseCreateRequest: Encodable {
    let amount: Double
    let tag: String       // Java name() e.g. "RESTAURANT"
    let status: String    // "PROCESSED" ou "PENDING"
    let date: String      // "yyyy-MM-dd"
    let label: String
    let recurring: Bool
}
