import SwiftUI

struct GlueListView: View {
    let domainName: String
    @ObservedObject var viewModel: DomainViewModel
    let client: NjallaClient

    @State private var showingAddGlue = false
    @State private var recordPendingDeletion: GlueRecord?

    var body: some View {
        List {
            if let errorMessage = viewModel.glueErrorMessage {
                Section {
                    InlineErrorView(message: errorMessage, retryTitle: "Retry Glue Records") {
                        Task {
                            await viewModel.loadGlue(for: domainName, client: client)
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
            }

            if viewModel.isLoadingGlue && viewModel.glueRecords.isEmpty {
                Section {
                    HStack {
                        Spacer()
                        ProgressView("Loading Glue")
                        Spacer()
                    }
                }
            } else if viewModel.glueRecords.isEmpty {
                Section {
                    ContentUnavailableView(
                        "No Glue Records",
                        systemImage: "list.bullet.rectangle",
                        description: Text("No glue records are configured for this domain.")
                    )
                }
            } else {
                ForEach(viewModel.glueRecords) { record in
                    NavigationLink {
                        GlueEditView(domainName: domainName, existingRecord: record, viewModel: viewModel, client: client)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(record.name)
                                .font(.headline)
                            Text("IPv4: \(record.address4 ?? "n/a")")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("IPv6: \(record.address6 ?? "n/a")")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .swipeActions {
                        Button("Delete", role: .destructive) {
                            recordPendingDeletion = record
                        }
                    }
                    .disabled(viewModel.isSaving)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Glue Records")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button {
                showingAddGlue = true
            } label: {
                Label("Add Glue", systemImage: "plus")
            }
            .disabled(viewModel.isSaving)
        }
        .sheet(isPresented: $showingAddGlue) {
            NavigationStack {
                GlueEditView(domainName: domainName, existingRecord: nil, viewModel: viewModel, client: client)
            }
        }
        .task {
            await viewModel.loadGlue(for: domainName, client: client)
        }
        .refreshable {
            await viewModel.loadGlue(for: domainName, client: client)
        }
        .alert(deleteAlertTitle, isPresented: deleteBinding) {
            Button("Delete Glue", role: .destructive) {
                guard let recordPendingDeletion else { return }
                Task {
                    do {
                        try await viewModel.removeGlue(recordPendingDeletion, client: client)
                        self.recordPendingDeletion = nil
                    } catch {
                        return
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                recordPendingDeletion = nil
            }
        } message: {
            Text("Delete glue record \(recordPendingDeletion?.name ?? "")?")
        }
        .alert("Request Failed", isPresented: mutationErrorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.mutationErrorMessage ?? "")
        }
    }

    private var deleteAlertTitle: String {
        guard let recordPendingDeletion else { return "" }
        return "Delete glue record \(recordPendingDeletion.name)?"
    }

    private var deleteBinding: Binding<Bool> {
        Binding(
            get: { recordPendingDeletion != nil },
            set: { newValue in
                if !newValue {
                    recordPendingDeletion = nil
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
