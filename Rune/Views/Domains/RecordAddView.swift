import SwiftUI

struct RecordAddView: View {
    let domainName: String
    @ObservedObject var viewModel: DomainViewModel
    let client: NjallaClient

    @Environment(\.dismiss) private var dismiss

    @State private var draft = DNSRecordDraft()
    var body: some View {
        Form {
            DNSRecordFormSections(draft: $draft)

            Section {
                Button("Save") {
                    Task {
                        await save()
                    }
                }
                .disabled(viewModel.isSaving || !draft.canSubmit)
            }
        }
        .navigationTitle("Add Record")
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
        .onChange(of: draft.type) { oldValue, newValue in
            guard oldValue != newValue else { return }
            draft.resetTypeSpecificFields()
        }
        .alert("Request Failed", isPresented: mutationErrorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.mutationErrorMessage ?? "")
        }
    }

    private func save() async {
        guard !viewModel.isSaving else {
            return
        }

        do {
            try await viewModel.addRecord(for: domainName, draft: draft, client: client)
            draft = DNSRecordDraft()
            dismiss()
        } catch is CancellationError {
            return
        } catch {
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
}

struct DNSRecordFormSections: View {
    @Binding var draft: DNSRecordDraft

    var body: some View {
        Section("Record") {
            Picker("Type", selection: $draft.type) {
                ForEach(DNSRecordType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }

            TextField("Name", text: $draft.name)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }

        if draft.type.usesContent {
            Section("Content") {
                TextField("Content", text: $draft.content, axis: .vertical)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
        }

        if draft.type.usesTTL {
            Section("TTL") {
                Picker("TTL", selection: $draft.ttlSeconds) {
                    ForEach(draft.ttlOptions) { option in
                        Text(option.isCustom ? "Custom (\(option.label))" : option.label)
                            .tag(option.seconds)
                    }
                }
            }
        }

        if draft.type.usesPriority {
            Section("Priority") {
                TextField("Priority", text: $draft.prio)
                    .keyboardType(.numberPad)
            }
        }

        if draft.type.usesWeight {
            Section("Weight") {
                TextField("Weight", text: $draft.weight)
                    .keyboardType(.numberPad)
            }
        }

        if draft.type.usesPort {
            Section("Port") {
                TextField("Port", text: $draft.port)
                    .keyboardType(.numberPad)
            }
        }

        if draft.type.usesTarget {
            Section("Target") {
                TextField("Target", text: $draft.target)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
        }

        if draft.type.usesSSHFields {
            Section {
                TextField("SSH Algorithm", text: $draft.sshAlgorithm)
                    .keyboardType(.numberPad)
                TextField("SSH Type", text: $draft.sshType)
                    .keyboardType(.numberPad)
            } header: {
                Text("SSHFP")
            } footer: {
                Text("Algorithm values: 1-5. Type values: 1-2.")
            }
        }
    }
}
