import Foundation

@MainActor
public final class MoltbookAPI: ObservableObject {
    private let baseURL = "https://www.moltbook.com/api/v1"
    private var apiKey: String?
    private let session: URLSession
    private let decoder: JSONDecoder

    @Published public var isAuthenticated = false

    public init(apiKey: String? = nil, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        self.isAuthenticated = apiKey != nil
    }

    public func setAPIKey(_ key: String) {
        self.apiKey = key
        self.isAuthenticated = true
    }

    public func clearAPIKey() {
        self.apiKey = nil
        self.isAuthenticated = false
    }

    public func buildRequest(endpoint: String, method: String, body: Data? = nil) -> URLRequest {
        var request = URLRequest(url: URL(string: baseURL + endpoint)!)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let apiKey = apiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.httpBody = body
        }

        return request
    }

    public func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError(error: "invalid_response")
        }

        switch httpResponse.statusCode {
        case 200...299:
            return try decoder.decode(T.self, from: data)
        case 401:
            throw APIError(error: "unauthorized", message: "Invalid or expired API key")
        case 404:
            throw APIError(error: "not_found", message: "Resource not found")
        case 429:
            let errorResponse = try? decoder.decode(APIError.self, from: data)
            throw errorResponse ?? APIError(error: "rate_limited")
        default:
            let errorResponse = try? decoder.decode(APIError.self, from: data)
            throw errorResponse ?? APIError(error: "unknown", message: "HTTP \(httpResponse.statusCode)")
        }
    }

    public func register() async throws -> RegistrationResponse {
        let request = buildRequest(endpoint: "/agents/register", method: "POST")
        return try await perform(request)
    }

    public func checkStatus() async throws -> StatusResponse {
        let request = buildRequest(endpoint: "/agents/status", method: "GET")
        return try await perform(request)
    }
}
