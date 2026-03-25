import SwiftUI

struct TokenAddView: View {
    @ObservedObject var viewModel: TokenViewModel
    let client: NjallaClient

    @Environment(\.dismiss) private var dismiss

    @State private var comment = ""
    @State private var fromText = ""
    @State private var allowedMethodsText = ""
    @State private var ipValidationMessage: String?
    @State private var methodValidationMessage: String?

    var body: some View {
        Form {
            Section("Token") {
                TextField("Comment", text: $comment)
            }

            Section {
                TextEditor(text: $fromText)
                    .frame(minHeight: 100)
                if let ipValidationMessage {
                    Text(ipValidationMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            } header: {
                Text("IP Restrictions")
            } footer: {
                Text("Enter one IPv4, IPv6, or CIDR range per line.")
            }

            Section {
                TextEditor(text: $allowedMethodsText)
                    .frame(minHeight: 100)
                if let methodValidationMessage {
                    Text(methodValidationMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            } header: {
                Text("Allowed Methods")
            } footer: {
                Text("Enter one API method per line, for example `list-domains`.")
            }

            Section {
                Button("Save") {
                    Task {
                        await save()
                    }
                }
                .disabled(viewModel.isSaving)
            }
        }
        .navigationTitle("Add Token")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
            }
        }
        .onChange(of: fromText) { _, _ in
            ipValidationMessage = nil
        }
        .onChange(of: allowedMethodsText) { _, _ in
            methodValidationMessage = nil
        }
        .alert("API Error", isPresented: errorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private func save() async {
        guard validateInput() else {
            return
        }

        let request = TokenCreateRequest(
            comment: comment,
            from: lines(fromText),
            allowedMethods: lines(allowedMethodsText)
        )

        if await viewModel.addToken(request: request, client: client) {
            dismiss()
        }
    }

    private func lines(_ value: String) -> [String] {
        value
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func validateInput() -> Bool {
        let ipEntries = lines(fromText)
        let methodEntries = lines(allowedMethodsText)

        ipValidationMessage = ipEntries.allSatisfy(isValidIPOrCIDR(_:))
            ? nil
            : "One or more entries are not valid IP addresses or CIDR ranges."

        methodValidationMessage = methodEntries.allSatisfy(isValidMethodName(_:))
            ? nil
            : "One or more method names appear invalid. Use format: list-domains"

        return ipValidationMessage == nil && methodValidationMessage == nil
    }

    private func isValidMethodName(_ value: String) -> Bool {
        value.range(of: "^[a-z-]+$", options: .regularExpression) != nil
    }

    private func isValidIPOrCIDR(_ value: String) -> Bool {
        let pattern = #"^((\d{1,3}\.){3}\d{1,3})(/(3[0-2]|[12]?\d))?$|^([0-9A-Fa-f:]+)(/\d{1,3})?$"#
        return value.range(of: pattern, options: .regularExpression) != nil
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
