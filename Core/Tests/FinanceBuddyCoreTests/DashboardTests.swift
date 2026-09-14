import Testing

@testable import FinanceBuddyCore

@MainActor struct DashboardTests {
  @Test func summaryAndTrendsAreAcceptedTogetherOrNeither() async throws {
    let api = FakeAPIClient()
    let store = PeriodStore(client: api)
    await store.refresh(dashboard: true)
    let oldDate = store.summary?.date
    let oldTrend = store.trends?.date
    api.trendsHandler = { _ in throw Refusal(.unavailable, message: "Later") }
    store.select(.init(kind: .day, date: try CalendarDate("2026-09-10")))
    await store.refresh(dashboard: true)
    #expect(store.summary?.date == oldDate)
    #expect(store.trends?.date == oldTrend)
    api.trendsHandler = nil
    await store.refresh(dashboard: true)
    #expect(store.summary?.date == store.trends?.date)
    #expect(store.summary?.kind == .day)
  }
  @Test func mismatchingPeriodReplyIsNotDisplayed() async {
    let api = FakeAPIClient()
    let store = PeriodStore(client: api)
    api.trendsHandler = { _ in Fixtures.trends(.init(kind: .month)) }
    await store.refresh(dashboard: true)
    #expect(store.summary == nil)
    #expect(store.trends == nil)
    #expect(store.error != nil)
  }
}
