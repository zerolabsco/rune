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
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        debugLogRawResponse(method: method, statusCode: statusCode, data: data)

        let decoder = JSONDecoder()
        let envelope: RPCResponse<T>
        do {
            envelope = try decoder.decode(RPCResponse<T>.self, from: data)
        } catch {
            debugLogDecodeFailure(method: method, error: error)
            throw error
        }

        if let error = envelope.error {
            throw NjallaError.api(message: error.message)
        }

        guard let result = envelope.result else {
            throw NjallaError.missingResult
        }

        return result
    }

    private func debugLogRawResponse(method: String, statusCode: Int, data: Data) {
        #if DEBUG
        let body = String(data: data, encoding: .utf8) ?? "<non-utf8 body: \(data.count) bytes>"
        debugPrint("[NjallaClient][\(method)] status=\(statusCode) raw=\(body)")
        #endif
    }

    private func debugLogDecodeFailure(method: String, error: Error) {
        #if DEBUG
        debugPrint("[NjallaClient][\(method)] decode-failure=\(error.localizedDescription)")
        #endif
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

    func listGlue(for domain: String) async throws -> [GlueRecord] {
        let response: GlueListResponse = try await call("list-glue", params: ["domain": domain])
        return response.glue.map { record in
            record.domain.isEmpty ? record.withDomain(domain) : record
        }
    }

    func addGlue(for domain: String, name: String, address4: String?, address6: String?) async throws {
        var params: [String: Any] = [
            "domain": domain,
            "name": name
        ]
        if let address4, !address4.isEmpty {
            params["address4"] = address4
        }
        if let address6, !address6.isEmpty {
            params["address6"] = address6
        }
        let _: EmptyResult = try await call("add-glue", params: params)
    }

    func editGlue(for domain: String, name: String, address4: String?, address6: String?) async throws {
        var params: [String: Any] = [
            "domain": domain,
            "name": name
        ]
        if let address4, !address4.isEmpty {
            params["address4"] = address4
        }
        if let address6, !address6.isEmpty {
            params["address6"] = address6
        }
        let _: EmptyResult = try await call("edit-glue", params: params)
    }

    func removeGlue(for domain: String, name: String) async throws {
        let _: EmptyResult = try await call(
            "remove-glue",
            params: [
                "domain": domain,
                "name": name
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

    func logout() async throws {
        let _: EmptyResult = try await call("logout")
    }

    func getBalance() async throws -> WalletBalance {
        try await call("get-balance")
    }

    func listTransactions() async throws -> [WalletTransaction] {
        let response: WalletTransactionListResponse = try await call("list-transactions")
        return response.transactions
    }

    func getPayment(id: String) async throws -> WalletPayment {
        try await call("get-payment", params: ["id": id])
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
