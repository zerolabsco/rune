import SwiftUI

struct ForwardListView: View {
    let domainName: String
    @ObservedObject var viewModel: DomainViewModel
    let client: NjallaClient

    @State private var showingAddForward = false
    @State private var forwardPendingDeletion: EmailForward?

    var body: some View {
        List {
            if let errorMessage = viewModel.forwardsErrorMessage {
                Section {
                    InlineErrorView(message: errorMessage, retryTitle: "Retry Forwards") {
                        Task {
                            await viewModel.loadForwards(for: domainName, client: client)
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
            }

            if viewModel.isLoadingForwards && viewModel.forwards.isEmpty {
                Section {
                    HStack {
                        Spacer()
                        ProgressView("Loading Forwards")
                        Spacer()
                    }
                }
            } else if viewModel.forwards.isEmpty {
                Section {
                    ContentUnavailableView(
                        "No Forwards",
                        systemImage: "envelope",
                        description: Text("No email forwards are configured for this domain.")
                    )
                }
            } else {
                ForEach(viewModel.forwards) { forward in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("@\(forward.from)")
                            .font(.headline)
                        Text(forward.to)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                    .swipeActions {
                        Button("Delete", role: .destructive) {
                            guard !viewModel.isSaving else { return }
                            forwardPendingDeletion = forward
                        }
                    }
                    .contextMenu {
                        Button("Delete Forward", role: .destructive) {
                            forwardPendingDeletion = forward
                        }
                    }
                    .disabled(viewModel.isSaving)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Forwards")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button {
                showingAddForward = true
            } label: {
                Label("Add Forward", systemImage: "plus")
            }
            .disabled(viewModel.isSaving)
        }
        .sheet(isPresented: $showingAddForward) {
            NavigationStack {
                ForwardAddView(domainName: domainName, viewModel: viewModel, client: client)
            }
        }
        .task {
            debugLog("Loading forwards for \(domainName)")
            await viewModel.loadForwards(for: domainName, client: client)
            debugLog("Loaded \(viewModel.forwards.count) forwards for \(domainName)")
        }
        .refreshable {
            debugLog("Refreshing forwards for \(domainName)")
            await viewModel.loadForwards(for: domainName, client: client)
            debugLog("Refresh complete with \(viewModel.forwards.count) forwards for \(domainName)")
        }
        .overlay(alignment: .top) {
            if viewModel.isLoadingForwards && !viewModel.forwards.isEmpty {
                ProgressView()
                    .padding(.top, 8)
            }
        }
        .alert(deleteAlertTitle, isPresented: deleteBinding) {
            Button("Delete Forward", role: .destructive) {
                guard let forwardPendingDeletion else { return }
                Task {
                    await delete(forwardPendingDeletion)
                }
            }
            Button("Cancel", role: .cancel) {
                forwardPendingDeletion = nil
            }
        } message: {
            Text("Delete the forward from \(forwardPendingDeletion?.from ?? "") to \(forwardPendingDeletion?.to ?? "")?")
        }
        .alert("Request Failed", isPresented: mutationErrorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.mutationErrorMessage ?? "")
        }
    }

    private func delete(_ forward: EmailForward) async {
        guard !viewModel.isSaving else {
            return
        }

        debugLog("Deleting forward \(forward.from)@\(forward.domain) -> \(forward.to)")
        do {
            try await viewModel.removeForward(forward, client: client)
            debugLog("Deleted forward \(forward.from)@\(forward.domain) -> \(forward.to)")
            forwardPendingDeletion = nil
        } catch is CancellationError {
            debugLog("Delete cancelled for \(forward.from)@\(forward.domain) -> \(forward.to)")
            return
        } catch {
            debugLog("Delete failed for \(forward.from)@\(forward.domain) -> \(forward.to): \(error.localizedDescription)")
            return
        }
    }

    private var deleteAlertTitle: String {
        guard let forwardPendingDeletion else {
            return ""
        }

        return "Delete forward \(forwardPendingDeletion.from)@\(domainName)?"
    }

    private var deleteBinding: Binding<Bool> {
        Binding(
            get: { forwardPendingDeletion != nil },
            set: { newValue in
                if !newValue {
                    forwardPendingDeletion = nil
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

    private func debugLog(_ message: String) {
        #if DEBUG
        debugPrint("[ForwardListView]", message)
        #endif
    }
}
