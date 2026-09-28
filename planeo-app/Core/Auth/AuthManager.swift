//
//  AuthManager.swift
//  planeo-app
//

import Foundation
import Observation

@Observable final class AuthManager {
    static let shared = AuthManager()
    private init() {}

    var token: String?
    var isAuthenticated: Bool { token != nil }

    func login(username: String, password: String) async throws {
        let response: LoginResponse = try await APIClient.shared.request(
            .login(username: username, password: password)
        )
        self.token = response.accessToken
    }

    func logout() {
        token = nil
    }
}
