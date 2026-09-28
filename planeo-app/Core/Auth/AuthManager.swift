//
//  AuthManager.swift
//  planeo-app
//

import Foundation
import Observation

@Observable final class AuthManager {
    static let shared = AuthManager()
    private init() {}

    // La session est portée par le cookie HttpOnly PLANEO_SID posé par le gateway
    // (stocké automatiquement dans HTTPCookieStorage.shared) : plus de JWT côté client.
    var isAuthenticated = false

    func login(username: String, password: String) async throws {
        let _: LoginResponse = try await APIClient.shared.request(
            .login(username: username, password: password)
        )
        isAuthenticated = true
    }

    func logout() {
        isAuthenticated = false
        Task { await APIClient.shared.logout() }
    }
}
