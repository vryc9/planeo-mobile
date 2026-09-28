//
//  DashboardViewModel.swift
//  planeo-app
//

import Foundation
import Observation

@Observable final class DashboardViewModel {
    var balance: BalanceDTO?
    var expenses: [Expense] = []
    var monthlyData: [ExpensePerMonthDTO] = []
    var categoryAmounts: [ExpenseAmountByCategoryDTO] = []
    var accounts: [Account] = []
    var isLoading = false
    var error: String?

    var soldeActuel: Double  { balance?.currentBalance  ?? 0 }
    var soldeAVenir: Double  { balance?.futureBalance   ?? 0 }
    var resteAPayer: Double  { balance?.pendingExpense  ?? 0 }

    var recentExpenses: [Expense] {
        expenses.sorted { $0.date > $1.date }.prefix(5).map { $0 }
    }

    var lineValues: [Double] { monthlyData.map(\.amount) }
    var lineLabels: [String] {
        let names = ["Jan","Fév","Mar","Avr","Mai","Jun","Jul","Aoû","Sep","Oct","Nov","Déc"]
        return monthlyData.map { names[max(0, ($0.month - 1) % 12)] }
    }

    var donutSlices: [DonutChart.Slice] {
        categoryAmounts.enumerated().map { i, t in
            .init(label: t.category.name,
                  value: t.total,
                  color: Format.donutColor(index: i))
        }
    }

    var donutTotal: Double { categoryAmounts.reduce(0) { $0 + $1.total } }

    func load() async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            async let bal: BalanceDTO              = APIClient.shared.request(.balance)
            async let exp: [ExpenseDTO]            = APIClient.shared.request(.expenses)
            async let month: [ExpensePerMonthDTO]  = APIClient.shared.request(.expenseMonth)
            async let amount: [ExpenseAmountByCategoryDTO] = APIClient.shared.request(.expenseAmountByCategory)
            async let accs: [AccountDTO] = APIClient.shared.request(.accounts)

            let (b, e, m, a, ac) = try await (bal, exp, month, amount, accs)
            balance = b
            expenses = e.map { $0.toExpense() }
            monthlyData = m
            categoryAmounts = a
            accounts = ac.map { $0.toAccount() }

            // Mise à jour du cache widget
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
