//
//  AddExpenseViewModel.swift
//  planeo-app
//

import Foundation
import Observation

@Observable final class AddExpenseViewModel {
    var isIncome = false
    var selectedTag: Tag?
    var label = ""
    var amountText = ""
    var date = Date()
    var isSubmitting = false
    var errorMessage: String?

    var amount: Double? { Double(amountText.replacingOccurrences(of: ",", with: ".")) }

    var dateDisplay: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateStyle = .medium
        return f.string(from: date)
    }

    var isValid: Bool {
        let hasAmount = amount != nil
        let hasLabel  = !label.trimmingCharacters(in: .whitespaces).isEmpty
        // En mode revenu : seul le montant est obligatoire
        return isIncome ? hasAmount : (hasLabel && hasAmount && selectedTag != nil)
    }

    // MARK: - Submit

    @discardableResult
    func submit() async -> Bool {
        isIncome ? await submitIncome() : await submitExpense()
    }

    private func submitIncome() async -> Bool {
        guard let a = amount else { return false }
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }
        do {
            // PUT /api/balance — corps = BigDecimal brut
            let _: BalanceDTO = try await APIClient.shared.request(.updateBalance(amount: a))
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func submitExpense() async -> Bool {
        guard let a = amount, let tag = selectedTag else { return false }
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        // Statut : passé → PROCESSED, futur → PENDING
        let today = Calendar.current.startOfDay(for: Date())
        let day   = Calendar.current.startOfDay(for: date)
        let status = day <= today ? "PROCESSED" : "PENDING"

        let body = ExpenseCreateRequest(
            amount: a,
            tag: tag.rawValue,
            status: status,
            date: Format.isoDate(date),
            label: label.trimmingCharacters(in: .whitespaces),
            recurring: false
        )
        do {
            let _: ExpenseDTO = try await APIClient.shared.request(.createExpense(body: body))
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
