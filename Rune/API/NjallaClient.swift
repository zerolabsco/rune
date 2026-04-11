import Foundation

struct NjallaClient: Sendable, Equatable {
    private let token: String
    private let endpoint = URL(string: "https://njal.la/api/1/")!

    init(token: String) {
        self.token = token
    }

    func call<T: Decodable>(_ method: String, params: [String: Any] = [:]) async throws -> T {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Njalla \(token)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "jsonrpc": "2.0",
            "method": method,
            "params": params,
            "id": "1"
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        _ = (response as? HTTPURLResponse)?.statusCode ?? -1

        let decoder = JSONDecoder()
        let envelope = try decoder.decode(RPCResponse<T>.self, from: data)

        if let error = envelope.error {
            throw NjallaError.api(message: error.message)
        }

        guard let result = envelope.result else {
            throw NjallaError.missingResult
        }

        return result
    }

    func listDomains() async throws -> [Domain] {
        let response: DomainListResponse = try await call("list-domains")
        return response.domains
    }

    func getDomain(named domain: String) async throws -> Domain {
        try await call("get-domain", params: ["domain": domain])
    }

    func editDomain(named domain: String, request: DomainUpdateRequest) async throws -> Domain {
        var params = request.params
        params["domain"] = domain
        return try await call("edit-domain", params: params)
    }

    func listForwards(for domain: String) async throws -> [EmailForward] {
        let response: ForwardListResponse = try await call("list-forwards", params: ["domain": domain])
        return response.forwards
    }

    func addForward(forward: EmailForward) async throws {
        let _: EmptyResult = try await call(
            "add-forward",
            params: [
                "domain": forward.domain,
                "from": forward.from,
                "to": forward.to
            ]
        )
    }

    func removeForward(_ forward: EmailForward) async throws {
        let _: EmptyResult = try await call(
            "remove-forward",
            params: [
                "domain": forward.domain,
                "from": forward.from,
                "to": forward.to
            ]
        )
    }

    func listRecords(for domain: String) async throws -> [DNSRecord] {
        let response: RecordListResponse = try await call("list-records", params: ["domain": domain])
        return response.records.map { record in
            record.domain.isEmpty ? record.withDomain(domain) : record
        }
    }

    func addRecord(for domain: String, draft: DNSRecordDraft) async throws -> DNSRecord {
        try await call("add-record", params: draft.params(domain: domain))
    }

    func editRecord(for domain: String, id: String, draft: DNSRecordDraft) async throws -> DNSRecord {
        try await call("edit-record", params: draft.params(domain: domain, id: id))
    }

    func removeRecord(_ record: DNSRecord) async throws -> [DNSRecord] {
        let params: [String: Any] = [
            "domain": record.domain,
            "id": record.id,
            "name": record.name,
            "type": record.type
        ]
        let response: RecordListResponse = try await call("remove-record", params: params)
        return response.records.map { item in
            item.domain.isEmpty ? item.withDomain(record.domain) : item
        }
    }

    func listTokens() async throws -> [APIToken] {
        let response: TokenListResponse = try await call("list-tokens")
        return response.tokens
    }

    func addToken(request: TokenCreateRequest) async throws {
        let _: EmptyResult = try await call("add-token", params: request.params)
    }

    func removeToken(key: String) async throws {
        let _: EmptyResult = try await call("remove-token", params: ["key": key])
    }

    func getBalance() async throws -> WalletBalance {
        try await call("get-balance")
    }
}

enum NjallaError: LocalizedError {
    case api(message: String)
    case missingResult
    case networkFailure

    var errorDescription: String? {
        switch self {
        case .api(let message):
            return message
        case .missingResult:
            return "The API response did not include a result."
        case .networkFailure:
            return "Network request failed. Check your connection and try again."
        }
    }
}

extension Error {
    var userFacingMessage: String {
        if let njallaError = self as? NjallaError {
            return njallaError.localizedDescription
        }

        if let urlError = self as? URLError {
            switch urlError.code {
            case .cancelled:
                return urlError.localizedDescription
            default:
                return NjallaError.networkFailure.localizedDescription
            }
        }

        return localizedDescription
    }
}

private struct RPCResponse<Result: Decodable>: Decodable {
    let result: Result?
    let error: RPCError?
}

private struct RPCError: Decodable {
    let code: Int
    let message: String
}
