import FinanceBuddyCore
import Network

@MainActor final class ConnectivityMonitor {
  private let monitor = NWPathMonitor()
  init(access: AppAccess) {
    monitor.pathUpdateHandler = { path in
      let offline = path.status != .satisfied
      Task { @MainActor in access.offline = offline }
    }
    monitor.start(queue: DispatchQueue(label: "FinanceBuddy.connectivity"))
  }
  deinit { monitor.cancel() }
}
