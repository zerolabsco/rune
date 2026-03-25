import Combine
import Foundation

@MainActor
final class DomainViewModel: ObservableObject {
    @Published private(set) var domains: [Domain] = []
    @Published private(set) var selectedDomain: Domain?
    @Published private(set) var records: [DNSRecord] = []
    @Published private(set) var isLoadingDomains = false
    @Published private(set) var isLoadingDetail = false
    @Published private(set) var isLoadingRecords = false
    @Published private(set) var isSaving = false
    @Published var errorMessage: String?

    func reset() {
        domains = []
        selectedDomain = nil
        records = []
        isLoadingDomains = false
        isLoadingDetail = false
        isLoadingRecords = false
        isSaving = false
        errorMessage = nil
    }

    func loadDomains(client: NjallaClient) async {
        isLoadingDomains = true
        defer {
            isLoadingDomains = false
        }

        do {
            domains = try await client.listDomains().sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            if (error as? URLError)?.code == .cancelled {
                return
            }
            errorMessage = error.localizedDescription
        }
    }

    func loadDomainDetail(named name: String, client: NjallaClient) async {
        isLoadingDetail = true
        defer {
            isLoadingDetail = false
        }

        do {
            let domain = try await client.getDomain(named: name)
            selectedDomain = domain
            if let index = domains.firstIndex(where: { $0.name == name }) {
                domains[index] = domain
            }
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            if (error as? URLError)?.code == .cancelled {
                return
            }
            errorMessage = error.localizedDescription
        }
    }

    func updateDomain(named name: String, request: DomainUpdateRequest, client: NjallaClient) async throws {
        isSaving = true
        defer {
            isSaving = false
        }

        let updated = try await client.editDomain(named: name, request: request)
        selectedDomain = updated
        if let index = domains.firstIndex(where: { $0.name == updated.name }) {
            domains[index] = updated
        }
        errorMessage = nil
    }

    func loadRecords(for domain: String, client: NjallaClient) async {
        isLoadingRecords = true
        defer {
            isLoadingRecords = false
        }

        do {
            records = try await client.listRecords(for: domain).sorted {
                ($0.name, $0.type, $0.id) < ($1.name, $1.type, $1.id)
            }
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            if (error as? URLError)?.code == .cancelled {
                return
            }
            errorMessage = error.localizedDescription
        }
    }

    func addRecord(for domain: String, draft: DNSRecordDraft, client: NjallaClient) async throws {
        isSaving = true
        defer {
            isSaving = false
        }

        _ = try await client.addRecord(for: domain, draft: draft)
        try await reloadRecords(for: domain, client: client)
        errorMessage = nil
    }

    func editRecord(for domain: String, recordID: String, draft: DNSRecordDraft, client: NjallaClient) async throws {
        isSaving = true
        defer {
            isSaving = false
        }

        _ = try await client.editRecord(for: domain, id: recordID, draft: draft)
        try await reloadRecords(for: domain, client: client)
        errorMessage = nil
    }

    func removeRecord(_ record: DNSRecord, client: NjallaClient) async throws {
        isSaving = true
        defer {
            isSaving = false
        }

        try await client.removeRecord(record)
        try await reloadRecords(for: record.domain, client: client)
        errorMessage = nil
    }

    private func reloadRecords(for domain: String, client: NjallaClient) async throws {
        records = try await client.listRecords(for: domain).sorted {
            ($0.name, $0.type, $0.id) < ($1.name, $1.type, $1.id)
        }
    }
}
