import Foundation

public enum Fixtures {
  public static let today = try! CalendarDate("2026-09-13")
  public static let session = SessionReply(
    user: User(id: "fixture-owner", name: "Journal Owner", email: "owner@example.com"),
    session: SessionReply.Session(id: "fixture-session"))
  public static let categories = CategoryLists(
    income: [Category(id: "10000000-0000-4000-8000-000000000001", kind: .income, name: "Salary")],
    expense: [
      Category(id: "10000000-0000-4000-8000-000000000002", kind: .expense, name: "Groceries"),
      Category(id: "10000000-0000-4000-8000-000000000003", kind: .expense, name: "Dining"),
      Category(
        id: "10000000-0000-4000-8000-000000000004", kind: .expense, name: "Travel", active: false),
    ])
  public static let entries: [JournalEntry] = [
    JournalEntry(
      id: "20000000-0000-4000-8000-000000000001", kind: .income, amount: Money(18000),
      date: try! CalendarDate("2026-09-11"), categoryId: categories.income[0].id,
      category: "Salary", note: "September salary", currency: "MXN"),
    JournalEntry(
      id: "20000000-0000-4000-8000-000000000002", kind: .expense, amount: Money(300),
      date: try! CalendarDate("2026-09-10"), categoryId: categories.expense[0].id,
      category: "Groceries", note: "Weekly groceries", currency: "MXN"),
    JournalEntry(
      id: "20000000-0000-4000-8000-000000000003", kind: .refund, amount: Money(20),
      date: try! CalendarDate("2026-09-12"), categoryId: categories.expense[0].id,
      category: "Groceries", note: "Returned item", currency: "MXN"),
    JournalEntry(
      id: "20000000-0000-4000-8000-000000000004", kind: .expense, amount: Money(1250),
      date: try! CalendarDate("2026-09-09"), categoryId: categories.expense[2].id,
      category: "Travel", note: "Archived category retained", currency: "MXN"),
  ]
  /// A stored budget row as the server keeps it: a span of periods of one kind. A one-off covers
  /// exactly its own period.
  public struct BudgetSpan: Hashable, Sendable {
    public var kind: PeriodKind
    public var start: CalendarDate
    public var until: CalendarDate?
    public var repeats: Bool
    public var amount: Money
    public init(
      kind: PeriodKind, start: CalendarDate, until: CalendarDate?, repeats: Bool, amount: Money
    ) {
      self.kind = kind
      self.start = start
      self.until = until
      self.repeats = repeats
      self.amount = amount
    }
  }
  public static let budgets: [BudgetSpan] = [
    BudgetSpan(
      kind: .week, start: try! CalendarDate("2026-08-31"), until: nil, repeats: true,
      amount: Money(2000)),
    BudgetSpan(
      kind: .week, start: try! CalendarDate("2026-09-21"), until: try! CalendarDate("2026-09-21"),
      repeats: false, amount: Money(5000)),
  ]
  /// Resolves a period's budget as the server does: its one-off, else the repeating span containing it.
  static func storedBudget(_ kind: PeriodKind, start: CalendarDate, in spans: [BudgetSpan])
    -> BudgetSpan?
  {
    if let oneOff = spans.first(where: { $0.kind == kind && !$0.repeats && $0.start == start }) {
      return oneOff
    }
    guard
      let latest = spans.filter({ $0.kind == kind && $0.repeats && $0.start <= start }).max(by: {
        $0.start < $1.start
      }), latest.until == nil || latest.until! >= start
    else { return nil }
    return latest
  }
  /// The shared budget figures: signed remaining, over budget only past the amount, and left per
  /// day for the current week or month, rounded down to the centavo.
  public static func budgetView(
    kind: PeriodKind, start: CalendarDate, end: CalendarDate, amount: Money, repeats: Bool,
    expenses: Money, today: CalendarDate = today
  ) -> BudgetView {
    let remaining = amount.value - expenses.value
    var daysLeft: Int?
    var leftPerDay: Money?
    if kind.hasLeftPerDay && start <= today && today <= end && remaining >= 0 {
      let days =
        CalendarDate.calendar.dateComponents([.day], from: today.utcDate, to: end.utcDate).day! + 1
      var share = remaining / Decimal(days)
      var rounded = Decimal()
      NSDecimalRound(&rounded, &share, 2, .down)
      daysLeft = days
      leftPerDay = Money(rounded)
    }
    return BudgetView(
      kind: kind, start: start, end: end, amount: amount, repeats: repeats, expenses: expenses,
      remaining: Money(remaining), overBudget: remaining < 0, daysLeft: daysLeft,
      leftPerDay: leftPerDay)
  }
  public static func summary(
    _ selection: PeriodSelection = .init(), entries: [JournalEntry] = entries,
    categories: [Category] = categories.all, budgets: [BudgetSpan] = budgets
  ) -> Summary {
    let date = selection.date ?? today
    let cal = CalendarDate.calendar
    let start: CalendarDate
    let end: CalendarDate
    switch selection.kind {
    case .day:
      start = date
      end = date
    case .week:
      let weekday = cal.component(.weekday, from: date.utcDate)
      start = date.adding(days: -((weekday + 5) % 7))
      end = start.adding(days: 6)
    case .month:
      start = try! CalendarDate(String(format: "%04d-%02d-01", date.year, date.month))
      end = CalendarDate(utcDate: cal.date(byAdding: .month, value: 1, to: start.utcDate)!).adding(
        days: -1)
    }
    let rows = entries.filter { start <= $0.date && $0.date <= end }.sorted { $0.date > $1.date }
    let income = rows.filter { $0.kind == .income }.reduce(Decimal.zero) { $0 + $1.amount.value }
    let expenses = rows.filter { $0.kind != .income }.reduce(Decimal.zero) {
      $0 + $1.signedAmount.value
    }
    let groups = Dictionary(
      grouping: rows.filter { $0.kind != .income }, by: { $0.categoryId ?? "uncategorized" })
    let breakdown = groups.values.map { rows in
      SpendingGroup(
        categoryId: rows[0].categoryId, category: rows[0].categoryName,
        amount: Money(rows.reduce(0) { $0 + $1.signedAmount.value }))
    }.sorted { $0.category < $1.category }
    let budget = storedBudget(selection.kind, start: start, in: budgets).map {
      budgetView(
        kind: selection.kind, start: start, end: end, amount: $0.amount, repeats: $0.repeats,
        expenses: Money(expenses))
    }
    return Summary(
      kind: selection.kind, date: date, start: start, end: end, today: today, currency: "MXN",
      income: Money(income), expenses: Money(expenses), netChange: Money(income - expenses),
      categories: categories.filter { $0.active != false }, entries: rows, breakdown: breakdown,
      budget: budget)
  }
  static func periodStart(_ kind: PeriodKind, containing date: CalendarDate) -> CalendarDate {
    summary(.init(kind: kind, date: date), entries: [], budgets: []).start
  }
  static func previousPeriodStart(_ kind: PeriodKind, before start: CalendarDate) -> CalendarDate {
    periodStart(kind, containing: start.adding(days: -1))
  }
  static func kindRank(_ kind: PeriodKind) -> Int { PeriodKind.allCases.firstIndex(of: kind)! }
  /// The budgets list as the server assembles it, from the in-memory spans.
  public static func budgetList(
    entries: [JournalEntry] = entries, categories: [Category] = categories.all,
    budgets: [BudgetSpan] = budgets, before: String? = nil
  ) -> BudgetList {
    func view(_ kind: PeriodKind, _ date: CalendarDate) -> BudgetView? {
      summary(.init(kind: kind, date: date), entries: entries, categories: categories, budgets: budgets)
        .budget
    }
    let current = Dictionary(
      uniqueKeysWithValues: PeriodKind.allCases.map { ($0, periodStart($0, containing: today)) })
    let repeating = budgets.filter { $0.repeats && ($0.until == nil || $0.until! >= current[$0.kind]!) }
      .sorted { kindRank($0.kind) != kindRank($1.kind) ? kindRank($0.kind) < kindRank($1.kind) : $0.start < $1.start }
      .map { RepeatingSpan(kind: $0.kind, start: $0.start, amount: $0.amount, until: $0.until) }
    let upcoming = budgets.filter { !$0.repeats && $0.start > today }
      .sorted { $0.start != $1.start ? $0.start < $1.start : kindRank($0.kind) < kindRank($1.kind) }
      .compactMap { view($0.kind, $0.start) }
    // ponytail: the fake walks 60 periods back per kind; the server pages the whole history.
    var past: [BudgetView] = []
    for kind in PeriodKind.allCases {
      var start = previousPeriodStart(kind, before: current[kind]!)
      for _ in 0..<60 {
        if let budget = view(kind, start) { past.append(budget) }
        start = previousPeriodStart(kind, before: start)
      }
    }
    past.sort { $0.end != $1.end ? $0.end > $1.end : kindRank($0.kind) < kindRank($1.kind) }
    if let before, let cursorEnd = try? CalendarDate(String(before.prefix(10))),
      let cursorKind = PeriodKind(rawValue: String(before.dropFirst(11)))
    {
      past.removeAll {
        $0.end > cursorEnd || ($0.end == cursorEnd && kindRank($0.kind) <= kindRank(cursorKind))
      }
    }
    let page = Array(past.prefix(20))
    return BudgetList(
      today: today, currency: "MXN",
      now: .init(day: view(.day, today), week: view(.week, today), month: view(.month, today)),
      repeating: repeating, upcoming: upcoming, past: page,
      nextBefore: past.count > page.count ? "\(page.last!.end)_\(page.last!.kind.rawValue)" : nil)
  }
  public static func trends(
    _ selection: PeriodSelection = .init(), entries: [JournalEntry] = entries
  ) -> Trends {
    let last = summary(selection, entries: entries)
    let length = selection.kind == .day ? 14 : 12
    var periods = [last]
    for _ in 1..<length {
      periods.insert(
        summary(
          .init(kind: selection.kind, date: periods[0].start.adding(days: -1)), entries: entries),
        at: 0)
    }
    let points = periods.map { s in
      TrendPoint(
        start: s.start, end: s.end, label: s.subtitle,
        tick: s.start.formatted(selection.kind == .month ? "MMM" : "MMM d"), income: s.income,
        expenses: s.expenses, netChange: s.netChange)
    }
    let income = points.reduce(Decimal.zero) { $0 + $1.income.value }
    let expense = points.reduce(Decimal.zero) { $0 + $1.expenses.value }
    let start = points[0].start
    let days =
      CalendarDate.calendar.dateComponents([.day], from: start.utcDate, to: last.end.utcDate).day!
      + 1
    return Trends(
      kind: selection.kind, date: last.date, start: start, end: last.end, today: today,
      currency: "MXN", length: length, points: points,
      previous: TrendRange(start: start.adding(days: -days), end: start.adding(days: -1)),
      income: Money(income), expenses: Money(expense), netChange: Money(income - expense),
      previousIncome: .zero, previousExpenses: .zero,
      categories: last.breakdown.map {
        TrendSpending(
          categoryId: $0.categoryId, category: $0.category, amount: $0.amount, previous: .zero)
      })
  }
  public static var pdf: Data {
    var document = "%PDF-1.4\n"
    let stream = "BT /F1 20 Tf 40 740 Td (Finance Buddy - Fixture snapshot) Tj ET"
    let objects = [
      "<< /Type /Catalog /Pages 2 0 R >>", "<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
      "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>",
      "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>",
      "<< /Length \(stream.utf8.count) >>\nstream\n\(stream)\nendstream",
    ]
    var offsets = [Int]()
    for (index, object) in objects.enumerated() {
      offsets.append(document.utf8.count)
      document += "\(index + 1) 0 obj\n\(object)\nendobj\n"
    }
    let xref = document.utf8.count
    document += "xref\n0 6\n0000000000 65535 f \n"
    for offset in offsets { document += String(format: "%010d 00000 n \n", offset) }
    document += "trailer\n<< /Size 6 /Root 1 0 R >>\nstartxref\n\(xref)\n%%EOF"
    return Data(document.utf8)
  }
}
