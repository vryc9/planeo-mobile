//
//  AddExpenseViewModel.swift
//  planeo-app
//

import Foundation
import Observation

@Observable final class AddExpenseViewModel {
    var isIncome = false
    var categories: [PlaneoCategory] = []
    var accounts: [Account] = []
    var selectedCategory: PlaneoCategory?
    var selectedAccountId: Int?
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
        let hasAccount = selectedAccountId != nil
        // Revenu : montant + banque à créditer ; dépense : libellé, montant, catégorie, banque
        return isIncome ? (hasAmount && hasAccount)
                        : (hasLabel && hasAmount && selectedCategory != nil && hasAccount)
    }

    // MARK: - Chargement des listes (catégories, banques)

    func load() async {
        async let cats: [CategoryDTO] = APIClient.shared.request(.categories)
        async let accs: [AccountDTO]  = APIClient.shared.request(.accounts)
        do {
            let (c, a) = try await (cats, accs)
            categories = c.compactMap { $0.toCategory() }
            accounts = a.map { $0.toAccount() }
            if selectedAccountId == nil { selectedAccountId = accounts.first?.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Submit

    @discardableResult
    func submit() async -> Bool {
        isIncome ? await submitIncome() : await submitExpense()
    }

    private func submitIncome() async -> Bool {
        guard let a = amount, let accountId = selectedAccountId else { return false }
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }
        do {
            // PUT /api/balance — crédite la banque choisie
            let _: BalanceDTO = try await APIClient.shared.request(
                .deposit(body: DepositRequest(amount: a, accountId: accountId))
            )
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func submitExpense() async -> Bool {
        guard let a = amount, let category = selectedCategory else { return false }
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        // Statut : passé → PROCESSED, futur → PENDING
        let today = Calendar.current.startOfDay(for: Date())
        let day   = Calendar.current.startOfDay(for: date)
        let status = day <= today ? "PROCESSED" : "PENDING"

        let body = ExpenseCreateRequest(
            amount: a,
            category: CategoryDTO(id: category.id, name: category.name, icon: category.icon),
            status: status,
            date: Format.isoDate(date),
            label: label.trimmingCharacters(in: .whitespaces),
            recurring: false,
            accountId: selectedAccountId
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
