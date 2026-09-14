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
  public static func summary(
    _ selection: PeriodSelection = .init(), entries: [JournalEntry] = entries,
    categories: [Category] = categories.all
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
    return Summary(
      kind: selection.kind, date: date, start: start, end: end, today: today, currency: "MXN",
      income: Money(income), expenses: Money(expenses), netChange: Money(income - expenses),
      categories: categories.filter { $0.active != false }, entries: rows, breakdown: breakdown)
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
