//
//  APIClient.swift
//  planeo-app
//

import Foundation

final class APIClient {
    static let shared = APIClient()
    private init() {}

    private let baseURL = URL(string: "https://planeo.duckdns.org")!

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        let data = try await perform(endpoint)
        return try decoder.decode(T.self, from: data)
    }

    /// Pour les endpoints dont la réponse n'a pas de corps exploitable (204, 200 vide…).
    func send(_ endpoint: APIEndpoint) async throws {
        _ = try await perform(endpoint)
    }

    private func perform(_ endpoint: APIEndpoint) async throws -> Data {
        // Construction de l'URL : on concatène manuellement pour préserver le chemin multi-segment
        guard let url = URL(string: baseURL.absoluteString + endpoint.path) else {
            throw URLError(.badURL)
        }

        var req = URLRequest(url: url)
        req.httpMethod = endpoint.method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body = endpoint.body {
            req.httpBody = try JSONEncoder().encode(AnyEncodable(body))
        }

        let (data, response) = try await URLSession.shared.data(for: req)

        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            if code == 401 && !endpoint.isCredentialCheck {
                // Session expirée côté gateway : retour à l'écran de connexion
                AuthManager.shared.isAuthenticated = false
            }
            if let message = APIError.message(from: data) { throw APIError.server(message) }
            throw APIError.httpError(code)
        }
        return data
    }

    /// Purge le cookie de session local (la session serveur est déjà fermée).
    func clearSessionCookies() {
        HTTPCookieStorage.shared.cookies(for: baseURL)?.forEach(HTTPCookieStorage.shared.deleteCookie)
    }

    /// Ferme la session côté gateway (best effort) et purge le cookie local.
    func logout() async {
        if let url = URL(string: baseURL.absoluteString + "/auth/logout") {
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            _ = try? await URLSession.shared.data(for: req)
        }
        HTTPCookieStorage.shared.cookies(for: baseURL)?.forEach(HTTPCookieStorage.shared.deleteCookie)
    }
}

// Nécessaire pour encoder un Encodable existentiel
private struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void
    init(_ value: Encodable) { _encode = value.encode }
    func encode(to encoder: Encoder) throws { try _encode(encoder) }
}

enum APIError: LocalizedError {
    case httpError(Int)
    case server(String)

    var errorDescription: String? {
        switch self {
        case .httpError(let code): return "Erreur HTTP \(code)"
        case .server(let message): return message
        }
    }

    /// Extrait le message d'un ProblemDetail Spring (`detail` + éventuel `errors` de validation).
    static func message(from data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        if let errors = json["errors"] as? [String: String], !errors.isEmpty {
            return errors.values.sorted().joined(separator: "\n")
        }
        return json["detail"] as? String
    }
}
