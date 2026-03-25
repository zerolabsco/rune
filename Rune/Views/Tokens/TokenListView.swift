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
        .sheet(isPresented: $showingAddToken) {
            if let client {
                NavigationStack {
                    TokenAddView(viewModel: viewModel, client: client)
                }
            }
        }
        .confirmationDialog(
            deletionTitle,
            isPresented: deleteBinding,
            titleVisibility: .visible
        ) {
            Button("Delete Token", role: .destructive) {
                guard let tokenPendingDeletion, let client else { return }
                Task {
                    let removed = await viewModel.removeToken(tokenPendingDeletion, client: client)
                    if removed {
                        onTokenRemoved(tokenPendingDeletion.key)
                    }
                    self.tokenPendingDeletion = nil
                }
            }
        }
        .alert("API Error", isPresented: errorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    @ViewBuilder
    private func content(client: NjallaClient) -> some View {
        if viewModel.isLoading && viewModel.tokens.isEmpty {
            ProgressView()
        } else if viewModel.tokens.isEmpty {
            ContentUnavailableView("No Tokens", systemImage: "key.horizontal", description: Text("No API tokens were found on this account."))
        } else {
            List(viewModel.tokens) { token in
                Button {
                    tokenPendingDeletion = token
                } label: {
                    TokenRow(token: token, label: viewModel.tokenLabel(for: token))
                }
                .buttonStyle(.plain)
            }
            .listStyle(.insetGrouped)
            .refreshable {
                await viewModel.loadTokens(client: client)
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
