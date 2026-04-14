import Foundation

struct EmptyResult: Codable {}

struct WalletBalance: Codable, Equatable {
    let balance: Int
}

struct DomainListResponse: Decodable {
    let domains: [Domain]
}

struct RecordListResponse: Codable {
    let records: [DNSRecord]
}

struct TokenListResponse: Codable {
    let tokens: [APIToken]
}

struct ForwardListResponse: Decodable {
    let forwards: [EmailForward]

    enum CodingKeys: String, CodingKey {
        case forwards
        case mailforwards
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let forwardsValue = try? container.decodeIfPresent([EmailForward].self, forKey: .forwards)
        let mailForwardsValue = try? container.decodeIfPresent([EmailForward].self, forKey: .mailforwards)
        forwards = forwardsValue ?? mailForwardsValue ?? []
    }
}

struct GlueListResponse: Decodable {
    let glue: [GlueRecord]

    enum CodingKeys: String, CodingKey {
        case glue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        glue = (try container.decodeIfPresent([GlueRecord].self, forKey: .glue)) ?? []
    }
}

struct WalletTransactionListResponse: Decodable {
    let transactions: [WalletTransaction]

    enum CodingKeys: String, CodingKey {
        case transactions
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        transactions = (try container.decodeIfPresent([WalletTransaction].self, forKey: .transactions)) ?? []
    }
}

struct Domain: Decodable, Identifiable, Hashable {
    var id: String { name }

    let name: String
    let status: String?
    let expiry: String?
    let renewPrice: Int?
    let autorenew: Bool?
    let mailforwarding: Bool?
    let dnssec: Bool?
    let lock: Bool?
    let nameservers: [String]?

    enum CodingKeys: String, CodingKey {
        case name
        case status
        case expiry
        case renewPrice = "renew_price"
        case renewalPrice = "renewal_price"
        case price
        case autorenew
        case mailforwarding
        case dnssec
        case dnssecEnabled = "dnssec_enabled"
        case lock
        case locked
        case nameservers
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        expiry = try container.decodeIfPresent(String.self, forKey: .expiry)
        renewPrice =
            container.decodeLossyIntIfPresent(forKey: .renewPrice) ??
            container.decodeLossyIntIfPresent(forKey: .renewalPrice) ??
            container.decodeLossyIntIfPresent(forKey: .price)
        autorenew = try container.decodeIfPresent(Bool.self, forKey: .autorenew)
        mailforwarding = try container.decodeIfPresent(Bool.self, forKey: .mailforwarding)
        dnssec = try container.decodeIfPresent(Bool.self, forKey: .dnssec) ??
            container.decodeIfPresent(Bool.self, forKey: .dnssecEnabled)
        lock = try container.decodeIfPresent(Bool.self, forKey: .lock) ??
            container.decodeIfPresent(Bool.self, forKey: .locked)
        nameservers = try container.decodeIfPresent([String].self, forKey: .nameservers)
    }
}

private extension KeyedDecodingContainer where K == Domain.CodingKeys {
    func decodeLossyIntIfPresent(forKey key: K) -> Int? {
        if let intValue = try? decodeIfPresent(Int.self, forKey: key) {
            return intValue
        }

        if let stringValue = try? decodeIfPresent(String.self, forKey: key) {
            return Int(stringValue)
        }

        return nil
    }
}

struct DNSRecord: Codable, Identifiable, Hashable {
    let id: String
    let domain: String
    let type: String
    let name: String
    let content: String?
    let ttl: Int?
    let prio: Int?
    let weight: Int?
    let port: Int?
    let target: String?
    let sshAlgorithm: Int?
    let sshType: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case domain
        case type
        case name
        case content
        case ttl
        case prio
        case weight
        case port
        case target
        case sshAlgorithm = "ssh_algorithm"
        case sshType = "ssh_type"
    }

    init(
        id: String,
        domain: String,
        type: String,
        name: String,
        content: String?,
        ttl: Int?,
        prio: Int?,
        weight: Int?,
        port: Int?,
        target: String?,
        sshAlgorithm: Int?,
        sshType: Int?
    ) {
        self.id = id
        self.domain = domain
        self.type = type
        self.name = name
        self.content = content
        self.ttl = ttl
        self.prio = prio
        self.weight = weight
        self.port = port
        self.target = target
        self.sshAlgorithm = sshAlgorithm
        self.sshType = sshType
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeLossyString(forKey: .id)
        domain = try container.decodeIfPresent(String.self, forKey: .domain) ?? ""
        type = try container.decode(String.self, forKey: .type)
        name = try container.decode(String.self, forKey: .name)
        content = try container.decodeIfPresent(String.self, forKey: .content)
        ttl = try container.decodeLossyIntIfPresent(forKey: .ttl)
        prio = try container.decodeLossyIntIfPresent(forKey: .prio)
        weight = try container.decodeLossyIntIfPresent(forKey: .weight)
        port = try container.decodeLossyIntIfPresent(forKey: .port)
        target = try container.decodeIfPresent(String.self, forKey: .target)
        sshAlgorithm = try container.decodeLossyIntIfPresent(forKey: .sshAlgorithm)
        sshType = try container.decodeLossyIntIfPresent(forKey: .sshType)
    }

    func withDomain(_ domain: String) -> DNSRecord {
        DNSRecord(
            id: id,
            domain: domain,
            type: type,
            name: name,
            content: content,
            ttl: ttl,
            prio: prio,
            weight: weight,
            port: port,
            target: target,
            sshAlgorithm: sshAlgorithm,
            sshType: sshType
        )
    }
}

struct APIToken: Codable, Identifiable, Hashable {
    var id: String { key }

    let key: String
    let comment: String?
    let from: [String]?
    let allowedDomains: [String]?
    let allowedServers: [String]?
    let allowedMethods: [String]?
    let allowedPrefixes: [String]?
    let allowedTypes: [String]?

    enum CodingKeys: String, CodingKey {
        case key
        case comment
        case from
        case allowedDomains = "allowed_domains"
        case allowedServers = "allowed_servers"
        case allowedMethods = "allowed_methods"
        case allowedPrefixes = "allowed_prefixes"
        case allowedTypes = "allowed_types"
    }
}

struct EmailForward: Codable, Hashable, Identifiable {
    let domain: String
    let from: String
    let to: String

    enum CodingKeys: String, CodingKey {
        case domain
        case from
        case to
    }

    init(domain: String, from: String, to: String) {
        self.domain = domain
        self.from = from
        self.to = to
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawFrom = try container.decode(String.self, forKey: .from).trimmingCharacters(in: .whitespacesAndNewlines)
        let to = try container.decode(String.self, forKey: .to).trimmingCharacters(in: .whitespacesAndNewlines)

        let decodedDomain = try container.decodeIfPresent(String.self, forKey: .domain)?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let atIndex = rawFrom.lastIndex(of: "@") {
            let localPart = String(rawFrom[..<atIndex])
            let fromDomain = String(rawFrom[rawFrom.index(after: atIndex)...])
            self.from = localPart.isEmpty ? rawFrom : localPart
            if let decodedDomain, !decodedDomain.isEmpty {
                self.domain = decodedDomain
            } else {
                self.domain = fromDomain
            }
        } else {
            self.from = rawFrom
            self.domain = decodedDomain ?? ""
        }

        self.to = to
    }

    var id: String {
        "\(domain)|\(from)|\(to)"
    }
}

struct GlueRecord: Codable, Hashable, Identifiable {
    let domain: String
    let name: String
    let address4: String?
    let address6: String?

    enum CodingKeys: String, CodingKey {
        case domain
        case name
        case address4
        case address6
    }

    init(domain: String, name: String, address4: String?, address6: String?) {
        self.domain = domain
        self.name = name
        self.address4 = address4
        self.address6 = address6
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        domain = (try container.decodeIfPresent(String.self, forKey: .domain)) ?? ""
        name = try container.decode(String.self, forKey: .name)
        address4 = try container.decodeIfPresent(String.self, forKey: .address4)
        address6 = try container.decodeIfPresent(String.self, forKey: .address6)
    }

    var id: String {
        "\(domain)|\(name)"
    }

    func withDomain(_ domain: String) -> GlueRecord {
        GlueRecord(domain: domain, name: name, address4: address4, address6: address6)
    }
}

struct WalletTransaction: Codable, Hashable, Identifiable {
    let id: String
    let type: String?
    let status: String?
    let amount: Int?
    let date: String?
    let details: String?

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case status
        case amount
        case date
        case details = "description"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? container.decodeLossyString(forKey: .id)) ?? UUID().uuidString
        type = try container.decodeIfPresent(String.self, forKey: .type)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        amount = try container.decodeLossyIntIfPresent(forKey: .amount)
        date = try container.decodeIfPresent(String.self, forKey: .date)
        details = try container.decodeIfPresent(String.self, forKey: .details)
    }
}

struct WalletPayment: Codable, Hashable {
    let id: String?
    let amount: Int?
    let status: String?
    let address: String?
    let url: String?
}

enum DNSRecordType: String, CaseIterable, Identifiable, Codable {
    case a = "A"
    case aaaa = "AAAA"
    case aname = "ANAME"
    case caa = "CAA"
    case cname = "CNAME"
    case ds = "DS"
    case dynamic = "Dynamic"
    case https = "HTTPS"
    case mx = "MX"
    case naptr = "NAPTR"
    case ns = "NS"
    case ptr = "PTR"
    case srv = "SRV"
    case sshfp = "SSHFP"
    case svcb = "SVCB"
    case tlsa = "TLSA"
    case txt = "TXT"

    var id: String { rawValue }

    var usesContent: Bool {
        switch self {
        case .dynamic, .https, .svcb:
            return false
        default:
            return true
        }
    }

    var usesTTL: Bool {
        usesContent
    }

    var usesPriority: Bool {
        switch self {
        case .https, .mx, .srv, .svcb:
            return true
        default:
            return false
        }
    }

    var usesWeight: Bool {
        self == .srv
    }

    var usesPort: Bool {
        self == .srv
    }

    var usesTarget: Bool {
        self == .https || self == .svcb
    }

    var usesSSHFields: Bool {
        self == .sshfp
    }
}

enum TTLPreset: Int, CaseIterable, Identifiable {
    case zero = 0
    case oneMinute = 60
    case fiveMinutes = 300
    case fifteenMinutes = 900
    case oneHour = 3600
    case threeHours = 10800
    case sixHours = 21600
    case oneDay = 86400

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .zero:
            return "0s"
        case .oneMinute:
            return "1m"
        case .fiveMinutes:
            return "5m"
        case .fifteenMinutes:
            return "15m"
        case .oneHour:
            return "1h"
        case .threeHours:
            return "3h"
        case .sixHours:
            return "6h"
        case .oneDay:
            return "1d"
        }
    }

    static func option(for seconds: Int) -> TTLOption {
        if let preset = TTLPreset(rawValue: seconds) {
            return TTLOption(seconds: preset.rawValue, label: preset.label)
        }

        return TTLOption(seconds: seconds, label: "\(seconds)s", isCustom: true)
    }
}

struct TTLOption: Hashable, Identifiable {
    let seconds: Int
    let label: String
    let isCustom: Bool

    init(seconds: Int, label: String, isCustom: Bool = false) {
        self.seconds = seconds
        self.label = label
        self.isCustom = isCustom
    }

    var id: Int { seconds }
}

struct DNSRecordDraft: Equatable {
    var type: DNSRecordType = .a
    var name = ""
    var content = ""
    var ttlSeconds = TTLPreset.oneHour.rawValue
    var prio = ""
    var weight = ""
    var port = ""
    var target = ""
    var sshAlgorithm = ""
    var sshType = ""

    init() {}

    init(record: DNSRecord) {
        type = DNSRecordType(rawValue: record.type) ?? .a
        name = record.name
        content = record.content ?? ""
        ttlSeconds = record.ttl ?? TTLPreset.oneHour.rawValue
        prio = record.prio.map(String.init) ?? ""
        weight = record.weight.map(String.init) ?? ""
        port = record.port.map(String.init) ?? ""
        target = record.target ?? ""
        sshAlgorithm = record.sshAlgorithm.map(String.init) ?? ""
        sshType = record.sshType.map(String.init) ?? ""
    }

    mutating func resetTypeSpecificFields() {
        content = ""
        ttlSeconds = TTLPreset.oneHour.rawValue
        prio = ""
        weight = ""
        port = ""
        target = ""
        sshAlgorithm = ""
        sshType = ""
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canSubmit: Bool {
        !trimmedName.isEmpty
    }

    var ttlOptions: [TTLOption] {
        let presetOptions = TTLPreset.allCases.map { TTLOption(seconds: $0.rawValue, label: $0.label) }

        guard type.usesTTL, TTLPreset(rawValue: ttlSeconds) == nil else {
            return presetOptions
        }

        return presetOptions + [TTLPreset.option(for: ttlSeconds)]
    }

    func params(domain: String, id: String? = nil) -> [String: Any] {
        var params: [String: Any] = [
            "domain": domain,
            "type": type.rawValue,
            "name": trimmedName
        ]

        if let id {
            params["id"] = id
        }

        if type.usesContent {
            params["content"] = content.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if type.usesTTL {
            params["ttl"] = ttlSeconds
        }

        if type.usesPriority, let value = Int(prio.trimmingCharacters(in: .whitespacesAndNewlines)) {
            params["prio"] = value
        }

        if type.usesWeight, let value = Int(weight.trimmingCharacters(in: .whitespacesAndNewlines)) {
            params["weight"] = value
        }

        if type.usesPort, let value = Int(port.trimmingCharacters(in: .whitespacesAndNewlines)) {
            params["port"] = value
        }

        if type.usesTarget {
            params["target"] = target.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if type.usesSSHFields {
            if let value = Int(sshAlgorithm.trimmingCharacters(in: .whitespacesAndNewlines)) {
                params["ssh_algorithm"] = value
            }
            if let value = Int(sshType.trimmingCharacters(in: .whitespacesAndNewlines)) {
                params["ssh_type"] = value
            }
        }

        return params
    }
}

struct DomainUpdateRequest {
    var autorenew: Bool?
    var mailforwarding: Bool?
    var dnssec: Bool?
    var lock: Bool?
    var nameservers: [String]?

    var hasChanges: Bool {
        autorenew != nil ||
        mailforwarding != nil ||
        dnssec != nil ||
        lock != nil ||
        nameservers != nil
    }

    var params: [String: Any] {
        var params: [String: Any] = [:]

        if let autorenew {
            params["autorenew"] = autorenew
        }

        if let mailforwarding {
            params["mailforwarding"] = mailforwarding
        }

        if let dnssec {
            params["dnssec"] = dnssec
        }

        if let lock {
            params["lock"] = lock
        }

        if let nameservers {
            params["nameservers"] = nameservers
        }

        return params
    }

    func isSatisfied(by domain: Domain) -> Bool {
        if let autorenew, domain.autorenew != autorenew {
            return false
        }

        if let mailforwarding, domain.mailforwarding != mailforwarding {
            return false
        }

        if let dnssec, domain.dnssec != dnssec {
            return false
        }

        if let lock, domain.lock != lock {
            return false
        }

        if let nameservers {
            let normalizedResponse = domain.nameservers ?? []
            if normalizedResponse != nameservers {
                return false
            }
        }

        return true
    }
}

struct TokenCreateRequest {
    var comment: String
    var from: [String]
    var allowedMethods: [String]
    var allowedDomains: [String]

    var params: [String: Any] {
        var params: [String: Any] = [:]

        let trimmedComment = comment.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedComment.isEmpty {
            params["comment"] = trimmedComment
        }

        if !from.isEmpty {
            params["from"] = from
        }

        if !allowedMethods.isEmpty {
            params["allowed_methods"] = allowedMethods
        }

        if !allowedDomains.isEmpty {
            params["allowed_domains"] = allowedDomains
        }

        return params
    }
}

extension String {
    func formattedExpiry() -> String {
        let parser = ISO8601DateFormatter()
        guard let date = parser.date(from: self) else { return self }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

private extension KeyedDecodingContainer where K == DNSRecord.CodingKeys {
    func decodeLossyString(forKey key: K) throws -> String {
        if let stringValue = try decodeIfPresent(String.self, forKey: key) {
            return stringValue
        }

        if let intValue = try decodeIfPresent(Int.self, forKey: key) {
            return String(intValue)
        }

        throw DecodingError.keyNotFound(
            key,
            DecodingError.Context(codingPath: codingPath, debugDescription: "Missing required value for \(key.stringValue).")
        )
    }

    func decodeLossyIntIfPresent(forKey key: K) throws -> Int? {
        if let intValue = try decodeIfPresent(Int.self, forKey: key) {
            return intValue
        }

        if let stringValue = try decodeIfPresent(String.self, forKey: key) {
            return Int(stringValue)
        }

        return nil
    }
}

private extension KeyedDecodingContainer where K == WalletTransaction.CodingKeys {
    func decodeLossyString(forKey key: K) throws -> String {
        if let stringValue = try decodeIfPresent(String.self, forKey: key) {
            return stringValue
        }

        if let intValue = try decodeIfPresent(Int.self, forKey: key) {
            return String(intValue)
        }

        throw DecodingError.keyNotFound(
            key,
            DecodingError.Context(codingPath: codingPath, debugDescription: "Missing required value for \(key.stringValue).")
        )
    }

    func decodeLossyIntIfPresent(forKey key: K) throws -> Int? {
        if let intValue = try decodeIfPresent(Int.self, forKey: key) {
            return intValue
        }

        if let stringValue = try decodeIfPresent(String.self, forKey: key) {
            return Int(stringValue)
        }

        return nil
    }
}
