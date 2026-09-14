import Foundation
import Observation

/// The Budgets tab: the budgets in effect today, repeating spans, upcoming one-offs, and a page of
/// ended periods. Stops and removals happen here; setting a budget is the editor store's job.
@MainActor @Observable public final class BudgetsStore {
  public private(set) var list: BudgetList?
  public private(set) var loading: Bool
  public private(set) var loadingMore = false
  public private(set) var busy = false
  public private(set) var error: String?
  public private(set) var confirmation: String?
  public private(set) var changeCount = 0
  private let client: any APIClient
  private var sequence = 0
  public init(client: any APIClient, list: BudgetList? = nil) {
    self.client = client
    self.list = list
    loading = list == nil
  }
  public func load() async {
    sequence += 1
    let current = sequence
    loading = true
    do {
      let result = try await client.budgets(before: nil)
      guard sequence == current else { return }
      list = result
      error = nil
      loading = false
    } catch {
      guard sequence == current else { return }
      self.error = error.localizedDescription
      loading = false
    }
  }
  /// Past arrives a page at a time; each page continues after the last.
  public func showMore() async {
    guard let list, let cursor = list.nextBefore, !loadingMore else { return }
    loadingMore = true
    defer { loadingMore = false }
    do {
      let next = try await client.budgets(before: cursor)
      self.list = list.appending(next)
      error = nil
    } catch { self.error = "Could not load more past budgets. Please retry." }
  }
  /// The first period of a span still to come: its own start when scheduled, otherwise today's.
  public func from(_ span: RepeatingSpan) -> CalendarDate {
    guard let list else { return span.start }
    return max(span.start, list.today)
  }
  public func fromText(_ span: RepeatingSpan) -> String {
    guard let list else { return "" }
    return span.start > list.today
      ? span.kind.spanStartName(span.start, today: list.today)
      : span.kind.currentTitle.lowercased()
  }
  public func stop(_ span: RepeatingSpan) async -> Bool {
    guard
      await remove(.init(kind: span.kind, date: from(span)), scope: .onward) != nil
    else { return false }
    confirmation = "\(span.kind.title) budget stopped from \(fromText(span))."
    return true
  }
  public func removeOneOff(kind: PeriodKind, date: CalendarDate) async -> Bool {
    guard let applies = await remove(.init(kind: kind, date: date), scope: .period) else {
      return false
    }
    confirmation =
      applies.map {
        "One-off budget removed. The repeating budget of \($0.amount.formatted()) applies again."
      } ?? "One-off budget removed."
    return true
  }
  /// Nil when the change was not confirmed; otherwise the budget that now applies, which may be none.
  private func remove(_ period: PeriodSelection, scope: BudgetRemovalScope) async -> BudgetView?? {
    guard !busy, !client.access.offline else { return nil }
    busy = true
    error = nil
    defer { busy = false }
    do {
      let applies = try await client.removeBudget(period, scope: scope)
      changeCount += 1
      await load()
      return .some(applies)
    } catch {
      self.error = error.localizedDescription
      return nil
    }
  }
  public func retry() async { await load() }
}
