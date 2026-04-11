import SwiftUI

struct TokenAddView: View {
    @ObservedObject var viewModel: TokenViewModel
    let client: NjallaClient

    @Environment(\.dismiss) private var dismiss

    @State private var comment = ""
    @State private var fromText = ""
    @State private var allowedMethodsText = ""
    @State private var allowedDomainsText = ""
    @State private var unrestrictedConfirmed = false
    @State private var ipValidationMessage: String?
    @State private var methodValidationMessage: String?
    @State private var domainValidationMessage: String?
    @State private var restrictionValidationMessage: String?

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
                TextEditor(text: $allowedDomainsText)
                    .frame(minHeight: 100)
                if let domainValidationMessage {
                    Text(domainValidationMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            } header: {
                Text("Allowed Domains")
            } footer: {
                Text("Optional. Enter one domain per line to limit the token to specific domains.")
            }

            Section("Restrictions") {
                Text("At least one restriction is recommended. Tokens without restrictions can access any allowed API method from any origin.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if lines(fromText).isEmpty && lines(allowedMethodsText).isEmpty && lines(allowedDomainsText).isEmpty {
                    Toggle("I understand this token will be unrestricted", isOn: $unrestrictedConfirmed)
                }

                if let restrictionValidationMessage {
                    Text(restrictionValidationMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
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
        .overlay {
            if viewModel.isSaving {
                ProgressView()
                    .controlSize(.large)
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
                .disabled(viewModel.isSaving)
            }
        }
        .interactiveDismissDisabled(viewModel.isSaving)
        .onChange(of: fromText) { _, _ in
            ipValidationMessage = nil
            restrictionValidationMessage = nil
            unrestrictedConfirmed = false
        }
        .onChange(of: allowedMethodsText) { _, _ in
            methodValidationMessage = nil
            restrictionValidationMessage = nil
            unrestrictedConfirmed = false
        }
        .onChange(of: allowedDomainsText) { _, _ in
            domainValidationMessage = nil
            restrictionValidationMessage = nil
            unrestrictedConfirmed = false
        }
        .alert("Request Failed", isPresented: errorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.mutationErrorMessage ?? "")
        }
    }

    private func save() async {
        guard !viewModel.isSaving else {
            return
        }

        guard validateInput() else {
            return
        }

        let request = TokenCreateRequest(
            comment: comment,
            from: lines(fromText),
            allowedMethods: lines(allowedMethodsText),
            allowedDomains: lines(allowedDomainsText)
        )

        if await viewModel.addToken(request: request, client: client) {
            resetForm()
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
        let domainEntries = lines(allowedDomainsText)

        ipValidationMessage = ipEntries.allSatisfy(isValidIPOrCIDR(_:))
            ? nil
            : "One or more entries are not valid IP addresses or CIDR ranges."

        methodValidationMessage = methodEntries.allSatisfy(isValidMethodName(_:))
            ? nil
            : "One or more method names appear invalid. Use format: list-domains"

        domainValidationMessage = domainEntries.allSatisfy(isValidDomainName(_:))
            ? nil
            : "One or more domain entries appear invalid."

        let hasRestrictions = !ipEntries.isEmpty || !methodEntries.isEmpty || !domainEntries.isEmpty
        restrictionValidationMessage = hasRestrictions || unrestrictedConfirmed
            ? nil
            : "Add at least one restriction or confirm unrestricted token creation."

        return ipValidationMessage == nil &&
            methodValidationMessage == nil &&
            domainValidationMessage == nil &&
            restrictionValidationMessage == nil
    }

    private func isValidMethodName(_ value: String) -> Bool {
        value.range(of: "^[a-z-]+$", options: .regularExpression) != nil
    }

    private func isValidIPOrCIDR(_ value: String) -> Bool {
        let pattern = #"^((\d{1,3}\.){3}\d{1,3})(/(3[0-2]|[12]?\d))?$|^([0-9A-Fa-f:]+)(/\d{1,3})?$"#
        return value.range(of: pattern, options: .regularExpression) != nil
    }

    private func isValidDomainName(_ value: String) -> Bool {
        value.range(of: #"^(?=.{1,253}$)([A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?\.)+[A-Za-z]{2,}$"#, options: .regularExpression) != nil
    }

    private func resetForm() {
        comment = ""
        fromText = ""
        allowedMethodsText = ""
        allowedDomainsText = ""
        unrestrictedConfirmed = false
        ipValidationMessage = nil
        methodValidationMessage = nil
        domainValidationMessage = nil
        restrictionValidationMessage = nil
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.mutationErrorMessage != nil },
            set: { newValue in
                if !newValue {
                    viewModel.dismissMutationError()
                }
            }
        )
    }
}
