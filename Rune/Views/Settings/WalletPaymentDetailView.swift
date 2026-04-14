import SwiftUI

struct WalletPaymentDetailView: View {
    let transactionID: String
    @ObservedObject var viewModel: WalletViewModel
    let client: NjallaClient

    var body: some View {
        Group {
            if viewModel.isLoadingPayment && viewModel.selectedPayment == nil {
                ProgressView("Loading Payment")
            } else if let payment = viewModel.selectedPayment {
                List {
                    Section("Payment") {
                        detailRow(label: "ID", value: payment.id ?? transactionID)
                        detailRow(label: "Status", value: payment.status ?? "Not available")
                        detailRow(label: "Amount", value: payment.amount.map { "€\($0)" } ?? "Not available")
                        detailRow(label: "Address", value: payment.address ?? "Not available")
                        detailRow(label: "URL", value: payment.url ?? "Not available")
                    }
                }
                .listStyle(.insetGrouped)
            } else if let errorMessage = viewModel.paymentErrorMessage {
                ContentUnavailableView("Payment Unavailable", systemImage: "exclamationmark.triangle", description: Text(errorMessage))
            } else {
                ContentUnavailableView("Payment Unavailable", systemImage: "creditcard", description: Text("No payment details were returned for this transaction."))
            }
        }
        .navigationTitle("Payment")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadPayment(id: transactionID, client: client)
        }
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }
}
