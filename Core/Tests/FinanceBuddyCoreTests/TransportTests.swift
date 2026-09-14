import Foundation
import Testing

@testable import FinanceBuddyCore

@MainActor struct TransportTests {
  @Test func entryTransportRetryKeepsExactBody() async {
    let api = FakeAPIClient()
    api.transportError = URLError(.networkConnectionLost)
    let store = EntryEditorStore(client: api, today: Fixtures.today, categories: [])
    store.amount = "999999999999.99"
    await store.save()
    #expect(store.locked)
    let first = api.entryRequests[0]
    api.transportError = nil
    await store.save()
    #expect(api.entryRequests[1] == first)
    #expect(store.saved)
  }
  @Test func categoryAndSheetsTransportRetriesKeepIDs() async {
    let api = FakeAPIClient()
    api.transportError = URLError(.timedOut)
    let category = CategoryEditorStore(client: api, kind: .income, all: [])
    category.name = "Gift"
    await category.save()
    let firstCategory = api.categoryRequests[0]
    let export = ExportStore(client: api)
    await export.begin(.sheets, summary: Fixtures.summary())
    let firstExport = api.exportRequests[0]
    api.transportError = nil
    await category.save()
    await export.retry()
    #expect(api.categoryRequests[1] == firstCategory)
    #expect(api.exportRequests[1].1 == firstExport.1)
    #expect(api.exportRequests[1].0 == firstExport.0)
  }
  @Test func signOutClearsLocalSessionEvenWhenRequestFails() async {
    let api = FakeAPIClient()
    let store = SessionStore(client: api)
    await store.restore()
    api.transportError = URLError(.timedOut)
    await store.signOut(everywhere: true)
    #expect(store.state == .signedOut)
    #expect(api.signedIn == false)
    #expect(store.message?.contains("could not be confirmed") == true)
  }
  @Test func offlineWritesAreDisabledButLoadedDataIsRetained() async {
    let api = FakeAPIClient()
    let period = PeriodStore(client: api)
    await period.refresh(dashboard: true)
    api.access.offline = true
    let editor = EntryEditorStore(client: api, today: Fixtures.today, categories: [])
    editor.amount = "20"
    await editor.save()
    #expect(api.entryRequests.isEmpty)
    #expect(period.summary?.entries.count == 4)
  }
  @Test func moneyFormatsLargeTotalsWithoutRounding() throws {
    let money = try Money(string: "999999999999999999999.99")
    #expect(money.wire == "999999999999999999999.99")
    #expect(money.formatted() == "MXN 999,999,999,999,999,999,999.99")
  }
}
