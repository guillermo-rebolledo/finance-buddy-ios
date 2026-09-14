import FinanceBuddyCore
import SwiftUI

struct DeleteEntryView: View {
  @Bindable var store: DeletionStore
  let offline: Bool
  let onDeleted: () -> Void
  @Environment(\.dismiss) private var dismiss
  @State private var notification: ToastMessage?
  var body: some View {
    NavigationStack {
      Form {
        Section {
          Text("Delete this entry permanently?").font(.title2.bold())
          Text(store.message)
        }
        Section {
          Button(
            store.busy ? "Deleting…" : store.error == nil ? "Delete Permanently" : "Retry",
            role: .destructive
          ) { Task {
            notification = nil
            await store.delete()
            if let error = store.error {
              notification = ToastMessage(text: error, isError: true)
            }
          } }.disabled(store.busy || offline)
          Button("Keep Entry", role: .cancel) { dismiss() }.disabled(store.busy)
        }
      }.navigationTitle("Delete entry").navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled(store.busy || store.error != nil)
        .onChange(of: store.deleted) { _, deleted in
          if deleted {
            onDeleted()
            dismiss()
          }
        }
        .toast($notification)
        .sensoryFeedback(.warning, trigger: store.error)
    }.presentationDetents([.medium, .large])
  }
}
