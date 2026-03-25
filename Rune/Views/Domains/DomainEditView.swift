import SwiftUI

struct DomainEditView: View {
    let domain: Domain
    @ObservedObject var viewModel: DomainViewModel
    let client: NjallaClient

    @Environment(\.dismiss) private var dismiss

    @State private var autorenew: Bool
    @State private var mailforwarding: Bool
    @State private var dnssec: Bool
    @State private var lock: Bool
    @State private var nameserversText: String
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
                Toggle("Autorenew", isOn: $autorenew)
                Toggle("Mail Forwarding", isOn: $mailforwarding)
                Toggle("DNSSEC", isOn: $dnssec)
                Toggle("Registrar Lock", isOn: $lock)
            }

            Section {
                TextEditor(text: $nameserversText)
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
                .disabled(viewModel.isSaving)
            }
        }
        .navigationTitle("Edit Domain")
        .navigationBarTitleDisplayMode(.inline)
        .alert("API Error", isPresented: localErrorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(localErrorMessage ?? "")
        }
    }

    private func save() async {
        let request = DomainUpdateRequest(
            autorenew: autorenew,
            mailforwarding: mailforwarding,
            dnssec: dnssec,
            lock: lock,
            nameservers: nameserversText
                .split(whereSeparator: \.isNewline)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        )

        do {
            try await viewModel.updateDomain(named: domain.name, request: request, client: client)
            dismiss()
        } catch is CancellationError {
            return
        } catch {
            if (error as? URLError)?.code == .cancelled {
                return
            }
            localErrorMessage = error.localizedDescription
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
}
