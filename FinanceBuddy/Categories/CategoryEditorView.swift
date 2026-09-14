import FinanceBuddyCore
import SwiftUI

struct CategoryEditorView: View {
  @Bindable var store: CategoryEditorStore
  let offline: Bool
  let onSaved: () -> Void
  @Environment(\.dismiss) private var dismiss
  @State private var discard = false
  @State private var notification: ToastMessage?
  @FocusState private var nameFocused: Bool
  var body: some View {
    NavigationStack {
      Form {
        Section {
          LabeledContent("List", value: store.kind.title)
          TextField("Name", text: $store.name)
            .accessibilityLabel("Category name").focused($nameFocused)
            .accessibilityIdentifier("categoryName")
            .disabled(store.busy || store.locked).submitLabel(.done)
        } footer: {
          Text(
            "1–40 characters. Names must be unique within this list, including archived categories."
          )
        }
        if store.locked {
          Text("Retrying keeps the same category name and identifier.").font(.footnote)
        }
      }.navigationTitle(
        store.original == nil ? "New category" : "Rename"
      ).navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { if store.dirty { discard = true } else { dismiss() } }.disabled(
              store.busy || store.locked)
          }
          ToolbarItem(placement: .confirmationAction) {
            Button(store.busy ? "Saving…" : store.locked ? "Retry" : "Save") {
              Task {
                notification = nil
                await store.save()
                if let error = store.error {
                  nameFocused = !store.locked
                  notification = ToastMessage(text: error, isError: true)
                }
              }
            }.disabled(store.busy || offline).accessibilityIdentifier("saveCategory")
          }
        }
        .confirmationDialog(
          "Discard unsaved changes?", isPresented: $discard, titleVisibility: .visible
        ) {
          Button("Discard Changes", role: .destructive) { dismiss() }
          Button("Keep Editing", role: .cancel) {}
        }
        .interactiveDismissDisabled(store.dirty || store.locked || store.busy)
        .onChange(of: store.saved) { _, saved in
          if saved {
            onSaved()
            dismiss()
          }
        }
        .onChange(of: store.error) { if !store.locked { nameFocused = true } }
        .toast($notification)
        .sensoryFeedback(.warning, trigger: store.error)
    }
  }
}
