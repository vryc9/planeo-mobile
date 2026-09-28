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
        // Construction de l'URL : on concatène manuellement pour préserver le chemin multi-segment
        guard let url = URL(string: baseURL.absoluteString + endpoint.path) else {
            throw URLError(.badURL)
        }

        var req = URLRequest(url: url)
        req.httpMethod = endpoint.method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = AuthManager.shared.token {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = endpoint.body {
            req.httpBody = try JSONEncoder().encode(AnyEncodable(body))
        }

        let (data, response) = try await URLSession.shared.data(for: req)

        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw APIError.httpError(code)
        }

        return try decoder.decode(T.self, from: data)
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
    var errorDescription: String? {
        if case .httpError(let code) = self { return "Erreur HTTP \(code)" }
        return nil
    }
}
