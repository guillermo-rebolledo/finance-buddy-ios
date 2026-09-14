import Foundation
import Observation

@MainActor @Observable public final class DeletionStore: Identifiable {
  public let entry: JournalEntry
  public nonisolated var id: String { entry.id }
  public private(set) var busy = false
  public private(set) var error: String?
  public private(set) var deleted = false
  private let client: any APIClient
  public init(entry: JournalEntry, client: any APIClient) {
    self.entry = entry
    self.client = client
  }
  public var message: String {
    "\(entry.kind.title) of \(entry.amount.formatted()) on \(entry.date), in \(entry.categoryName). It leaves your journal and every day, week, and month total that includes it. This cannot be undone."
  }
  public func delete() async {
    guard !busy, !client.access.offline else { return }
    busy = true
    error = nil
    defer { busy = false }
    do {
      try await client.delete(id: entry.id)
      deleted = true
    } catch { self.error = error.localizedDescription }
  }
}
