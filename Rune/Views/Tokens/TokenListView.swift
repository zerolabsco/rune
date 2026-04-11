import SwiftUI

struct TokenListView: View {
    @ObservedObject var viewModel: TokenViewModel
    let client: NjallaClient?
    let onTokenRemoved: (String) -> Void

    @State private var showingAddToken = false
    @State private var tokenPendingDeletion: APIToken?

    var body: some View {
        NavigationStack {
            Group {
                if let client {
                    content(client: client)
                } else {
                    ContentUnavailableView("Sign in required", systemImage: "key.fill", description: Text("Add a valid Njalla API token to load account tokens."))
                }
            }
            .navigationTitle("Tokens")
            .toolbar {
                if client != nil {
                    Button {
                        showingAddToken = true
                    } label: {
                        Label("Add Token", systemImage: "plus")
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingAddToken) {
            if let client {
                NavigationStack {
                    TokenAddView(viewModel: viewModel, client: client)
                }
            }
        }
        .alert(deletionTitle, isPresented: deleteBinding) {
            Button("Delete Token", role: .destructive) {
                guard let tokenPendingDeletion, let client else { return }
                Task {
                    guard !viewModel.isSaving else { return }
                    let removed = await viewModel.removeToken(tokenPendingDeletion, client: client)
                    if removed {
                        onTokenRemoved(tokenPendingDeletion.key)
                    }
                    self.tokenPendingDeletion = nil
                }
            }

            Button("Cancel", role: .cancel) {
                tokenPendingDeletion = nil
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .alert("Request Failed", isPresented: mutationErrorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.mutationErrorMessage ?? "")
        }
    }

    @ViewBuilder
    private func content(client: NjallaClient) -> some View {
        List {
            if let errorMessage = viewModel.listErrorMessage {
                Section {
                    InlineErrorView(message: errorMessage, retryTitle: "Retry Tokens") {
                        Task {
                            await viewModel.loadTokens(client: client)
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
            }

            if viewModel.isLoading && viewModel.tokens.isEmpty {
                Section {
                    HStack {
                        Spacer()
                        ProgressView("Loading Tokens")
                        Spacer()
                    }
                }
            } else if viewModel.tokens.isEmpty {
                Section {
                    ContentUnavailableView(
                        "No Tokens",
                        systemImage: "key.horizontal",
                        description: Text("No API tokens found. Create a restricted token for specific access.")
                    )
                }
            } else {
                ForEach(viewModel.tokens) { token in
                    TokenRow(token: token, label: viewModel.tokenLabel(for: token))
                        .contentShape(Rectangle())
                        .contextMenu {
                            Button("Delete Token", role: .destructive) {
                                tokenPendingDeletion = token
                            }
                        }
                        .disabled(viewModel.isSaving)
                        .opacity(viewModel.isSaving ? 0.6 : 1)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            await viewModel.loadTokens(client: client)
        }
        .overlay(alignment: .top) {
            if viewModel.isLoading && !viewModel.tokens.isEmpty {
                ProgressView()
                    .padding(.top, 8)
            }
        }
    }

    private var deletionTitle: String {
        guard let tokenPendingDeletion else {
            return ""
        }

        return "Delete token \(viewModel.tokenLabel(for: tokenPendingDeletion))?"
    }

    private var deleteBinding: Binding<Bool> {
        Binding(
            get: { tokenPendingDeletion != nil },
            set: { newValue in
                if !newValue {
                    tokenPendingDeletion = nil
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

private struct TokenRow: View {
    let token: APIToken
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.headline)

            Text(methodsText)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let from = token.from, !from.isEmpty {
                Text("From: \(from.joined(separator: ", "))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let domains = token.allowedDomains, !domains.isEmpty {
                Text("Domains: \(domains.joined(separator: ", "))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var methodsText: String {
        guard let methods = token.allowedMethods, !methods.isEmpty else {
            return "Methods: Unrestricted"
        }

        return "Methods: \(methods.joined(separator: ", "))"
    }
}
