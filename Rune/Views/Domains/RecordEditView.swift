import SwiftUI

struct RecordEditView: View {
    let domainName: String
    let record: DNSRecord
    @ObservedObject var viewModel: DomainViewModel
    let client: NjallaClient

    @Environment(\.dismiss) private var dismiss

    @State private var draft: DNSRecordDraft
    @State private var showingDeleteConfirmation = false

    init(domainName: String, record: DNSRecord, viewModel: DomainViewModel, client: NjallaClient) {
        self.domainName = domainName
        self.record = record
        self.viewModel = viewModel
        self.client = client
        _draft = State(initialValue: DNSRecordDraft(record: record))
    }

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

            Section {
                Button("Delete Record", role: .destructive) {
                    guard !viewModel.isSaving else { return }
                    showingDeleteConfirmation = true
                }
                .foregroundStyle(.red)
                .disabled(viewModel.isSaving)
            }
        }
        .navigationTitle(record.name)
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if viewModel.isSaving {
                ProgressView()
                    .controlSize(.large)
            }
        }
        .interactiveDismissDisabled(viewModel.isSaving)
        .onChange(of: draft.type) { oldValue, newValue in
            guard oldValue != newValue else { return }
            draft.resetTypeSpecificFields()
        }
        .alert(deleteAlertTitle, isPresented: $showingDeleteConfirmation) {
            Button("Delete Record", role: .destructive) {
                Task {
                    await deleteRecord()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
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
            try await viewModel.editRecord(for: domainName, recordID: record.id, draft: draft, client: client)
            dismiss()
        } catch is CancellationError {
            return
        } catch {
            return
        }
    }

    private func deleteRecord() async {
        guard !viewModel.isSaving else {
            return
        }

        do {
            try await viewModel.removeRecord(record, client: client)
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

    private var deleteAlertTitle: String {
        "Delete \(record.type) record \(record.name)?"
    }
}
