import SwiftUI

struct DomainDetailView: View {
    let domainName: String
    @ObservedObject var viewModel: DomainViewModel
    let client: NjallaClient

    var body: some View {
        Group {
            if viewModel.isLoadingDetail && viewModel.selectedDomain?.name != domainName {
                ProgressView()
            } else if let domain = currentDomain {
                List {
                    Section("Status") {
                        DetailRow(label: "Name", value: domain.name)
                        DetailRow(label: "Status", value: textValue(domain.status))
                        DetailRow(label: "Expiry", value: domain.expiry?.formattedExpiry() ?? "Not available")
                        DetailRow(label: "Autorenew", value: boolText(domain.autorenew))
                    }

                    Section("Settings") {
                        DetailRow(label: "Mail Forwarding", value: boolText(domain.mailforwarding))
                        DetailRow(label: "DNSSEC", value: boolText(domain.dnssec))
                        DetailRow(label: "Registrar Lock", value: boolText(domain.lock))
                        DetailRow(label: "Nameservers", value: nameserverText(domain.nameservers))
                    }

                    Section("Email") {
                        NavigationLink("Forwards") {
                            ForwardListView(domainName: domain.name, viewModel: viewModel, client: client)
                        }
                    }

                    Section("DNS") {
                        NavigationLink("Records") {
                            RecordListView(domainName: domain.name, viewModel: viewModel, client: client)
                        }
                        NavigationLink("Glue Records") {
                            GlueListView(domainName: domain.name, viewModel: viewModel, client: client)
                        }
                    }

                }
                .listStyle(.insetGrouped)
                .toolbar {
                    NavigationLink("Edit") {
                        DomainEditView(domain: domain, viewModel: viewModel, client: client)
                    }
                }
            } else {
                ContentUnavailableView("Domain Unavailable", systemImage: "globe", description: Text("The domain details could not be loaded."))
            }
        }
        .navigationTitle(domainName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadDomainDetail(named: domainName, client: client)
        }
        .alert("API Error", isPresented: errorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.detailErrorMessage ?? "")
        }
        .alert("Request Failed", isPresented: mutationErrorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.mutationErrorMessage ?? "")
        }
    }

    private var currentDomain: Domain? {
        if viewModel.selectedDomain?.name == domainName {
            return viewModel.selectedDomain
        }

        return viewModel.domains.first(where: { $0.name == domainName })
    }

    private func boolText(_ value: Bool?) -> String {
        guard let value else { return "Not available" }
        return value ? "On" : "Off"
    }

    private func nameserverText(_ nameservers: [String]?) -> String {
        guard let nameservers else {
            return "Njalla"
        }

        guard !nameservers.isEmpty else {
            return "Njalla"
        }

        return nameservers.joined(separator: ", ")
    }

    private func textValue(_ value: String?) -> String {
        guard let value, !value.isEmpty else {
            return "Not available"
        }

        return value
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.detailErrorMessage != nil },
            set: { newValue in
                if !newValue {
                    viewModel.detailErrorMessage = nil
                }
            }
        )
    }

    private var mutationErrorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.mutationErrorMessage != nil },
            set: { newValue in
                if !newValue {
                    viewModel.dismissMutationError()
                }
            }
        )
    }
}

private struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }
}
