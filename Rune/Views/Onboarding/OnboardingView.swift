import SwiftUI

struct OnboardingView: View {
    @ObservedObject var viewModel: SettingsViewModel

    @State private var token = ""
    @State private var isSubmitting = false
    @State private var localErrorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("Enter Njalla API token", text: $token)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    Button("Validate and Save") {
                        Task {
                            await submit()
                        }
                    }
                    .disabled(isSubmitting || token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                } header: {
                    Text("API Token")
                } footer: {
                    Text("Rune validates the token with `get-balance` before saving it to Keychain.")
                }

                if let localErrorMessage {
                    Section {
                        Text(localErrorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Welcome")
            .overlay {
                if isSubmitting {
                    ProgressView()
                        .controlSize(.large)
                }
            }
        }
    }

    private func submit() async {
        isSubmitting = true
        defer {
            isSubmitting = false
        }

        do {
            try await viewModel.login(token: token)
            localErrorMessage = nil
        } catch {
            localErrorMessage = error.localizedDescription
        }
    }
}
