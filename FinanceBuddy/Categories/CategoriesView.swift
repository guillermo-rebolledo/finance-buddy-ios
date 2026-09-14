import FinanceBuddyCore
import SwiftUI

struct CategoriesView: View {
  let client: any APIClient
  let onChanged: () -> Void
  @State private var store: CategoriesStore
  @State private var editor: CategoryEditorStore?
  @State private var notification: ToastMessage?
  init(client: any APIClient, onChanged: @escaping () -> Void, store: CategoriesStore? = nil) {
    self.client = client
    self.onChanged = onChanged
    _store = State(initialValue: store ?? CategoriesStore(client: client))
  }
  var body: some View {
    List {
      if let lists = store.lists {
        categorySection(.income, categories: lists.income.filter { $0.active != false })
        categorySection(.expense, categories: lists.expense.filter { $0.active != false })
        Section("Archived") {
          let archived = lists.all.filter { $0.active == false }
          if archived.isEmpty { Text("No archived categories").foregroundStyle(.secondary) }
          ForEach(archived) { row($0) }
        }
      } else if store.loading {
        Group {
          categorySection(.income, categories: Fixtures.categories.income)
          categorySection(.expense, categories: Fixtures.categories.expense)
        }.redacted(reason: .placeholder).disabled(true).accessibilityHidden(true)
      }
    }.listStyle(.insetGrouped).navigationTitle("Categories")
      .smoothChanges(store.lists?.all)
      .task { await store.load(); showResult(includeSuccess: false) }
      .refreshable { await store.load(); showResult(includeSuccess: false) }
      .sheet(item: $editor) { model in
        CategoryEditorView(store: model, offline: client.access.offline) {
          Task {
            await store.editorSaved(renamed: model.original != nil)
            showResult()
          }
        }
      }
      .toast($notification)
      .onChange(of: store.changeCount) { onChanged() }
      .sensoryFeedback(.success, trigger: store.changeCount)
  }
  private func categorySection(_ kind: CategoryKind, categories: [FinanceBuddyCore.Category])
    -> some View
  {
    Section {
      ForEach(categories) { row($0) }
      Button { edit(kind: kind) } label: {
        Text("Add \(kind.rawValue) category")
          .fixedSize(horizontal: false, vertical: true)
          .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
          .contentShape(Rectangle())
      }
      .disabled(store.busy || client.access.offline)
      .accessibilityIdentifier("add-\(kind.rawValue)-category")
    } header: {
      Text(kind.title)
    } footer: {
      Text(
        kind == .income
          ? "Where the money you receive comes from."
          : "What you spend on. Refunds use these categories too.")
    }
  }
  private func row(_ category: FinanceBuddyCore.Category) -> some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text(category.name)
        if category.active == false {
          Text(category.kind.title).font(.caption).foregroundStyle(.secondary)
        }
      }
      Spacer()
      Menu {
        Button("Rename", systemImage: "pencil") { edit(kind: category.kind, original: category) }
        archiveButton(category)
      } label: {
        Image(systemName: "ellipsis")
          .frame(width: 44, height: 44)
          .contentShape(Rectangle())
      }
      .accessibilityLabel("Actions for \(category.name)")
      .disabled(store.busy || client.access.offline)
    }
    .swipeActions(edge: .trailing) {
      archiveButton(category)
        .tint(category.active == false ? .green : .orange)
        .disabled(store.busy || client.access.offline)
    }
    .swipeActions(edge: .leading) {
      Button("Rename", systemImage: "pencil") { edit(kind: category.kind, original: category) }
        .tint(.blue)
        .disabled(store.busy || client.access.offline)
    }
  }
  private func archiveButton(_ category: FinanceBuddyCore.Category) -> some View {
    Button(
      category.active == false ? "Restore" : "Archive",
      systemImage: category.active == false ? "arrow.uturn.backward" : "archivebox"
    ) {
      Task {
        await store.change(
          CategoryRequest(action: category.active == false ? .restore : .archive, id: category.id))
        showResult()
      }
    }
  }
  private func showResult(includeSuccess: Bool = true) {
    if let error = store.error {
      notification = ToastMessage(text: error, isError: true, actionTitle: "Retry") {
        Task {
          await store.retry()
          showResult()
        }
      }
    } else if includeSuccess, let confirmation = store.confirmation {
      notification = ToastMessage(text: confirmation)
    }
  }
  private func edit(kind: CategoryKind, original: FinanceBuddyCore.Category? = nil) {
    editor = CategoryEditorStore(
      client: client, kind: kind, all: store.lists?.all ?? [], original: original)
  }
}
