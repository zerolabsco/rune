import Combine
import Foundation

@MainActor
final class TokenViewModel: ObservableObject {
    @Published private(set) var tokens: [APIToken] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isSaving = false
    @Published var errorMessage: String?

    func reset() {
        tokens = []
        isLoading = false
        isSaving = false
        errorMessage = nil
    }

    func loadTokens(client: NjallaClient) async {
        isLoading = true
        defer {
            isLoading = false
        }

        do {
            tokens = try await client.listTokens().sorted {
                tokenLabel(for: $0).localizedCaseInsensitiveCompare(tokenLabel(for: $1)) == .orderedAscending
            }
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            if (error as? URLError)?.code == .cancelled {
                return
            }
            errorMessage = error.localizedDescription
        }
    }

    func addToken(request: TokenCreateRequest, client: NjallaClient) async -> Bool {
        isSaving = true
        defer {
            isSaving = false
        }

        do {
            try await client.addToken(request: request)
            tokens = try await client.listTokens()
            errorMessage = nil
            return true
        } catch is CancellationError {
            return false
        } catch {
            if (error as? URLError)?.code == .cancelled {
                return false
            }
            errorMessage = error.localizedDescription
            return false
        }
    }

    func removeToken(_ token: APIToken, client: NjallaClient) async -> Bool {
        isSaving = true
        defer {
            isSaving = false
        }

        do {
            try await client.removeToken(key: token.key)
            tokens.removeAll { $0.key == token.key }
            errorMessage = nil
            return true
        } catch is CancellationError {
            return false
        } catch {
            if (error as? URLError)?.code == .cancelled {
                return false
            }
            errorMessage = error.localizedDescription
            return false
        }
    }

    func tokenLabel(for token: APIToken) -> String {
        let trimmedComment = token.comment?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !trimmedComment.isEmpty {
            return trimmedComment
        }

        return String(token.key.prefix(8))
    }
}
