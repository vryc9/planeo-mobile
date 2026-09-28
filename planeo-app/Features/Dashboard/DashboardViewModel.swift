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
    var tagAmounts: [ExpenseAmountByTagDTO] = []
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
        tagAmounts.enumerated().map { i, t in
            .init(label: Tag.from(t.tag)?.label ?? t.tag,
                  value: t.total,
                  color: Format.donutColor(index: i))
        }
    }

    var donutTotal: Double { tagAmounts.reduce(0) { $0 + $1.total } }

    func load() async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            async let bal: BalanceDTO              = APIClient.shared.request(.balance)
            async let exp: [ExpenseDTO]            = APIClient.shared.request(.expenses)
            async let month: [ExpensePerMonthDTO]  = APIClient.shared.request(.expenseMonth)
            async let amount: [ExpenseAmountByTagDTO] = APIClient.shared.request(.expenseAmount)

            let (b, e, m, a) = try await (bal, exp, month, amount)
            balance = b
            expenses = e.map { $0.toExpense() }
            monthlyData = m
            tagAmounts = a

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
