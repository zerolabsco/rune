import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    let onLogout: () -> Void
    @State private var showingLogoutConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                Section("Wallet") {
                    if let balance = viewModel.balance {
                        HStack {
                            Text("Balance")
                            Spacer()
                            Text("€\(balance.balance)")
                                .foregroundStyle(.secondary)
                        }
                    } else if viewModel.isLoadingBalance {
                        ProgressView()
                    } else {
                        Text("Wallet balance unavailable.")
                            .foregroundStyle(.secondary)
                    }

                    Button("Refresh Balance") {
                        Task {
                            do {
                                try await viewModel.refreshBalance()
                            } catch {
                                viewModel.errorMessage = error.localizedDescription
                            }
                        }
                    }
                    .disabled(viewModel.client == nil || viewModel.isLoadingBalance)
                }

                Section("Account") {
                    Button("Logout", role: .destructive) {
                        showingLogoutConfirmation = true
                    }
                    .foregroundStyle(.red)
                }

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Settings")
        }
        .confirmationDialog(
            "Log out of Rune?",
            isPresented: $showingLogoutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Log Out", role: .destructive) {
                do {
                    try viewModel.logout()
                    onLogout()
                } catch {
                    viewModel.errorMessage = error.localizedDescription
                }
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your API token will be removed from this device.")
        }
    }
}
