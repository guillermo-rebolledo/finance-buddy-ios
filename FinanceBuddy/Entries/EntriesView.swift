import FinanceBuddyCore
import SwiftUI

struct EntriesView: View {
  @Bindable var period: PeriodStore
  let client: any APIClient
  @State private var editor: EntryEditorStore?
  @State private var deletion: DeletionStore?
  @State private var notification: ToastMessage?
  var body: some View {
    List {
      Section { PeriodPicker(store: period) }
      if period.showsPlaceholder {
        entrySections(Fixtures.entries, headers: true)
          .redacted(reason: .placeholder).disabled(true).accessibilityHidden(true)
      } else if let summary = period.summary {
        if summary.entries.isEmpty {
          ContentUnavailableView(
            "No entries in this period", systemImage: "book.closed",
            description: Text("Record income, an expense, or a refund to begin."))
        }
        entrySections(summary.entries, headers: summary.kind != .day)
      }
    }.listStyle(.insetGrouped).navigationTitle("Entries")
      .smoothChanges(period.showsPlaceholder ? nil : period.summary?.entries.map(\.id))
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          Button("Add entry", systemImage: "plus") { edit(nil) }.disabled(
            period.summary == nil || client.access.offline
          ).accessibilityIdentifier("addEntry")
        }
      }
      .refreshable { await period.refresh(dashboard: true) }
      .sheet(item: $editor) { store in
        EntryEditorView(store: store, offline: client.access.offline, onSaved: entrySaved)
      }
      .sheet(item: $deletion) { store in
        DeleteEntryView(store: store, offline: client.access.offline) {
          notification = ToastMessage(text: "Entry deleted.")
          Task { await period.refresh(dashboard: true) }
        }
      }
      .toast($notification)
      .sensoryFeedback(.success, trigger: notification?.id) { _, value in value != nil }
  }
  private func entrySections(_ entries: [JournalEntry], headers: Bool) -> some View {
    ForEach(Array(Set(entries.map(\.date))).sorted(by: >), id: \.self) { date in
      Section {
        ForEach(entries.filter { $0.date == date }) { entry in
          Button {
            edit(entry)
          } label: {
            EntryRow(entry: entry)
          }.buttonStyle(.plain)
            .accessibilityIdentifier("entry-\(entry.id)")
            .contextMenu {
              Button("Edit", systemImage: "pencil") { edit(entry) }
              Button("Delete", systemImage: "trash", role: .destructive) {
                deletion = DeletionStore(entry: entry, client: client)
              }
            }
            .swipeActions(allowsFullSwipe: false) {
              Button("Delete", systemImage: "trash") {
                deletion = DeletionStore(entry: entry, client: client)
              }.tint(.red).disabled(client.access.offline)
            }
        }
      } header: {
        if headers { Text(date.formatted("EEEE, MMM d")) }
      }
    }
  }
  private func entrySaved(_ date: CalendarDate) {
    if period.summary?.contains(date) == false {
      notification = ToastMessage(
        text: "Entry saved outside the period you are viewing.", actionTitle: "Show"
      ) {
        period.select(.init(kind: period.selection.kind, date: date))
      }
    } else {
      notification = ToastMessage(text: "Entry saved.")
    }
    Task { await period.refresh(dashboard: true) }
  }
  private func edit(_ entry: JournalEntry?) {
    guard let summary = period.summary else { return }
    editor = EntryEditorStore(
      client: client, today: summary.today, categories: summary.categories, entry: entry)
  }
}
