import Testing

@testable import FinanceBuddyCore

@MainActor struct CategoryTests {
  @Test func creationKeepsUUIDAcrossUncertainRepliesAndRenewsAfter400() async {
    let api = FakeAPIClient()
    let store = CategoryEditorStore(client: api, kind: .income, all: [])
    store.name = "Gifts"
    api.failure = Refusal(.notConfirmed, message: "Retry", status: 503)
    await store.save()
    let first = api.categoryRequests[0]
    store.name = "Programmatic change"
    await store.save()
    #expect(api.categoryRequests[1] == first)
    api.failure = Refusal(.invalidField, message: "Fix name", field: "name", status: 400)
    await store.save()
    #expect(store.pending == nil)
    #expect(store.name == "Programmatic change")
    api.failure = nil
    await store.save()
    #expect(api.categoryRequests[3].id != first.id)
    #expect(store.saved)
  }
  @Test func archivedDuplicateIsRejectedAndTypedNameIsKept() async {
    let store = CategoryEditorStore(
      client: FakeAPIClient(), kind: .expense, all: Fixtures.categories.all)
    store.name = "  TRAVEL  "
    await store.save()
    #expect(store.error?.contains("Rename or restore") == true)
    #expect(store.name == "  TRAVEL  ")
  }
  @Test(arguments: ["", "\n", "Bad\nName", "Invisible\u{200B}", String(repeating: "x", count: 41)])
  func invalidCategoryNames(name: String) async {
    let store = CategoryEditorStore(client: FakeAPIClient(), kind: .income, all: [])
    store.name = name
    await store.save()
    #expect(store.saved == false)
    #expect(store.error != nil)
  }
  @Test func archivePreservesEntriesAndTotals() async {
    let api = FakeAPIClient()
    let before = try! await api.summary(.init())
    let store = CategoriesStore(client: api)
    await store.change(CategoryRequest(action: .archive, id: Fixtures.categories.expense[0].id))
    let after = try! await api.summary(.init())
    #expect(before.expenses == after.expenses)
    #expect(before.entries.count == after.entries.count)
    #expect(store.lists?.expense[0].active == false)
  }
}
