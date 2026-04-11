//
//  RuneTests.swift
//  RuneTests
//
//  Created by cmc on 2026-03-23.
//

import Testing
@testable import Rune

@MainActor
struct RuneTests {

    @Test func domainUpdateRequestIncludesOnlyChangedFields() async throws {
        let request = DomainUpdateRequest(
            autorenew: true,
            mailforwarding: nil,
            dnssec: nil,
            lock: false,
            nameservers: nil
        )

        #expect(request.hasChanges)
        #expect(request.params["autorenew"] as? Bool == true)
        #expect(request.params["lock"] as? Bool == false)
        #expect(request.params["dnssec"] == nil)
        #expect(request.params["mailforwarding"] == nil)
        #expect(request.params["nameservers"] == nil)
    }

    @Test func changingLockDoesNotAlterDNSSEC() async throws {
        let request = DomainUpdateRequest(
            autorenew: nil,
            mailforwarding: nil,
            dnssec: nil,
            lock: true,
            nameservers: nil
        )

        #expect(request.hasChanges)
        #expect(request.params.count == 1)
        #expect(request.params["lock"] as? Bool == true)
        #expect(request.params["dnssec"] == nil)
    }

    @Test func dnssecOnlyChangeSendsOnlyDNSSEC() async throws {
        let request = DomainUpdateRequest(
            autorenew: nil,
            mailforwarding: nil,
            dnssec: false,
            lock: nil,
            nameservers: nil
        )

        #expect(request.hasChanges)
        #expect(request.params.count == 1)
        #expect(request.params["dnssec"] as? Bool == false)
        #expect(request.params["lock"] == nil)
        #expect(request.params["autorenew"] == nil)
        #expect(request.params["mailforwarding"] == nil)
    }

    @Test func ttlPresetUsesPresetSeconds() async throws {
        var draft = DNSRecordDraft()
        draft.type = .a
        draft.name = "www"
        draft.ttlSeconds = TTLPreset.fifteenMinutes.rawValue

        let params = draft.params(domain: "example.com")

        #expect(params["ttl"] as? Int == 900)
    }

    @Test func ttlOptionsIncludeExistingCustomValue() async throws {
        let record = DNSRecord(
            id: "1",
            domain: "example.com",
            type: "A",
            name: "www",
            content: "1.2.3.4",
            ttl: 42,
            prio: nil,
            weight: nil,
            port: nil,
            target: nil,
            sshAlgorithm: nil,
            sshType: nil
        )

        let draft = DNSRecordDraft(record: record)

        #expect(draft.ttlSeconds == 42)
        #expect(draft.ttlOptions.contains(where: { $0.seconds == 42 && $0.isCustom }))
    }
}
