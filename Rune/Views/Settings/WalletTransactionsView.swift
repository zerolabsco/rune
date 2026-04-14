import SwiftUI

struct WalletTransactionsView: View {
    @ObservedObject var viewModel: WalletViewModel
    let client: NjallaClient

    var body: some View {
        List {
            if let errorMessage = viewModel.transactionsErrorMessage {
                Section {
                    InlineErrorView(message: errorMessage, retryTitle: "Retry Transactions") {
                        Task {
                            await viewModel.loadTransactions(client: client)
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
            }

            if viewModel.isLoadingTransactions && viewModel.transactions.isEmpty {
                Section {
                    HStack {
                        Spacer()
                        ProgressView("Loading Transactions")
                        Spacer()
                    }
                }
            } else if viewModel.transactions.isEmpty {
                Section {
                    ContentUnavailableView(
                        "No Transactions",
                        systemImage: "eurosign.circle",
                        description: Text("No wallet transactions were returned for this account.")
                    )
                }
            } else {
                ForEach(viewModel.transactions) { transaction in
                    NavigationLink {
                        WalletPaymentDetailView(transactionID: transaction.id, viewModel: viewModel, client: client)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(transaction.type ?? "Transaction")
                                .font(.headline)
                            Text(transactionDateText(transaction))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            if let amount = transaction.amount {
                                Text("Amount: €\(amount)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Transactions")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadTransactions(client: client)
        }
        .refreshable {
            await viewModel.loadTransactions(client: client)
        }
    }

    private func transactionDateText(_ transaction: WalletTransaction) -> String {
        if let date = transaction.date, !date.isEmpty {
            return date
        }
        return "ID: \(transaction.id)"
    }
}
