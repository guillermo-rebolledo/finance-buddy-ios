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
  public init() {}
  public func session() async throws -> SessionReply? {
    if let failure { throw failure }
    return signedIn ? Fixtures.session : nil
  }
  public func signIn(idToken: String, nonce: String) async throws {
    signedIn = true
    access.signedOut = false
  }
  public func signOut(everywhere: Bool) async throws {
    if let transportError { throw transportError }
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
    return Fixtures.summary(period, entries: entries, categories: managedCategories.all)
  }
  public func trends(_ period: PeriodSelection) async throws -> Trends {
    if let trendsHandler { return try await trendsHandler(period) }
    if let transportError { throw transportError }
    if let failure { throw failure }
    return Fixtures.trends(period, entries: entries)
  }
  public func save(_ entry: EntryRequest, correcting: Bool) async throws {
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
