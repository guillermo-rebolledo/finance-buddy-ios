import FinanceBuddyCore
import QuickLook
import SwiftUI

struct ExportView: View {
  @Bindable var store: ExportStore
  let offline: Bool
  @Environment(\.dismiss) private var dismiss
  @State private var browser: BrowserDestination?
  var body: some View {
    NavigationStack {
      Form {
        if store.busy {
          LoadingView(title: store.kind == .pdf ? "Creating PDF…" : "Creating spreadsheet…")
        }
        if let file = store.fileURL {
          Section {
            Label("PDF created for \(store.periodTitle)", systemImage: "checkmark.circle")
            Button("Preview PDF", systemImage: "doc.richtext") { store.previewURL = file }
            ShareLink("Share PDF", item: file)
          }
        }
        if let spreadsheet = store.spreadsheet {
          Section {
            Label("Spreadsheet created for \(store.periodTitle)", systemImage: "checkmark.circle")
            Button("Open Spreadsheet", systemImage: "arrow.up.right.square") {
              browser = BrowserDestination(url: spreadsheet.url)
            }
          }
        }
        if let error = store.error {
          Section {
            switch store.code {
            case .reconnectRequired:
              Text(
                "Google Sheets export isn't connected. Connect it from the Finance Buddy website's Dashboard, then export again."
              )
              Button("Open Website") { browser = BrowserDestination(url: Website.dashboard) }
              retryButton("Retry")
            case .exportUnconfirmed:
              Text(
                "The spreadsheet's creation could not be confirmed. Check Google Drive before creating a new export; a spreadsheet may already be there."
              )
              Button("Open Google Drive") {
                browser = BrowserDestination(url: URL(string: "https://drive.google.com")!)
              }
              retryButton("Export New Spreadsheet")
            case .exportPeriodMismatch:
              Text(error)
              retryButton("Export New Spreadsheet")
            default:
              Text(error)
              retryButton("Retry")
            }
          }
        }
        Section {
          Text(
            "Exports are snapshots. Later changes to your journal do not change an existing PDF or spreadsheet."
          ).font(.footnote).foregroundStyle(.secondary)
        }
      }
      .navigationTitle(store.kind == .pdf ? "Export PDF" : "Google Sheets")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done") { dismiss() }.disabled(store.busy)
        }
      }
      .interactiveDismissDisabled(store.busy)
      .quickLookPreview($store.previewURL)
      .sheet(item: $browser) { SafariView(url: $0.url) }
      .sensoryFeedback(.success, trigger: store.fileURL)
      .sensoryFeedback(.success, trigger: store.spreadsheet?.url)
      .sensoryFeedback(.warning, trigger: store.error)
    }
  }
  private func retryButton(_ title: String) -> some View {
    Button(title) { Task { await store.retry() } }.disabled(store.busy || offline)
  }
}
