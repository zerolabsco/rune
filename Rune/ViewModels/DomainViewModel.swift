import Combine
import Foundation

@MainActor
final class DomainViewModel: ObservableObject {
    @Published private(set) var domains: [Domain] = []
    @Published private(set) var selectedDomain: Domain?
    @Published private(set) var records: [DNSRecord] = []
    @Published private(set) var forwards: [EmailForward] = []
    @Published private(set) var isLoadingDomains = false
    @Published private(set) var isLoadingDetail = false
    @Published private(set) var isLoadingRecords = false
    @Published private(set) var isLoadingForwards = false
    @Published private(set) var isSaving = false
    @Published private(set) var hasLoadedDomains = false
    @Published var domainsErrorMessage: String?
    @Published var detailErrorMessage: String?
    @Published var recordsErrorMessage: String?
    @Published var forwardsErrorMessage: String?
    @Published var mutationErrorMessage: String?

    private var recordsRefreshTask: Task<Void, Never>?

    func reset() {
        domains = []
        selectedDomain = nil
        records = []
        forwards = []
        isLoadingDomains = false
        isLoadingDetail = false
        isLoadingRecords = false
        isLoadingForwards = false
        isSaving = false
        hasLoadedDomains = false
        domainsErrorMessage = nil
        detailErrorMessage = nil
        recordsErrorMessage = nil
        forwardsErrorMessage = nil
        mutationErrorMessage = nil
        stopAutoRefreshRecords()
    }

    func loadDomains(client: NjallaClient) async {
        guard !isLoadingDomains else { return }

        isLoadingDomains = true
        defer {
            isLoadingDomains = false
            hasLoadedDomains = true
        }

        do {
            domains = try await client.listDomains().sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
            domainsErrorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            if (error as? URLError)?.code == .cancelled {
                return
            }
            domainsErrorMessage = error.userFacingMessage
        }
    }

    func loadDomainDetail(named name: String, client: NjallaClient) async {
        guard !isLoadingDetail else { return }

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
            detailErrorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            if (error as? URLError)?.code == .cancelled {
                return
            }
            detailErrorMessage = error.userFacingMessage
        }
    }

    func updateDomain(named name: String, request: DomainUpdateRequest, client: NjallaClient) async throws {
        guard !isSaving else { return }

        isSaving = true
        mutationErrorMessage = nil

        do {
            let updated = try await client.editDomain(named: name, request: request)
            guard request.isSatisfied(by: updated) else {
                throw NjallaError.api(message: "The API response did not reflect the requested domain changes.")
            }
            selectedDomain = updated
            if let index = domains.firstIndex(where: { $0.name == updated.name }) {
                domains[index] = updated
            }
            detailErrorMessage = nil
            isSaving = false
            Task {
                await loadDomainDetail(named: updated.name, client: client)
            }
        } catch {
            isSaving = false
            mutationErrorMessage = error.userFacingMessage
            throw error
        }
    }

    func loadRecords(for domain: String, client: NjallaClient) async {
        await fetchRecords(for: domain, client: client)
    }

    func startAutoRefreshRecords(for domain: String, client: NjallaClient) {
        guard recordsRefreshTask == nil else { return }

        recordsRefreshTask = Task { [weak self] in
            guard let self else { return }

            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))

                guard !Task.isCancelled else { return }
                await self.fetchRecords(for: domain, client: client)
            }
        }
    }

    func stopAutoRefreshRecords() {
        recordsRefreshTask?.cancel()
        recordsRefreshTask = nil
    }

    func dismissMutationError() {
        mutationErrorMessage = nil
    }

    func loadForwards(for domain: String, client: NjallaClient) async {
        guard !isLoadingForwards else { return }

        isLoadingForwards = true
        defer {
            isLoadingForwards = false
        }

        do {
            forwards = try await client.listForwards(for: domain).sorted {
                ($0.from, $0.to) < ($1.from, $1.to)
            }
            forwardsErrorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            if (error as? URLError)?.code == .cancelled {
                return
            }
            forwardsErrorMessage = error.userFacingMessage
        }
    }

    private func fetchRecords(for domain: String, client: NjallaClient) async {
        guard !isLoadingRecords else { return }

        isLoadingRecords = true
        defer {
            isLoadingRecords = false
        }

        do {
            records = try await client.listRecords(for: domain).sorted {
                ($0.name, $0.type, $0.id) < ($1.name, $1.type, $1.id)
            }
            recordsErrorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            if (error as? URLError)?.code == .cancelled {
                return
            }
            recordsErrorMessage = error.userFacingMessage
        }
    }

    func addRecord(for domain: String, draft: DNSRecordDraft, client: NjallaClient) async throws {
        guard !isSaving else { return }

        isSaving = true
        mutationErrorMessage = nil

        do {
            let record = try await client.addRecord(for: domain, draft: draft).withDomain(domain)
            guard record.id.isEmpty == false,
                  record.type == draft.type.rawValue,
                  record.name == draft.trimmedName else {
                throw NjallaError.api(message: "The API response did not reflect the requested record change.")
            }
            records = sortedRecords(records + [record])
            recordsErrorMessage = nil
            isSaving = false
            Task {
                await loadRecords(for: domain, client: client)
            }
        } catch {
            isSaving = false
            mutationErrorMessage = error.userFacingMessage
            throw error
        }
    }

    func editRecord(for domain: String, recordID: String, draft: DNSRecordDraft, client: NjallaClient) async throws {
        guard !isSaving else { return }

        isSaving = true
        mutationErrorMessage = nil

        do {
            let updatedRecord = try await client.editRecord(for: domain, id: recordID, draft: draft).withDomain(domain)
            guard updatedRecord.id == recordID,
                  updatedRecord.type == draft.type.rawValue,
                  updatedRecord.name == draft.trimmedName else {
                throw NjallaError.api(message: "The API response did not reflect the requested record change.")
            }
            if let index = records.firstIndex(where: { $0.id == recordID }) {
                records[index] = updatedRecord
            } else {
                records.append(updatedRecord)
            }
            records = sortedRecords(records)
            recordsErrorMessage = nil
            isSaving = false
            Task {
                await loadRecords(for: domain, client: client)
            }
        } catch {
            isSaving = false
            mutationErrorMessage = error.userFacingMessage
            throw error
        }
    }

    func removeRecord(_ record: DNSRecord, client: NjallaClient) async throws {
        guard !isSaving else { return }

        isSaving = true
        mutationErrorMessage = nil

        do {
            let updatedRecords = try await client.removeRecord(record)
            guard updatedRecords.contains(where: { $0.id == record.id }) == false else {
                throw NjallaError.api(message: "The API response indicates the record was not removed.")
            }
            records = sortedRecords(updatedRecords)
            recordsErrorMessage = nil
            isSaving = false
            Task {
                await loadRecords(for: record.domain, client: client)
            }
        } catch {
            isSaving = false
            mutationErrorMessage = error.userFacingMessage
            throw error
        }
    }

    func addForward(_ forward: EmailForward, client: NjallaClient) async throws {
        guard !isSaving else { return }

        isSaving = true
        mutationErrorMessage = nil

        do {
            try await client.addForward(forward: forward)
            if forwards.contains(forward) == false {
                forwards = sortedForwards(forwards + [forward])
            }
            forwardsErrorMessage = nil
            isSaving = false
            Task {
                await loadForwards(for: forward.domain, client: client)
            }
        } catch {
            isSaving = false
            mutationErrorMessage = error.userFacingMessage
            throw error
        }
    }

    func removeForward(_ forward: EmailForward, client: NjallaClient) async throws {
        guard !isSaving else { return }

        isSaving = true
        mutationErrorMessage = nil

        do {
            try await client.removeForward(forward)
            forwards.removeAll { $0 == forward }
            forwardsErrorMessage = nil
            isSaving = false
            Task {
                await loadForwards(for: forward.domain, client: client)
            }
        } catch {
            isSaving = false
            mutationErrorMessage = error.userFacingMessage
            throw error
        }
    }

    private func sortedRecords(_ records: [DNSRecord]) -> [DNSRecord] {
        records.sorted {
            ($0.name, $0.type, $0.id) < ($1.name, $1.type, $1.id)
        }
    }

    private func sortedForwards(_ forwards: [EmailForward]) -> [EmailForward] {
        forwards.sorted {
            ($0.from, $0.to) < ($1.from, $1.to)
        }
    }
}
