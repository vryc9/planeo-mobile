//
//  LoginViewModel.swift
//  planeo-app
//

import Foundation
import Observation

@Observable final class LoginViewModel {
    var username = ""
    var password = ""
    var isLoading = false
    var errorMessage: String?

    var isValid: Bool {
        !username.trimmingCharacters(in: .whitespaces).isEmpty &&
        !password.isEmpty
    }

    func login() async -> Bool {
        guard isValid else { return false }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await AuthManager.shared.login(username: username, password: password)
            return true
        } catch APIError.httpError(let code) where code == 401 || code == 403 {
            errorMessage = "Identifiants incorrects"
            return false
        } catch APIError.network(let code) {
            errorMessage = "Connexion impossible, réessaie (réseau \(code))"
            return false
        } catch APIError.httpError(let code) {
            errorMessage = "Serveur indisponible, réessaie (HTTP \(code))"
            return false
        } catch {
            errorMessage = "Erreur inattendue, réessaie (\(error.localizedDescription))"
            return false
        }
    }
}
