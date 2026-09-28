//
//  CalendarViewModel.swift
//  planeo-app
//

import Foundation
import Observation

@Observable final class CalendarViewModel {
    var expensesByDate: [String: [Expense]] = [:]
    var isLoading = false
    var error: String?

    func load() async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            let dtos: [ExpenseDTO] = try await APIClient.shared.request(.expenses)
            var dict: [String: [Expense]] = [:]
            for dto in dtos {
                let e = dto.toExpense()
                dict[e.date, default: []].append(e)
            }
            expensesByDate = dict
        } catch {
            self.error = error.localizedDescription
        }
    }
}
