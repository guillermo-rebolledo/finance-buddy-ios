import Foundation

/// In-memory server for previews and tests only. Its calendar arithmetic never runs in the live client.
@MainActor public final class FakeAPIClient: APIClient {
  public let access = AppAccess()
  public var signedIn = true
  public var entries: [JournalEntry] = Fixtures.entries
  public var managedCategories = Fixtures.categories
  public var summaryHandler: ((PeriodSelection) async throws -> Summary)?
  public var trendsHandler: ((PeriodSelection) async throws -> Trends)?
  public var transportError: URLError?
  public var failure: Refusal?
  public var entryRequests: [EntryRequest] = []
  public var categoryRequests: [CategoryRequest] = []
  public var exportRequests: [(PeriodSelection, String)] = []
  public var budgets = Fixtures.budgets
  public var budgetRequests: [(PeriodSelection, BudgetRequest)] = []
  public var removalRequests: [(PeriodSelection, BudgetRemovalScope)] = []
  public var requiresAppleAuthorization = false
  public var accountDeletionRequests: [String?] = []
  private var accountDeleted = false
  public init() {}
  public func session() async throws -> SessionReply? {
    if let failure { throw failure }
    return signedIn ? Fixtures.session : nil
  }
  public func signIn(provider: SignInProvider, idToken: String, nonce: String) async throws {
    if accountDeleted {
      managedCategories = CategoryLists(
        income: ["Salary", "Freelance", "Other income"].map {
          Category(id: UUID().uuidString, kind: .income, name: $0)
        },
        expense: ["Groceries", "Dining", "Transport", "Housing", "Utilities", "Health", "Shopping", "Entertainment"].map {
          Category(id: UUID().uuidString, kind: .expense, name: $0)
        })
      accountDeleted = false
    }
    signedIn = true
    access.signedOut = false
  }
  public func signOut(everywhere: Bool) async throws {
    if let transportError { throw transportError }
    try clearToken()
  }
  public func deleteAccount(appleAuthorizationCode: String?) async throws {
    accountDeletionRequests.append(appleAuthorizationCode)
    if access.offline { throw ClientError.offline }
    if let transportError { throw transportError }
    if let failure { throw failure }
    if requiresAppleAuthorization && appleAuthorizationCode?.isEmpty != false {
      throw Refusal(.appleAuthorizationRequired, message: "Confirm with Apple.")
    }
    entries.removeAll()
    managedCategories = CategoryLists(income: [], expense: [])
    budgets.removeAll()
    exportRequests.removeAll()
    accountDeleted = true
    try clearToken()
  }
  public func clearToken() throws {
    signedIn = false
    access.signedOut = true
    access.sessionGeneration += 1
  }
  public func summary(_ period: PeriodSelection) async throws -> Summary {
    if let summaryHandler { return try await summaryHandler(period) }
    if let transportError { throw transportError }
    if let failure { throw failure }
    return Fixtures.summary(
      period, entries: entries, categories: managedCategories.all, budgets: budgets)
  }
  public func trends(_ period: PeriodSelection) async throws -> Trends {
    if let trendsHandler { return try await trendsHandler(period) }
    if let transportError { throw transportError }
    if let failure { throw failure }
    return Fixtures.trends(period, entries: entries)
  }
  public func save(_ entry: EntryRequest, correcting: Bool) async throws -> BudgetView? {
    entryRequests.append(entry)
    if let transportError { throw transportError }
    if let failure { throw failure }
    entries.removeAll { $0.id == entry.id }
    entries.append(
      JournalEntry(
        id: entry.id, kind: entry.kind, amount: entry.amount, date: entry.date,
        categoryId: entry.categoryId,
        category: managedCategories.all.first { $0.id == entry.categoryId }?.name,
        note: entry.note, currency: "MXN"))
    guard entry.kind != .income else { return nil }
    return PeriodKind.allCases.lazy.compactMap { self.budget(.init(kind: $0, date: entry.date)) }
      .first
  }
  private func budget(_ period: PeriodSelection) -> BudgetView? {
    Fixtures.summary(period, entries: entries, categories: managedCategories.all, budgets: budgets)
      .budget
  }
  public func budgets(before: String?) async throws -> BudgetList {
    if let transportError { throw transportError }
    if let failure { throw failure }
    return Fixtures.budgetList(
      entries: entries, categories: managedCategories.all, budgets: budgets, before: before)
  }
  /// The named period's start, refusing one that has ended as the server does.
  private func changeablePeriod(_ period: PeriodSelection) throws -> CalendarDate {
    if let transportError { throw transportError }
    if let failure { throw failure }
    let resolved = Fixtures.summary(period, entries: [], budgets: [])
    guard resolved.end >= Fixtures.today else {
      throw Refusal(
        .periodEnded, message: "This period has ended, so its budget stays as it was.",
        status: 409)
    }
    return resolved.start
  }
  public func setBudget(_ period: PeriodSelection, _ request: BudgetRequest) async throws
    -> BudgetView?
  {
    budgetRequests.append((period, request))
    let start = try changeablePeriod(period)
    let kind = period.kind
    let previous = Fixtures.previousPeriodStart(kind, before: start)
    budgets.removeAll { $0.kind == kind && !$0.repeats && $0.start == start }
    if request.oneOff {
      budgets.append(
        .init(kind: kind, start: start, until: start, repeats: false, amount: request.amount))
    } else if let i = budgets.firstIndex(where: { $0.kind == kind && $0.repeats && $0.start == start })
    {
      budgets[i].amount = request.amount
    } else if let i = budgets.firstIndex(where: {
      $0.kind == kind && $0.repeats && $0.start < start && ($0.until == nil || $0.until! >= start)
    }) {
      let until = budgets[i].until
      budgets[i].until = previous
      budgets.append(
        .init(kind: kind, start: start, until: until, repeats: true, amount: request.amount))
    } else {
      let next = budgets.filter { $0.kind == kind && $0.repeats && $0.start > start }.map(\.start)
        .min()
      budgets.append(
        .init(
          kind: kind, start: start,
          until: next.map { Fixtures.previousPeriodStart(kind, before: $0) }, repeats: true,
          amount: request.amount))
    }
    return budget(period)
  }
  public func removeBudget(_ period: PeriodSelection, scope: BudgetRemovalScope) async throws
    -> BudgetView?
  {
    removalRequests.append((period, scope))
    let start = try changeablePeriod(period)
    let kind = period.kind
    switch scope {
    case .period: budgets.removeAll { $0.kind == kind && !$0.repeats && $0.start == start }
    case .onward:
      budgets.removeAll { $0.kind == kind && $0.repeats && $0.start >= start }
      let previous = Fixtures.previousPeriodStart(kind, before: start)
      for i in budgets.indices
      where budgets[i].kind == kind && budgets[i].repeats
        && (budgets[i].until == nil || budgets[i].until! >= start)
      {
        budgets[i].until = previous
      }
    }
    return budget(period)
  }
  public func delete(id: String) async throws {
    if let transportError { throw transportError }
    if let failure { throw failure }
    entries.removeAll { $0.id == id }
  }
  public func categories() async throws -> CategoryLists {
    if let transportError { throw transportError }
    if let failure { throw failure }
    return managedCategories
  }
  public func changeCategory(_ request: CategoryRequest) async throws {
    categoryRequests.append(request)
    if let transportError { throw transportError }
    if let failure { throw failure }
    var all = managedCategories.all
    if request.action == .create, let kind = request.kind, let name = request.name {
      if !all.contains(where: { $0.id == request.id }) {
        all.append(Category(id: request.id, kind: kind, name: name))
      }
    } else if let i = all.firstIndex(where: { $0.id == request.id }) {
      switch request.action {
      case .rename: all[i].name = request.name ?? all[i].name
      case .archive: all[i].active = false
      case .restore: all[i].active = true
      case .create: break
      }
    }
    managedCategories = CategoryLists(
      income: all.filter { $0.kind == .income }, expense: all.filter { $0.kind == .expense })
    entries = entries.map { e in
      JournalEntry(
        id: e.id, kind: e.kind, amount: e.amount, date: e.date, categoryId: e.categoryId,
        category: all.first { $0.id == e.categoryId }?.name, note: e.note, currency: e.currency)
    }
  }
  public func pdf(_ period: PeriodSelection) async throws -> PDFDocument {
    if let transportError { throw transportError }
    if let failure { throw failure }
    return PDFDocument(
      data: Fixtures.pdf,
      filename: "finance-buddy-week-2026-09-07-to-2026-09-13-exported-2026-09-13.pdf")
  }
  public func spreadsheet(_ period: PeriodSelection, id: String) async throws -> Spreadsheet {
    exportRequests.append((period, id))
    if let transportError { throw transportError }
    if let failure { throw failure }
    return Spreadsheet(
      url: URL(string: "https://docs.google.com/spreadsheets/")!, title: "Finance Buddy snapshot")
  }
}
