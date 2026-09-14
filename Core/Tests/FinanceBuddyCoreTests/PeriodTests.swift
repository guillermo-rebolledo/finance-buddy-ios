import Testing

@testable import FinanceBuddyCore

@MainActor struct PeriodTests {
  @Test func staleRepliesDoNotReplaceNewSelection() async throws {
    let api = FakeAPIClient()
    let store = PeriodStore(client: api)
    var first: CheckedContinuation<Summary, Never>?
    api.summaryHandler = { selection in
      if selection.date == nil { return await withCheckedContinuation { first = $0 } }
      return Fixtures.summary(selection)
    }
    let old = Task { await store.refresh() }
    while first == nil { await Task.yield() }
    let date = try CalendarDate("2026-08-01")
    store.select(.init(kind: .month, date: date))
    await store.refresh()
    first?.resume(returning: Fixtures.summary())
    await old.value
    #expect(store.summary?.date == date)
    #expect(store.summary?.kind == .month)
  }
  @Test func failedLoadKeepsLoadedPeriod() async {
    let api = FakeAPIClient()
    let store = PeriodStore(client: api)
    await store.refresh()
    let start = store.summary?.start
    api.failure = Refusal(.unavailable, message: "Later")
    store.previous()
    await store.refresh()
    #expect(store.summary?.start == start)
    #expect(store.failureMessage?.contains("still describe This week") == true)
  }
  @Test func placeholderCoversFirstLoadAndPeriodSwitchOnly() async {
    let api = FakeAPIClient()
    let store = PeriodStore(client: api)
    #expect(store.showsPlaceholder)
    await store.refresh(dashboard: true)
    #expect(!store.showsPlaceholder)
    var pending: CheckedContinuation<Summary, Never>?
    api.summaryHandler = { selection in await withCheckedContinuation { pending = $0 } }
    let sameRefresh = Task { await store.refresh() }
    while pending == nil { await Task.yield() }
    #expect(store.loading && !store.showsPlaceholder)
    pending?.resume(returning: Fixtures.summary())
    await sameRefresh.value
    api.summaryHandler = nil
    store.previous()
    #expect(store.showsPlaceholder)
    await store.refresh(dashboard: true)
    #expect(!store.showsPlaceholder)
  }
}
