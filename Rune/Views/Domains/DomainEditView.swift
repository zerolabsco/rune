import SwiftUI

struct DomainEditView: View {
    let domain: Domain
    @ObservedObject var viewModel: DomainViewModel
    let client: NjallaClient

    @Environment(\.dismiss) private var dismiss

    @State private var autorenew: Bool
    @State private var autorenewDirty = false
    @State private var mailforwarding: Bool
    @State private var mailforwardingDirty = false
    @State private var dnssec: Bool
    @State private var dnssecDirty = false
    @State private var lock: Bool
    @State private var lockDirty = false
    @State private var nameserversText: String
    @State private var nameserversDirty = false
    @State private var localErrorMessage: String?

    init(domain: Domain, viewModel: DomainViewModel, client: NjallaClient) {
        self.domain = domain
        self.viewModel = viewModel
        self.client = client
        _autorenew = State(initialValue: domain.autorenew ?? false)
        _mailforwarding = State(initialValue: domain.mailforwarding ?? false)
        _dnssec = State(initialValue: domain.dnssec ?? false)
        _lock = State(initialValue: domain.lock ?? false)
        _nameserversText = State(initialValue: (domain.nameservers ?? []).joined(separator: "\n"))
    }

    var body: some View {
        Form {
            Section("Settings") {
                Toggle("Autorenew", isOn: dirtyBinding(for: $autorenew, dirty: $autorenewDirty, original: originalAutorenew))
                Toggle("Mail Forwarding", isOn: dirtyBinding(for: $mailforwarding, dirty: $mailforwardingDirty, original: originalMailForwarding))
                Toggle("DNSSEC", isOn: dirtyBinding(for: $dnssec, dirty: $dnssecDirty, original: originalDNSSEC))
                Toggle("Registrar Lock", isOn: dirtyBinding(for: $lock, dirty: $lockDirty, original: originalLock))
            }

            Section {
                TextEditor(text: nameserversBinding)
                    .frame(minHeight: 120)
            } header: {
                Text("Nameservers")
            } footer: {
                Text("Enter one nameserver per line. Leave blank to use Njalla defaults.")
            }

            Section {
                Button("Save") {
                    Task {
                        await save()
                    }
                }
                .disabled(viewModel.isSaving || !request.hasChanges)
            }
        }
        .navigationTitle("Edit Domain")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if viewModel.isSaving {
                ProgressView()
                    .controlSize(.large)
            }
        }
        .interactiveDismissDisabled(viewModel.isSaving)
        .alert("Request Failed", isPresented: localErrorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(localErrorMessage ?? "")
        }
    }

    private func save() async {
        guard !viewModel.isSaving else {
            return
        }

        let request = request

        guard request.hasChanges else {
            dismiss()
            return
        }

        do {
            try await viewModel.updateDomain(named: domain.name, request: request, client: client)
            dismiss()
        } catch is CancellationError {
            return
        } catch {
            if (error as? URLError)?.code == .cancelled {
                return
            }
            localErrorMessage = error.userFacingMessage
        }
    }

    private var localErrorBinding: Binding<Bool> {
        Binding(
            get: { localErrorMessage != nil },
            set: { newValue in
                if !newValue {
                    localErrorMessage = nil
                }
            }
        )
    }

    private var originalAutorenew: Bool {
        domain.autorenew ?? false
    }

    private var originalMailForwarding: Bool {
        domain.mailforwarding ?? false
    }

    private var originalDNSSEC: Bool {
        domain.dnssec ?? false
    }

    private var originalLock: Bool {
        domain.lock ?? false
    }

    private var originalNameservers: [String] {
        normalizedNameservers(from: (domain.nameservers ?? []).joined(separator: "\n"))
    }

    private var request: DomainUpdateRequest {
        DomainUpdateRequest(
            autorenew: autorenewDirty ? autorenew : nil,
            mailforwarding: mailforwardingDirty ? mailforwarding : nil,
            dnssec: dnssecDirty ? dnssec : nil,
            lock: lockDirty ? lock : nil,
            nameservers: nameserversDirty ? normalizedNameservers(from: nameserversText) : nil
        )
    }

    private var nameserversBinding: Binding<String> {
        Binding(
            get: { nameserversText },
            set: { newValue in
                nameserversText = newValue
                nameserversDirty = normalizedNameservers(from: newValue) != originalNameservers
            }
        )
    }

    private func dirtyBinding(
        for value: Binding<Bool>,
        dirty: Binding<Bool>,
        original: Bool
    ) -> Binding<Bool> {
        Binding(
            get: { value.wrappedValue },
            set: { newValue in
                value.wrappedValue = newValue
                dirty.wrappedValue = newValue != original
            }
        )
    }

    private func normalizedNameservers(from text: String) -> [String] {
        text
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
