import SwiftUI

struct GlueEditView: View {
    let domainName: String
    let existingRecord: GlueRecord?
    @ObservedObject var viewModel: DomainViewModel
    let client: NjallaClient

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var address4: String
    @State private var address6: String
    @State private var localErrorMessage: String?

    init(domainName: String, existingRecord: GlueRecord?, viewModel: DomainViewModel, client: NjallaClient) {
        self.domainName = domainName
        self.existingRecord = existingRecord
        self.viewModel = viewModel
        self.client = client
        _name = State(initialValue: existingRecord?.name ?? "")
        _address4 = State(initialValue: existingRecord?.address4 ?? "")
        _address6 = State(initialValue: existingRecord?.address6 ?? "")
    }

    var body: some View {
        Form {
            Section("Record") {
                TextField("Name", text: $name)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .disabled(existingRecord != nil)

                TextField("IPv4", text: $address4)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                TextField("IPv6", text: $address6)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
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
        .navigationTitle(existingRecord == nil ? "Add Glue" : "Edit Glue")
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
        .alert("Invalid Glue Data", isPresented: localErrorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(localErrorMessage ?? "")
        }
        .alert("Request Failed", isPresented: mutationErrorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.mutationErrorMessage ?? "")
        }
    }

    private func save() async {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAddress4 = address4.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAddress6 = address6.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            localErrorMessage = "Glue record name is required."
            return
        }

        guard !trimmedAddress4.isEmpty || !trimmedAddress6.isEmpty else {
            localErrorMessage = "Provide at least one address (IPv4 or IPv6)."
            return
        }

        do {
            if existingRecord == nil {
                try await viewModel.addGlue(
                    for: domainName,
                    name: trimmedName,
                    address4: trimmedAddress4.isEmpty ? nil : trimmedAddress4,
                    address6: trimmedAddress6.isEmpty ? nil : trimmedAddress6,
                    client: client
                )
            } else {
                try await viewModel.editGlue(
                    for: domainName,
                    name: trimmedName,
                    address4: trimmedAddress4.isEmpty ? nil : trimmedAddress4,
                    address6: trimmedAddress6.isEmpty ? nil : trimmedAddress6,
                    client: client
                )
            }
            dismiss()
        } catch {
            return
        }
    }

    private var localErrorBinding: Binding<Bool> {
        Binding(
            get: { localErrorMessage != nil },
            set: { newValue in
                if !newValue {
                    localErrorMessage = nil
                }
            }
        )
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
}
