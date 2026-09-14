import Foundation

public struct Summary: Codable, Sendable {
  public let kind: PeriodKind
  public let date: CalendarDate
  public let start: CalendarDate
  public let end: CalendarDate
  public let today: CalendarDate
  public let currency: String
  public let income: Money
  public let expenses: Money
  public let netChange: Money
  public let categories: [Category]
  public let entries: [JournalEntry]
  public let breakdown: [SpendingGroup]
  /// The period's budget, or nil when it has none or the server predates budgets.
  public let budget: BudgetView?
  public var containsToday: Bool { contains(today) }
  public func contains(_ day: CalendarDate) -> Bool { start <= day && day <= end }
  public var selection: PeriodSelection { .init(kind: kind, date: date) }
  public var title: String {
    if containsToday { return kind.currentTitle }
    switch kind {
    case .day: return start.formatted()
    case .week: return "\(start.formatted("MMM d, yyyy")) – \(end.formatted("MMM d, yyyy"))"
    case .month: return start.formatted("MMMM yyyy")
    }
  }
  public var subtitle: String { "\(start) – \(end)" }
}
