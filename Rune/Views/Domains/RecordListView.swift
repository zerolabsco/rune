import SwiftUI

struct RecordListView: View {
    let domainName: String
    @ObservedObject var viewModel: DomainViewModel
    let client: NjallaClient

    @State private var showingAddRecord = false

    var body: some View {
        Group {
            if viewModel.isLoadingRecords && viewModel.records.isEmpty {
                ProgressView()
            } else if viewModel.records.isEmpty {
                ContentUnavailableView("No Records", systemImage: "list.bullet", description: Text("No DNS records for this domain."))
            } else {
                List(viewModel.records) { record in
                    NavigationLink {
                        RecordEditView(domainName: domainName, record: record, viewModel: viewModel, client: client)
                    } label: {
                        RecordRow(record: record)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("DNS Records")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button {
                showingAddRecord = true
            } label: {
                Label("Add Record", systemImage: "plus")
            }
        }
        .sheet(isPresented: $showingAddRecord) {
            NavigationStack {
                RecordAddView(domainName: domainName, viewModel: viewModel, client: client)
            }
        }
        .task {
            await viewModel.loadRecords(for: domainName, client: client)
        }
        .refreshable {
            await viewModel.loadRecords(for: domainName, client: client)
        }
        .alert("API Error", isPresented: errorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
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

private struct RecordRow: View {
    let record: DNSRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(record.type) \(record.name)")
                .font(.headline)
            if let detail = [record.content, record.target].compactMap({ $0 }).first, !detail.isEmpty {
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
