import SwiftUI

struct RecordListView: View {
    let domainName: String
    @ObservedObject var viewModel: DomainViewModel
    let client: NjallaClient

    @State private var showingAddRecord = false

    var body: some View {
        List {
            if let errorMessage = viewModel.recordsErrorMessage {
                Section {
                    InlineErrorView(message: errorMessage, retryTitle: "Retry Records") {
                        Task {
                            await viewModel.loadRecords(for: domainName, client: client)
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
            }

            if viewModel.isLoadingRecords && viewModel.records.isEmpty {
                Section {
                    HStack {
                        Spacer()
                        ProgressView("Loading Records")
                        Spacer()
                    }
                }
            } else if viewModel.records.isEmpty {
                Section {
                    ContentUnavailableView(
                        "No Records",
                        systemImage: "list.bullet",
                        description: Text("No DNS records for this domain yet. Add a record to get started.")
                    )
                }
            } else {
                ForEach(viewModel.records) { record in
                    NavigationLink {
                        RecordEditView(domainName: domainName, record: record, viewModel: viewModel, client: client)
                    } label: {
                        RecordRow(record: record)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
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
        .onAppear {
            viewModel.startAutoRefreshRecords(for: domainName, client: client)
        }
        .onDisappear {
            viewModel.stopAutoRefreshRecords()
        }
        .refreshable {
            await viewModel.loadRecords(for: domainName, client: client)
        }
        .overlay(alignment: .top) {
            if viewModel.isLoadingRecords && !viewModel.records.isEmpty {
                ProgressView()
                    .padding(.top, 8)
            }
        }
        .alert("Request Failed", isPresented: mutationErrorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.mutationErrorMessage ?? "")
        }
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
