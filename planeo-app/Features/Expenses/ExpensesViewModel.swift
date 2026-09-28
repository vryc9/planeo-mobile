//
//  ExpensesViewModel.swift
//  planeo-app
//

import Foundation
import Observation

@Observable final class ExpensesViewModel {
    var expenses: [Expense] = []
    var balance: BalanceDTO?
    var isLoading = false
    var error: String?

    var aVenirCount: Int    { expenses.filter { $0.status == .pending }.count }
    var totalDepense: Double { expenses.filter { $0.status == .paid }.reduce(0) { $0 + $1.amount } }
    var soldeActuel: Double  { balance?.currentBalance  ?? 0 }
    var soldeAVenir: Double  { balance?.futureBalance   ?? 0 }
    var resteAPayer: Double  { balance?.pendingExpense  ?? 0 }

    var categories: [CategoryGroup] {
        var dict: [String: [Expense]] = [:]
        for e in expenses { dict[e.cat, default: []].append(e) }
        return dict.map { key, vals in
            CategoryGroup(label: key, expenses: vals.sorted { $0.date > $1.date })
        }
        .sorted { $0.total > $1.total }
    }

    func delete(_ e: Expense) async -> Bool {
        guard let categoryId = e.categoryId else { return false }
        let dto = ExpenseDTO(
            id: e.id, amount: e.amount,
            category: CategoryDTO(id: categoryId, name: e.cat, icon: e.catIcon),
            status: e.status == .paid ? "PROCESSED" : "PENDING",
            date: e.date, label: e.label, recurring: e.recurring, accountId: e.accountId
        )
        do {
            try await APIClient.shared.send(.deleteExpense(body: dto))
            expenses.removeAll { $0.id == e.id }
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    func load() async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            async let bal: BalanceDTO   = APIClient.shared.request(.balance)
            async let exp: [ExpenseDTO] = APIClient.shared.request(.expenses)
            let (b, e) = try await (bal, exp)
            balance = b
            expenses = e.map { $0.toExpense() }
            SharedStore.save(BalanceSnapshot(
                soldeActuel: b.currentBalance,
                soldeAVenir: b.futureBalance,
                resteAPayer: b.pendingExpense,
                updatedAt: Date()
            ))
        } catch {
            self.error = error.localizedDescription
        }
    }
}
