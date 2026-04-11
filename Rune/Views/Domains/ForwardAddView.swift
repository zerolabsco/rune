import SwiftUI

struct ForwardAddView: View {
    let domainName: String
    @ObservedObject var viewModel: DomainViewModel
    let client: NjallaClient

    @Environment(\.dismiss) private var dismiss

    @State private var from = ""
    @State private var to = ""

    var body: some View {
        Form {
            Section {
                TextField("From", text: $from)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                TextField("To", text: $to)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
            } header: {
                Text("Forward")
            } footer: {
                Text("Creates \(trimmedFrom)@\(domainName) -> \(trimmedTo)")
            }

            Section {
                Button("Save") {
                    Task {
                        await save()
                    }
                }
                .disabled(viewModel.isSaving || !canSubmit)
            }
        }
        .navigationTitle("Add Forward")
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
        .alert("Request Failed", isPresented: mutationErrorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.mutationErrorMessage ?? "")
        }
    }

    private var trimmedFrom: String {
        from.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedTo: String {
        to.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSubmit: Bool {
        !trimmedFrom.isEmpty && !trimmedTo.isEmpty
    }

    private func save() async {
        guard !viewModel.isSaving, canSubmit else {
            return
        }

        let forward = EmailForward(domain: domainName, from: trimmedFrom, to: trimmedTo)

        debugLog("Creating forward \(forward.from)@\(forward.domain) -> \(forward.to)")
        do {
            try await viewModel.addForward(forward, client: client)
            debugLog("Created forward \(forward.from)@\(forward.domain) -> \(forward.to)")
            dismiss()
        } catch is CancellationError {
            debugLog("Create cancelled for \(forward.from)@\(forward.domain) -> \(forward.to)")
            return
        } catch {
            debugLog("Create failed for \(forward.from)@\(forward.domain) -> \(forward.to): \(error.localizedDescription)")
            return
        }
    }

    private var mutationErrorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.mutationErrorMessage != nil },
            set: { newValue in
                if !newValue {
                    viewModel.dismissMutationError()
                }
            }
        )
    }

    private func debugLog(_ message: String) {
        #if DEBUG
        debugPrint("[ForwardAddView]", message)
        #endif
    }
}
