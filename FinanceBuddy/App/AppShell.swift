import FinanceBuddyCore
import SwiftUI

struct AppShell: View {
  let session: SessionStore
  @State private var period: PeriodStore
  init(session: SessionStore) {
    self.session = session
    _period = State(initialValue: PeriodStore(client: session.client))
  }
  var body: some View {
    TabView {
      NavigationStack {
        EntriesView(period: period, client: session.client)
      }.tabItem { Label("Entries", systemImage: "list.bullet") }
      NavigationStack {
        DashboardView(period: period, client: session.client)
      }.tabItem { Label("Dashboard", systemImage: "chart.bar") }
      NavigationStack {
        CategoriesView(client: session.client) { Task { await period.refresh(dashboard: true) } }
      }.tabItem { Label("Categories", systemImage: "tag") }
      NavigationStack { SettingsView(session: session) }.tabItem {
        Label("Settings", systemImage: "gearshape")
      }
    }.task(id: period.revision) { await period.refresh(dashboard: true) }
  }
}
