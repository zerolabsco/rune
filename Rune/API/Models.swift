import Foundation

struct EmptyResult: Codable {}

struct WalletBalance: Codable, Equatable {
    let balance: Int
}

struct DomainListResponse: Codable {
    let domains: [Domain]
}

struct RecordListResponse: Codable {
    let records: [DNSRecord]
}

struct TokenListResponse: Codable {
    let tokens: [APIToken]
}

struct Domain: Codable, Identifiable, Hashable {
    var id: String { name }

    let name: String
    let status: String?
    let expiry: String?
    let autorenew: Bool?
    let mailforwarding: Bool?
    let dnssec: Bool?
    let lock: Bool?
    let nameservers: [String]?
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

struct DNSRecordDraft: Equatable {
    var type: DNSRecordType = .a
    var name = ""
    var content = ""
    var ttl = ""
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
        ttl = record.ttl.map(String.init) ?? ""
        prio = record.prio.map(String.init) ?? ""
        weight = record.weight.map(String.init) ?? ""
        port = record.port.map(String.init) ?? ""
        target = record.target ?? ""
        sshAlgorithm = record.sshAlgorithm.map(String.init) ?? ""
        sshType = record.sshType.map(String.init) ?? ""
    }

    mutating func resetTypeSpecificFields() {
        content = ""
        ttl = ""
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

        if type.usesTTL, let value = Int(ttl.trimmingCharacters(in: .whitespacesAndNewlines)) {
            params["ttl"] = value
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
    var autorenew: Bool
    var mailforwarding: Bool
    var dnssec: Bool
    var lock: Bool
    var nameservers: [String]

    var params: [String: Any] {
        [
            "autorenew": autorenew,
            "mailforwarding": mailforwarding,
            "dnssec": dnssec,
            "lock": lock,
            "nameservers": nameservers
        ]
    }
}

struct TokenCreateRequest {
    var comment: String
    var from: [String]
    var allowedMethods: [String]

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
