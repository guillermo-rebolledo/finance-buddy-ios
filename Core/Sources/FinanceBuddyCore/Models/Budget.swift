import Foundation

/// One period's budget beside that period's total expenses, as the server figures it. The summary,
/// the budgets list, and every budget write reply share this shape. Nothing here computes periods.
public struct BudgetView: Codable, Hashable, Sendable, Identifiable {
  public let kind: PeriodKind
  public let start: CalendarDate
  public let end: CalendarDate
  public let amount: Money
  public let repeats: Bool
  public let expenses: Money
  public let remaining: Money
  public let overBudget: Bool
  public let daysLeft: Int?
  public let leftPerDay: Money?
  public init(
    kind: PeriodKind, start: CalendarDate, end: CalendarDate, amount: Money, repeats: Bool,
    expenses: Money, remaining: Money, overBudget: Bool, daysLeft: Int?, leftPerDay: Money?
  ) {
    self.kind = kind
    self.start = start
    self.end = end
    self.amount = amount
    self.repeats = repeats
    self.expenses = expenses
    self.remaining = remaining
    self.overBudget = overBudget
    self.daysLeft = daysLeft
    self.leftPerDay = leftPerDay
  }
  public var id: String { "\(kind.rawValue):\(start)" }
  public func contains(_ day: CalendarDate) -> Bool { start <= day && day <= end }
  public func hasEnded(_ today: CalendarDate) -> Bool { end < today }
  public var source: String { repeats ? "Repeating" : "One-off" }
  /// "Over by MXN X", "Under by MXN X" for an ended period, otherwise "MXN X left".
  public func standing(ended: Bool = false) -> String {
    if overBudget { return "Over by \(Money(-remaining.value).formatted())" }
    return ended ? "Under by \(remaining.formatted())" : "\(remaining.formatted()) left"
  }
  /// The line an entry's confirmation carries: "MXN 1,240.00 left this week".
  public func line(today: CalendarDate) -> String {
    "\(standing()) \(contains(today) ? kind.currentTitle.lowercased() : phrase(today: today))"
  }
  public var leftPerDayText: (amount: String, days: String)? {
    guard let leftPerDay, let daysLeft else { return nil }
    return (
      "\(leftPerDay.formatted()) left per day",
      daysLeft == 1 ? "Today is the last day" : "\(daysLeft) days left, counting today"
    )
  }
  public func label(today: CalendarDate) -> String {
    kind.label(start: start, end: end, today: today)
  }
  public func phrase(today: CalendarDate) -> String {
    kind.phrase(start: start, end: end, today: today)
  }
}

public struct RepeatingSpan: Codable, Hashable, Sendable, Identifiable {
  public let kind: PeriodKind
  public let start: CalendarDate
  public let amount: Money
  public let until: CalendarDate?
  public init(kind: PeriodKind, start: CalendarDate, amount: Money, until: CalendarDate?) {
    self.kind = kind
    self.start = start
    self.amount = amount
    self.until = until
  }
  public var id: String { "\(kind.rawValue):\(start)" }
  /// "From the week of 7 Sep through the week of 28 Sep".
  public func label(today: CalendarDate) -> String {
    "From \(kind.spanStartName(start, today: today))"
      + (until.map { " through \(kind.spanStartName($0, today: today))" } ?? "")
  }
}

public struct BudgetList: Codable, Sendable {
  public struct Now: Codable, Sendable {
    public let day: BudgetView?
    public let week: BudgetView?
    public let month: BudgetView?
    public init(day: BudgetView?, week: BudgetView?, month: BudgetView?) {
      self.day = day
      self.week = week
      self.month = month
    }
    public subscript(kind: PeriodKind) -> BudgetView? {
      switch kind {
      case .day: day
      case .week: week
      case .month: month
      }
    }
  }
  public let today: CalendarDate
  public let currency: String
  public let now: Now
  public let repeating: [RepeatingSpan]
  public let upcoming: [BudgetView]
  public let past: [BudgetView]
  public let nextBefore: String?
  public init(
    today: CalendarDate, currency: String, now: Now, repeating: [RepeatingSpan],
    upcoming: [BudgetView], past: [BudgetView], nextBefore: String?
  ) {
    self.today = today
    self.currency = currency
    self.now = now
    self.repeating = repeating
    self.upcoming = upcoming
    self.past = past
    self.nextBefore = nextBefore
  }
  public var isEmpty: Bool {
    PeriodKind.allCases.allSatisfy { now[$0] == nil } && repeating.isEmpty && upcoming.isEmpty
      && past.isEmpty
  }
  /// Another page of Past, continued after this one.
  public func appending(_ next: BudgetList) -> BudgetList {
    BudgetList(
      today: today, currency: currency, now: now, repeating: repeating, upcoming: upcoming,
      past: past + next.past, nextBefore: next.nextBefore)
  }
}

public struct BudgetRequest: Codable, Equatable, Sendable {
  public let amount: Money
  public let oneOff: Bool
  public init(amount: Money, oneOff: Bool) {
    self.amount = amount
    self.oneOff = oneOff
  }
}

/// "period" removes a one-off budget; "onward" stops the repeating budget from the period.
public enum BudgetRemovalScope: String, Codable, Sendable { case period, onward }

extension CalendarDate {
  /// "7 Sep", adding the year only when it is not today's: "7 Sep 2025".
  public func budgetName(today: CalendarDate) -> String {
    "\(day) \(formatted("MMM"))" + (year == today.year ? "" : " \(year)")
  }
}

extension PeriodKind {
  /// A day has only itself, so left per day describes weeks and months.
  public var hasLeftPerDay: Bool { self != .day }
  /// How a budget names its period: "Sunday 13 Sep", "Week of 14–20 Sep", "September 2026".
  public func label(start: CalendarDate, end: CalendarDate, today: CalendarDate) -> String {
    switch self {
    case .day: "\(start.formatted("EEEE")) \(start.budgetName(today: today))"
    case .week: "Week of \(Self.weekName(start, end, today: today))"
    case .month: start.formatted("MMMM yyyy")
    }
  }
  /// How a sentence names a period: "for the week of 31 Aug – 6 Sep".
  public func phrase(start: CalendarDate, end: CalendarDate, today: CalendarDate) -> String {
    switch self {
    case .day: "on \(start.formatted("EEEE")) \(start.budgetName(today: today))"
    case .week: "for the week of \(Self.weekName(start, end, today: today))"
    case .month: "for \(start.formatted("MMMM yyyy"))"
    }
  }
  /// How a repeating span names a period by its first day: "the week of 7 Sep".
  public func spanStartName(_ start: CalendarDate, today: CalendarDate) -> String {
    switch self {
    case .day: start.budgetName(today: today)
    case .week: "the week of \(start.budgetName(today: today))"
    case .month: start.formatted("MMMM yyyy")
    }
  }
  private static func weekName(_ start: CalendarDate, _ end: CalendarDate, today: CalendarDate)
    -> String
  {
    start.year == end.year && start.month == end.month
      ? "\(start.day)–\(end.budgetName(today: today))"
      : "\(start.budgetName(today: today)) – \(end.budgetName(today: today))"
  }
}
