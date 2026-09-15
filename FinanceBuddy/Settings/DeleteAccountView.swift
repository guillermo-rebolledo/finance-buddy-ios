import SwiftUI

struct DeleteAccountView: View {
  let disabled: Bool
  let onConfirm: () -> Void
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      Form {
        Section {
          Text("Delete your account permanently?").font(.title2.bold())
            .accessibilityAddTraits(.isHeader)
          Text("Your financial movements, categories, budgets and export history will be permanently deleted. This cannot be undone.")
          Text("Spreadsheets already in your Google Drive and PDFs you saved are not deleted.")
          Text("You will be signed out on every device, including browsers.")
          Text("If you sign in with Google and Apple using the same verified email, your one shared journal is deleted.")
        }.fixedSize(horizontal: false, vertical: true)
        Section {
          Button("Delete Permanently", role: .destructive, action: onConfirm)
            .frame(minHeight: 44).disabled(disabled)
          Button("Keep Account", role: .cancel) { dismiss() }.frame(minHeight: 44)
        }
      }.navigationTitle("Delete Account").navigationBarTitleDisplayMode(.inline)
    }
  }
}
