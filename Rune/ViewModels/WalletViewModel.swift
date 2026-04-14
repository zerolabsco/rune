import Combine
import Foundation

@MainActor
final class WalletViewModel: ObservableObject {
    @Published private(set) var transactions: [WalletTransaction] = []
    @Published private(set) var selectedPayment: WalletPayment?
    @Published private(set) var isLoadingTransactions = false
    @Published private(set) var isLoadingPayment = false
    @Published var transactionsErrorMessage: String?
    @Published var paymentErrorMessage: String?

    func reset() {
        transactions = []
        selectedPayment = nil
        isLoadingTransactions = false
        isLoadingPayment = false
        transactionsErrorMessage = nil
        paymentErrorMessage = nil
    }

    func loadTransactions(client: NjallaClient) async {
        guard !isLoadingTransactions else { return }

        isLoadingTransactions = true
        defer {
            isLoadingTransactions = false
        }

        do {
            transactions = try await client.listTransactions().sorted {
                ($0.date ?? "", $0.id) > ($1.date ?? "", $1.id)
            }
            transactionsErrorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            if (error as? URLError)?.code == .cancelled {
                return
            }
            transactionsErrorMessage = error.userFacingMessage
        }
    }

    func loadPayment(id: String, client: NjallaClient) async {
        guard !isLoadingPayment else { return }

        isLoadingPayment = true
        defer {
            isLoadingPayment = false
        }

        do {
            selectedPayment = try await client.getPayment(id: id)
            paymentErrorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            if (error as? URLError)?.code == .cancelled {
                return
            }
            paymentErrorMessage = error.userFacingMessage
        }
    }
}
