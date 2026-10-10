//
//  APIClient.swift
//  planeo-app
//

import Foundation

final class APIClient {
    static let shared = APIClient()
    private init() {}

    private let baseURL = URL(string: "https://planeo.duckdns.org")!

    // Au tout premier lancement (installation neuve), le réseau n'est parfois pas encore prêt :
    // avec URLSession.shared la requête échoue aussitôt (-1009/-1003…) sans jamais partir.
    // `waitsForConnectivity` la met en attente au lieu d'échouer. Les cookies restent ceux de
    // HTTPCookieStorage.shared (comportement par défaut d'une configuration .default).
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        return URLSession(configuration: config)
    }()

    /// Erreurs réseau où la requête n'a (très probablement) pas abouti : un nouvel essai est sûr.
    private static let transientErrors: Set<URLError.Code> = [
        .notConnectedToInternet, .networkConnectionLost, .cannotFindHost,
        .cannotConnectToHost, .dnsLookupFailed, .timedOut, .secureConnectionFailed,
        .dataNotAllowed, .internationalRoamingOff
    ]

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

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await self.data(for: req)
        } catch let error as URLError {
            throw APIError.network(error.errorCode)
        }

        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            if code == 401 && !endpoint.isLogin {
                // Session expirée côté gateway : retour à l'écran de connexion
                AuthManager.shared.isAuthenticated = false
            }
            if let message = APIError.message(from: data) { throw APIError.server(message) }
            throw APIError.httpError(code)
        }
        return data
    }

    /// Jusqu'à 3 essais sur erreur réseau transitoire (la requête n'a pas atteint le serveur).
    private func data(for req: URLRequest) async throws -> (Data, URLResponse) {
        let maxAttempts = 3
        var attempt = 1
        while true {
            do {
                return try await session.data(for: req)
            } catch let error as URLError where attempt < maxAttempts
                        && Self.transientErrors.contains(error.code) {
                try await Task.sleep(for: .seconds(Double(attempt)))
                attempt += 1
            }
        }
    }

    /// Ferme la session côté gateway (best effort) et purge le cookie local.
    func logout() async {
        if let url = URL(string: baseURL.absoluteString + "/auth/logout") {
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            _ = try? await session.data(for: req)
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
    case network(Int)

    var errorDescription: String? {
        switch self {
        case .httpError(let code): return "Erreur HTTP \(code)"
        case .server(let message): return message
        case .network(let code): return "Connexion impossible (réseau \(code))"
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
