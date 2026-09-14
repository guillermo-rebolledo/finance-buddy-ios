import FinanceBuddyCore
import SwiftUI

struct AppShell: View {
  enum Tab { case entries, dashboard, budgets, categories, settings }
  let session: SessionStore
  @State private var period: PeriodStore
  @State private var tab = Tab.entries
  init(session: SessionStore) {
    self.session = session
    _period = State(initialValue: PeriodStore(client: session.client))
  }
  var body: some View {
    TabView(selection: $tab) {
      NavigationStack {
        EntriesView(period: period, client: session.client)
      }.tabItem { Label("Entries", systemImage: "list.bullet") }.tag(Tab.entries)
      NavigationStack {
        DashboardView(period: period, client: session.client) { tab = .budgets }
      }.tabItem { Label("Dashboard", systemImage: "chart.bar") }.tag(Tab.dashboard)
      NavigationStack {
        BudgetsView(client: session.client) { Task { await period.refresh(dashboard: true) } }
      }.tabItem { Label("Budgets", systemImage: "wallet.pass") }.tag(Tab.budgets)
      NavigationStack {
        CategoriesView(client: session.client) { Task { await period.refresh(dashboard: true) } }
      }.tabItem { Label("Categories", systemImage: "tag") }.tag(Tab.categories)
      NavigationStack { SettingsView(session: session) }.tabItem {
        Label("Settings", systemImage: "gearshape")
      }.tag(Tab.settings)
    }.task(id: period.revision) { await period.refresh(dashboard: true) }
  }
}
