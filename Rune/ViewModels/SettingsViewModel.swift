import Combine
import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published private(set) var client: NjallaClient?
    @Published private(set) var balance: WalletBalance?
    @Published private(set) var isAuthenticated = false
    @Published private(set) var isBootstrapped = false
    @Published private(set) var isLoadingBalance = false
    @Published var errorMessage: String?

    private let keychainManager = KeychainManager()

    var requiresOnboarding: Bool {
        isBootstrapped && !isAuthenticated
    }

    func bootstrap() async {
        guard !isBootstrapped else { return }

        defer {
            isBootstrapped = true
        }

        do {
            guard let token = try keychainManager.readToken(), !token.isEmpty else {
                isAuthenticated = false
                client = nil
                balance = nil
                return
            }

            let client = NjallaClient(token: token)
            self.client = client
            isAuthenticated = true
            try await refreshBalance()
        } catch is CancellationError {
            return
        } catch {
            if (error as? URLError)?.code == .cancelled {
                return
            }
            errorMessage = error.localizedDescription
            client = nil
            balance = nil
            isAuthenticated = false
        }
    }

    func login(token: String) async throws {
        let trimmedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        let client = NjallaClient(token: trimmedToken)
        let balance = try await client.getBalance()
        try keychainManager.saveToken(trimmedToken)

        self.client = client
        self.balance = balance
        isAuthenticated = true
        isBootstrapped = true
        errorMessage = nil
    }

    func refreshBalance() async throws {
        guard let client else { return }

        isLoadingBalance = true
        defer {
            isLoadingBalance = false
        }

        do {
            balance = try await client.getBalance()
            errorMessage = nil
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            if (error as? URLError)?.code == .cancelled {
                throw error
            }
            errorMessage = error.localizedDescription
            throw error
        }
    }

    func logout() throws {
        try keychainManager.deleteToken()
        client = nil
        balance = nil
        isAuthenticated = false
        errorMessage = nil
    }

    func logoutIfCurrentTokenDeleted(_ key: String) throws -> Bool {
        guard let storedToken = try keychainManager.readToken(), storedToken == key else {
            return false
        }

        try logout()
        return true
    }
}
