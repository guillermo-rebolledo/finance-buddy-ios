import FinanceBuddyCore
import SwiftUI

enum PreviewScreen: String {
  case categoryEditor, budgetEditor, budgets
  case entries, dashboard, categories, settings, signIn, editor, deletion, export, unavailable,
    upgrade
}
enum PreviewFixture { case week, emptyDay, failedLoad }
struct ScreenPreview: View {
  let screen: PreviewScreen
  @State private var api: FakeAPIClient
  @State private var period: PeriodStore
  @State private var session: SessionStore
  let fixture: PreviewFixture
  init(_ screen: PreviewScreen, fixture: PreviewFixture = .week) {
    self.screen = screen
    self.fixture = fixture
    let api = FakeAPIClient()
    let selection =
      fixture == .emptyDay ? PeriodSelection(kind: .day, date: Fixtures.today) : PeriodSelection()
    let summary = Fixtures.summary(selection)
    _api = State(initialValue: api)
    _period = State(
      initialValue: PeriodStore(client: api, summary: summary, trends: Fixtures.trends(selection)))
    _session = State(initialValue: SessionStore(client: api))
  }
  var body: some View {
    Group {
      switch screen {
      case .entries: NavigationStack { EntriesView(period: period, client: api) }
      case .dashboard: NavigationStack { DashboardView(period: period, client: api) {} }
      case .budgets:
        NavigationStack {
          BudgetsView(
            client: api, onChanged: {}, store: BudgetsStore(client: api, list: Fixtures.budgetList()))
        }
      case .budgetEditor:
        BudgetEditorView(
          store: BudgetEditorStore(client: api, kind: .week, date: Fixtures.today), offline: false
        ) { _ in }
      case .categories:
        NavigationStack {
          CategoriesView(
            client: api, onChanged: {},
            store: CategoriesStore(client: api, lists: Fixtures.categories))
        }
      case .settings:
        NavigationStack { SettingsView(session: session) }.task { await session.restore() }
      case .signIn: SignInView(session: session)
      case .editor:
        EntryEditorView(
          store: EntryEditorStore(
            client: api, today: Fixtures.today, categories: Fixtures.categories.all,
            entry: Fixtures.entries[3]), offline: false
        ) { _, _ in }
      case .categoryEditor:
        CategoryEditorView(
          store: CategoryEditorStore(client: api, kind: .income, all: Fixtures.categories.all),
          offline: false
        ) {}
      case .deletion:
        DeleteEntryView(
          store: DeletionStore(entry: Fixtures.entries[1], client: api), offline: false
        ) {}
      case .export: ExportPreview(api: api)
      case .unavailable:
        ContentUnavailableView(
          "Workspace unavailable", systemImage: "exclamationmark.icloud",
          description: Text("Please try again later."))
      case .upgrade:
        ContentUnavailableView(
          "Update Finance Buddy", systemImage: "arrow.down.app",
          description: Text("Install the latest app build to continue. Your journal is unchanged."))
      }
    }.task {
      if fixture == .failedLoad {
        api.failure = Refusal(.unavailable, message: "Workspace temporarily unavailable.")
        period.previous()
        await period.refresh(dashboard: true)
      }
    }
  }
}
struct ExportPreview: View {
  let api: FakeAPIClient
  @State private var store: ExportStore
  init(api: FakeAPIClient) {
    self.api = api
    _store = State(initialValue: ExportStore(client: api))
  }
  var body: some View {
    ExportView(store: store, offline: false).task {
      api.failure = Refusal(.reconnectRequired, message: "Reconnect")
      await store.begin(.sheets, summary: Fixtures.summary())
    }
  }
}

#Preview("entries · Light") { ScreenPreview(.entries).preferredColorScheme(.light) }

#Preview("entries · Dark") { ScreenPreview(.entries).preferredColorScheme(.dark) }

#Preview("entries · Accessibility") { ScreenPreview(.entries).dynamicTypeSize(.accessibility5) }

#Preview("dashboard · Light") { ScreenPreview(.dashboard).preferredColorScheme(.light) }

#Preview("dashboard · Dark") { ScreenPreview(.dashboard).preferredColorScheme(.dark) }

#Preview("dashboard · Accessibility") { ScreenPreview(.dashboard).dynamicTypeSize(.accessibility5) }

#Preview("categories · Light") { ScreenPreview(.categories).preferredColorScheme(.light) }

#Preview("categories · Dark") { ScreenPreview(.categories).preferredColorScheme(.dark) }

#Preview("categories · Accessibility") {
  ScreenPreview(.categories).dynamicTypeSize(.accessibility5)
}

#Preview("settings · Light") { ScreenPreview(.settings).preferredColorScheme(.light) }

#Preview("settings · Dark") { ScreenPreview(.settings).preferredColorScheme(.dark) }

#Preview("settings · Accessibility") { ScreenPreview(.settings).dynamicTypeSize(.accessibility5) }

#Preview("signIn · Light") { ScreenPreview(.signIn).preferredColorScheme(.light) }

#Preview("signIn · Dark") { ScreenPreview(.signIn).preferredColorScheme(.dark) }

#Preview("signIn · Accessibility") { ScreenPreview(.signIn).dynamicTypeSize(.accessibility5) }

#Preview("editor · Light") { ScreenPreview(.editor).preferredColorScheme(.light) }

#Preview("editor · Dark") { ScreenPreview(.editor).preferredColorScheme(.dark) }

#Preview("editor · Accessibility") { ScreenPreview(.editor).dynamicTypeSize(.accessibility5) }

#Preview("deletion · Light") { ScreenPreview(.deletion).preferredColorScheme(.light) }

#Preview("deletion · Dark") { ScreenPreview(.deletion).preferredColorScheme(.dark) }

#Preview("deletion · Accessibility") { ScreenPreview(.deletion).dynamicTypeSize(.accessibility5) }

#Preview("export · Light") { ScreenPreview(.export).preferredColorScheme(.light) }

#Preview("export · Dark") { ScreenPreview(.export).preferredColorScheme(.dark) }

#Preview("export · Accessibility") { ScreenPreview(.export).dynamicTypeSize(.accessibility5) }

#Preview("unavailable · Light") { ScreenPreview(.unavailable).preferredColorScheme(.light) }

#Preview("unavailable · Dark") { ScreenPreview(.unavailable).preferredColorScheme(.dark) }

#Preview("unavailable · Accessibility") {
  ScreenPreview(.unavailable).dynamicTypeSize(.accessibility5)
}

#Preview("upgrade · Light") { ScreenPreview(.upgrade).preferredColorScheme(.light) }

#Preview("upgrade · Dark") { ScreenPreview(.upgrade).preferredColorScheme(.dark) }

#Preview("upgrade · Accessibility") { ScreenPreview(.upgrade).dynamicTypeSize(.accessibility5) }

#Preview("entries · emptyDay · Light") {
  ScreenPreview(.entries, fixture: .emptyDay).preferredColorScheme(.light)
}

#Preview("entries · emptyDay · Dark") {
  ScreenPreview(.entries, fixture: .emptyDay).preferredColorScheme(.dark)
}

#Preview("entries · emptyDay · Accessibility") {
  ScreenPreview(.entries, fixture: .emptyDay).dynamicTypeSize(.accessibility5)
}

#Preview("dashboard · emptyDay · Light") {
  ScreenPreview(.dashboard, fixture: .emptyDay).preferredColorScheme(.light)
}

#Preview("dashboard · emptyDay · Dark") {
  ScreenPreview(.dashboard, fixture: .emptyDay).preferredColorScheme(.dark)
}

#Preview("dashboard · emptyDay · Accessibility") {
  ScreenPreview(.dashboard, fixture: .emptyDay).dynamicTypeSize(.accessibility5)
}

#Preview("entries · failedLoad · Light") {
  ScreenPreview(.entries, fixture: .failedLoad).preferredColorScheme(.light)
}

#Preview("entries · failedLoad · Dark") {
  ScreenPreview(.entries, fixture: .failedLoad).preferredColorScheme(.dark)
}

#Preview("entries · failedLoad · Accessibility") {
  ScreenPreview(.entries, fixture: .failedLoad).dynamicTypeSize(.accessibility5)
}

#Preview("dashboard · failedLoad · Light") {
  ScreenPreview(.dashboard, fixture: .failedLoad).preferredColorScheme(.light)
}

#Preview("dashboard · failedLoad · Dark") {
  ScreenPreview(.dashboard, fixture: .failedLoad).preferredColorScheme(.dark)
}

#Preview("dashboard · failedLoad · Accessibility") {
  ScreenPreview(.dashboard, fixture: .failedLoad).dynamicTypeSize(.accessibility5)
}

#Preview("budgets · Light") { ScreenPreview(.budgets).preferredColorScheme(.light) }

#Preview("budgets · Dark") { ScreenPreview(.budgets).preferredColorScheme(.dark) }

#Preview("budgets · Accessibility") { ScreenPreview(.budgets).dynamicTypeSize(.accessibility5) }

#Preview("Budget editor · Light") { ScreenPreview(.budgetEditor).preferredColorScheme(.light) }

#Preview("Budget editor · Dark") { ScreenPreview(.budgetEditor).preferredColorScheme(.dark) }

#Preview("Budget editor · Accessibility") {
  ScreenPreview(.budgetEditor).dynamicTypeSize(.accessibility5)
}

#Preview("Category editor · Light") { ScreenPreview(.categoryEditor).preferredColorScheme(.light) }

#Preview("Category editor · Dark") { ScreenPreview(.categoryEditor).preferredColorScheme(.dark) }

#Preview("Category editor · Accessibility") {
  ScreenPreview(.categoryEditor).dynamicTypeSize(.accessibility5)
}
