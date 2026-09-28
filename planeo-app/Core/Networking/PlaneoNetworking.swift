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

// MARK: - Category

nonisolated struct CategoryDTO: Codable {
    let id: Int?
    let name: String
    let icon: String

    func toCategory() -> PlaneoCategory? {
        guard let id else { return nil }
        return PlaneoCategory(id: id, name: name, icon: icon)
    }
}

nonisolated struct CategoryCreateRequest: Encodable {
    let name: String
    let icon: String
}

// MARK: - Account (banque)

nonisolated struct AccountDTO: Decodable {
    let id: Int
    let label: String
    let amount: Double
    let logo: String?

    func toAccount() -> Account {
        Account(id: id, label: label, amount: amount, logo: logo ?? "")
    }
}

nonisolated struct AccountCreateRequest: Encodable {
    let label: String
    let amount: Double
    let logo: String
}

nonisolated struct TransferRequest: Encodable {
    let accountOriginId: Int
    let accountTargetId: Int
    let amount: Double
}

nonisolated struct DepositRequest: Encodable {
    let amount: Double
    let accountId: Int
}

// MARK: - Expense

nonisolated struct ExpenseDTO: Codable {
    let id: Int
    let amount: Double
    let category: CategoryDTO
    let status: String
    let date: String
    let label: String
    let recurring: Bool
    let accountId: Int?

    func toExpense() -> Expense {
        Expense(
            id: id,
            amount: amount,
            cat: category.name,
            status: ExpenseStatus.from(status),
            date: date,
            label: label,
            recurring: recurring,
            catIcon: category.icon,
            categoryId: category.id,
            accountId: accountId
        )
    }
}

nonisolated struct ExpensePerMonthDTO: Decodable {
    let month: Int
    let amount: Double
}

nonisolated struct ExpenseAmountByCategoryDTO: Decodable {
    let category: CategoryDTO
    let total: Double
}

// MARK: - Create expense body

nonisolated struct ExpenseCreateRequest: Encodable {
    let amount: Double
    let category: CategoryDTO
    let status: String    // "PROCESSED" ou "PENDING"
    let date: String      // "yyyy-MM-dd"
    let label: String
    let recurring: Bool
    let accountId: Int?
}
