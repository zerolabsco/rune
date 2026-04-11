import Combine
import Foundation

@MainActor
final class TokenViewModel: ObservableObject {
    @Published private(set) var tokens: [APIToken] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isSaving = false
    @Published var listErrorMessage: String?
    @Published var mutationErrorMessage: String?

    func reset() {
        tokens = []
        isLoading = false
        isSaving = false
        listErrorMessage = nil
        mutationErrorMessage = nil
    }

    func loadTokens(client: NjallaClient) async {
        guard !isLoading else { return }

        isLoading = true
        defer {
            isLoading = false
        }

        do {
            tokens = try await client.listTokens().sorted {
                tokenLabel(for: $0).localizedCaseInsensitiveCompare(tokenLabel(for: $1)) == .orderedAscending
            }
            listErrorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            if (error as? URLError)?.code == .cancelled {
                return
            }
            listErrorMessage = error.userFacingMessage
        }
    }

    func addToken(request: TokenCreateRequest, client: NjallaClient) async -> Bool {
        guard !isSaving else { return false }

        isSaving = true
        mutationErrorMessage = nil

        do {
            try await client.addToken(request: request)
            isSaving = false
            Task {
                await loadTokens(client: client)
            }
            return true
        } catch is CancellationError {
            isSaving = false
            return false
        } catch {
            if (error as? URLError)?.code == .cancelled {
                isSaving = false
                return false
            }
            isSaving = false
            mutationErrorMessage = error.userFacingMessage
            return false
        }
    }

    func removeToken(_ token: APIToken, client: NjallaClient) async -> Bool {
        guard !isSaving else { return false }

        isSaving = true
        mutationErrorMessage = nil

        do {
            try await client.removeToken(key: token.key)
            tokens.removeAll { $0.key == token.key }
            isSaving = false
            Task {
                await loadTokens(client: client)
            }
            return true
        } catch is CancellationError {
            isSaving = false
            return false
        } catch {
            if (error as? URLError)?.code == .cancelled {
                isSaving = false
                return false
            }
            isSaving = false
            mutationErrorMessage = error.userFacingMessage
            return false
        }
    }

    func dismissMutationError() {
        mutationErrorMessage = nil
    }

    func tokenLabel(for token: APIToken) -> String {
        let trimmedComment = token.comment?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !trimmedComment.isEmpty {
            return trimmedComment
        }

        return String(token.key.prefix(8))
    }

    private func sortedTokens(_ tokens: [APIToken]) -> [APIToken] {
        tokens.sorted {
            tokenLabel(for: $0).localizedCaseInsensitiveCompare(tokenLabel(for: $1)) == .orderedAscending
        }
    }
}
