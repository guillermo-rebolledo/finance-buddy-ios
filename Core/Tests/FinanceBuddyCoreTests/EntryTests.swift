import Foundation
import Testing

@testable import FinanceBuddyCore

@MainActor struct EntryTests {
  @Test func uncertainRetryKeepsExactIdentityAndPayload() async {
    let api = FakeAPIClient()
    let store = EntryEditorStore(
      client: api, today: Fixtures.today, categories: Fixtures.categories.all)
    store.amount = "20"
    store.note = "A note"
    api.failure = Refusal(.notConfirmed, message: "Unknown", status: 503)
    await store.save()
    let first = api.entryRequests[0]
    #expect(store.locked)
    store.note = "Even programmatic edits cannot change a retry"
    await store.save()
    #expect(api.entryRequests.count == 2)
    #expect(api.entryRequests[1] == first)
    api.failure = nil
    await store.save()
    #expect(store.saved)
    #expect(api.entries.filter { $0.id == first.id }.count == 1)
  }
  @Test func definite400UnlocksAndUsesNewIdentity() async {
    let api = FakeAPIClient()
    let store = EntryEditorStore(client: api, today: Fixtures.today, categories: [])
    store.amount = "20"
    api.failure = Refusal(.invalidField, message: "Fix note", field: "note", status: 400)
    await store.save()
    #expect(store.locked == false)
    #expect(store.field == "note")
    let first = api.entryRequests[0].id
    store.note = "Fixed"
    api.failure = nil
    await store.save()
    #expect(api.entryRequests[1].id != first)
  }
  @Test func archivedCategoryRetainedOnlyInOriginalList() {
    let api = FakeAPIClient()
    let entry = Fixtures.entries[3]
    let store = EntryEditorStore(
      client: api, today: Fixtures.today, categories: Fixtures.categories.all, entry: entry)
    #expect(store.choices.contains { $0.id == entry.categoryId && $0.active == false })
    store.kind = .refund
    store.updateKind()
    #expect(store.categoryId == entry.categoryId)
    store.kind = .income
    store.updateKind()
    #expect(store.categoryId == nil)
    let new = EntryEditorStore(
      client: api, today: Fixtures.today, categories: Fixtures.categories.all)
    #expect(new.choices.contains { $0.active == false } == false)
  }
  @Test(arguments: ["0", "-1", "1.234", "1000000000000", "1e3", "1,000"])
  func invalidAmountsAreRefused(amount: String) {
    let store = EntryEditorStore(client: FakeAPIClient(), today: Fixtures.today, categories: [])
    store.amount = amount
    #expect(store.validate() == false)
    #expect(store.field == "amount")
  }
  @Test func validationUsesServerTodayAndUTF16Limits() {
    let store = EntryEditorStore(client: FakeAPIClient(), today: Fixtures.today, categories: [])
    store.amount = "1.25"
    store.date = Fixtures.today.adding(days: 1)
    #expect(store.validate() == false)
    #expect(store.field == "date")
    store.date = Fixtures.today
    store.note = String(repeating: "😀", count: 1001)
    #expect(store.validate() == false)
    #expect(store.field == "note")
  }
  @Test func deletionKeepsConfirmationOnRefusal() async {
    let api = FakeAPIClient()
    let store = DeletionStore(entry: Fixtures.entries[0], client: api)
    api.failure = Refusal(.notConfirmed, message: "Retry", status: 503)
    await store.delete()
    #expect(store.deleted == false)
    #expect(store.error == "Retry")
    api.failure = nil
    await store.delete()
    #expect(store.deleted)
  }
}
