//
//  AccountsViewModel.swift
//  planeo-app
//

import Foundation
import Observation

@Observable final class AccountsViewModel {
    var accounts: [Account] = []
    var isLoading = false
    var error: String?

    var total: Double { accounts.reduce(0) { $0 + $1.amount } }

    func load() async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            let dtos: [AccountDTO] = try await APIClient.shared.request(.accounts)
            accounts = dtos.map { $0.toAccount() }
        } catch {
            self.error = error.localizedDescription
        }
    }
}

/// État du formulaire "Ajouter une banque".
@Observable final class AddAccountViewModel {
    var label = ""
    var amountText = ""
    var logo = ""
    var isSubmitting = false
    var errorMessage: String?

    var amount: Double? { Double(amountText.replacingOccurrences(of: ",", with: ".")) }
    var isValid: Bool { !label.trimmingCharacters(in: .whitespaces).isEmpty && amount != nil }

    func submit() async -> Bool {
        guard let amount else { return false }
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }
        let body = AccountCreateRequest(
            label: label.trimmingCharacters(in: .whitespaces),
            amount: amount,
            logo: logo
        )
        do {
            let _: [AccountDTO] = try await APIClient.shared.request(.createAccounts(body: [body]))
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}

/// État du formulaire "Virement entre banques".
@Observable final class TransferViewModel {
    var originId: Int?
    var targetId: Int?
    var amountText = ""
    var isSubmitting = false
    var errorMessage: String?

    var amount: Double? { Double(amountText.replacingOccurrences(of: ",", with: ".")) }

    var isValid: Bool {
        guard let originId, let targetId, let amount else { return false }
        return originId != targetId && amount >= 1
    }

    func submit() async -> Bool {
        guard let originId, let targetId, let amount else { return false }
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }
        do {
            try await APIClient.shared.send(.transfer(body: TransferRequest(
                accountOriginId: originId, accountTargetId: targetId, amount: amount
            )))
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
