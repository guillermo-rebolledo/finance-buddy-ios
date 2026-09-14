import Foundation
import Observation

@MainActor @Observable public final class CategoriesStore {
  public private(set) var lists: CategoryLists?
  public private(set) var loading = false
  public private(set) var busy = false
  public private(set) var error: String?
  public private(set) var pending: CategoryRequest?
  public private(set) var confirmation: String?
  public private(set) var changeCount = 0
  private let client: any APIClient
  private var sequence = 0
  public init(client: any APIClient, lists: CategoryLists? = nil) {
    self.client = client
    self.lists = lists
  }
  public func load() async {
    sequence += 1
    let current = sequence
    loading = true
    do {
      let result = try await client.categories()
      guard sequence == current else { return }
      lists = result
      error = nil
      loading = false
    } catch {
      guard sequence == current else { return }
      self.error = error.localizedDescription
      loading = false
    }
  }
  public func change(_ request: CategoryRequest) async {
    guard !busy, !client.access.offline else { return }
    busy = true
    error = nil
    pending = request
    defer { busy = false }
    do {
      try await client.changeCategory(request)
      pending = nil
      confirmation =
        request.action == .archive
        ? "Category archived. Existing entries and totals keep it." : "Category restored."
      changeCount += 1
      await load()
    } catch { self.error = error.localizedDescription }
  }
  public func retry() async { if let pending { await change(pending) } else { await load() } }
  public func editorSaved(renamed: Bool) async {
    confirmation = renamed ? "Category renamed." : "Category added."
    changeCount += 1
    await load()
  }
}
