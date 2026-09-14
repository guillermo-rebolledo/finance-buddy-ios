import AppIntents
import FinanceBuddyCore
import GoogleSignIn
import SwiftUI

struct RootView: View {
  @Bindable var session: SessionStore
  var body: some View {
    Group {
      if session.client.access.upgradeRequired {
        ContentUnavailableView(
          "Update Finance Buddy", systemImage: "arrow.down.app",
          description: Text("Install the latest app build to continue. Your journal is unchanged."))
      } else {
        switch session.state {
        case .loading:
          LoadingView(title: "Opening your journal…")
            .frame(maxHeight: .infinity, alignment: .center)
        case .signedOut: SignInView(session: session)
        case .signedIn: AppShell(session: session).id(session.client.access.sessionGeneration)
        case .unavailable:
          ContentUnavailableView {
            Label("Workspace unavailable", systemImage: "exclamationmark.icloud")
          } description: {
            Text(session.message ?? "Please try again later.")
          } actions: {
            Button("Retry") { Task { await session.restore() } }.buttonStyle(.borderedProminent)
          }
        }
      }
    }
    .safeAreaInset(edge: .top) {
      if session.client.access.offline {
        Label("You’re offline. Reconnect to make changes.", systemImage: "wifi.slash")
          .font(.callout).frame(maxWidth: .infinity).padding(12).background(.bar)
      }
    }
    .task { await session.restore() }
    .onChange(of: session.client.access.signedOut) { _, signedOut in
      if signedOut && session.state == .signedIn {
        session.didLoseSession()
        GIDSignIn.sharedInstance.signOut()
      }
    }
  }
}
