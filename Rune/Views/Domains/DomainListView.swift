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
    }

    @ViewBuilder
    private func content(client: NjallaClient) -> some View {
        List {
            if let errorMessage = viewModel.domainsErrorMessage {
                Section {
                    InlineErrorView(message: errorMessage, retryTitle: "Retry Domains") {
                        Task {
                            await viewModel.loadDomains(client: client)
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
            }

            if (!viewModel.hasLoadedDomains || viewModel.isLoadingDomains) && viewModel.domains.isEmpty {
                Section {
                    HStack {
                        Spacer()
                        ProgressView("Loading Domains")
                        Spacer()
                    }
                }
            } else if viewModel.domains.isEmpty {
                Section {
                    ContentUnavailableView(
                        "No Domains",
                        systemImage: "globe",
                        description: Text("No domains found. Pull to refresh after domains are added to this account.")
                    )
                }
            } else {
                ForEach(viewModel.domains) { domain in
                    NavigationLink {
                        DomainDetailView(domainName: domain.name, viewModel: viewModel, client: client)
                    } label: {
                        DomainRow(domain: domain)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            await viewModel.loadDomains(client: client)
        }
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
