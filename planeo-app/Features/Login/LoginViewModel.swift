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
        } catch {
            errorMessage = "Identifiants incorrects"
            return false
        }
    }
}
