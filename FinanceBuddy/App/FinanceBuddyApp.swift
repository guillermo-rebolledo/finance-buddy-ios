import AppIntents
import FinanceBuddyCore
import GoogleSignIn
import SwiftUI

@main struct FinanceBuddyApp: App {
  @State private var session: SessionStore
  private let connectivity: ConnectivityMonitor?
  init() {
    let client: any APIClient
    #if DEBUG
      if ProcessInfo.processInfo.arguments.contains("-useFakeAPI") {
        client = FakeAPIClient()
      } else {
        client = Self.liveClient()
      }
    #else
      client = Self.liveClient()
    #endif
    _session = State(initialValue: SessionStore(client: client))
    connectivity = client is FakeAPIClient ? nil : ConnectivityMonitor(access: client.access)
  }
  private static func liveClient() -> LiveAPIClient {
    let origin =
      Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String
      ?? "https://finance-buddy-self.vercel.app"
    let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    return LiveAPIClient(
      baseURL: URL(string: origin)!, build: build, tokens: KeychainTokenStorage())
  }
  var body: some Scene {
    WindowGroup {
      Group {
        #if DEBUG
          if let previewScreen {
            ScreenPreview(previewScreen)
          } else {
            RootView(session: session)
          }
        #else
          RootView(session: session)
        #endif
      }
      #if DEBUG
        .modifier(DebugFixtureAppearance())
      #endif
      .onOpenURL { GIDSignIn.sharedInstance.handle($0) }
    }
  }
  #if DEBUG
    private var previewScreen: PreviewScreen? {
      let arguments = ProcessInfo.processInfo.arguments
      guard arguments.contains("-useFakeAPI"),
        let index = arguments.firstIndex(of: "-previewScreen"),
        arguments.indices.contains(index + 1)
      else { return nil }
      return PreviewScreen(rawValue: arguments[index + 1])
    }
  #endif
}
