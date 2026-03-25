import SwiftUI

struct RecordEditView: View {
    let domainName: String
    let record: DNSRecord
    @ObservedObject var viewModel: DomainViewModel
    let client: NjallaClient

    @Environment(\.dismiss) private var dismiss

    @State private var draft: DNSRecordDraft
    @State private var showingDeleteConfirmation = false
    @State private var localErrorMessage: String?

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
                    showingDeleteConfirmation = true
                }
                .foregroundStyle(.red)
            }
        }
        .navigationTitle(record.name)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: draft.type) { oldValue, newValue in
            guard oldValue != newValue else { return }
            draft.resetTypeSpecificFields()
        }
        .confirmationDialog(
            "Delete \(record.type) record \(record.name)?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Record", role: .destructive) {
                Task {
                    await deleteRecord()
                }
            }
        }
        .alert("API Error", isPresented: localErrorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(localErrorMessage ?? "")
        }
    }

    private func save() async {
        do {
            try await viewModel.editRecord(for: domainName, recordID: record.id, draft: draft, client: client)
            dismiss()
        } catch is CancellationError {
            return
        } catch {
            if (error as? URLError)?.code == .cancelled {
                return
            }
            localErrorMessage = error.localizedDescription
        }
    }

    private func deleteRecord() async {
        do {
            try await viewModel.removeRecord(record, client: client)
            dismiss()
        } catch is CancellationError {
            return
        } catch {
            if (error as? URLError)?.code == .cancelled {
                return
            }
            localErrorMessage = error.localizedDescription
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
}
