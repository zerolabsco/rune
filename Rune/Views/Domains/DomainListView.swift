import SwiftUI

struct DomainListView: View {
    @ObservedObject var viewModel: DomainViewModel
    let client: NjallaClient?

    var body: some View {
        NavigationStack {
            Group {
                if let client {
                    content(client: client)
                } else {
                    ContentUnavailableView("Sign in required", systemImage: "key.fill", description: Text("Add a valid Njalla API token to load domains."))
                }
            }
            .navigationTitle("Domains")
        }
        .alert("API Error", isPresented: errorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    @ViewBuilder
    private func content(client: NjallaClient) -> some View {
        if viewModel.isLoadingDomains && viewModel.domains.isEmpty {
            ProgressView()
        } else if viewModel.domains.isEmpty {
            ContentUnavailableView("No Domains", systemImage: "globe", description: Text("No domains found on this account."))
        } else {
            List(viewModel.domains) { domain in
                NavigationLink {
                    DomainDetailView(domainName: domain.name, viewModel: viewModel, client: client)
                } label: {
                    DomainRow(domain: domain)
                }
            }
            .listStyle(.insetGrouped)
            .refreshable {
                await viewModel.loadDomains(client: client)
            }
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { newValue in
                if !newValue {
                    viewModel.errorMessage = nil
                }
            }
        )
    }
}

private struct DomainRow: View {
    let domain: Domain

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(domain.name)
                .font(.headline)

            HStack {
                if let status = domain.status {
                    Text(status)
                }

                if let expiry = domain.expiry {
                    Text("Expiry: \(expiry.formattedExpiry())")
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            if let autorenew = domain.autorenew {
                Text(autorenew ? "Autorenew On" : "Autorenew Off")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
