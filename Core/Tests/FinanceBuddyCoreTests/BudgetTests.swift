import Foundation
import Testing

@testable import FinanceBuddyCore

@MainActor struct BudgetTests {
  @Test func summaryDecodesWithOrWithoutBudget() throws {
    let base = try JSONSerialization.jsonObject(
      with: JSONEncoder().encode(Fixtures.summary())) as! [String: Any]
    var without = base
    without.removeValue(forKey: "budget")
    let older = try JSONDecoder().decode(
      Summary.self, from: JSONSerialization.data(withJSONObject: without))
    #expect(older.budget == nil)
    var explicit = base
    explicit["budget"] = NSNull()
    #expect(
      try JSONDecoder().decode(
        Summary.self, from: JSONSerialization.data(withJSONObject: explicit)
      ).budget == nil)
    let view = try JSONDecoder().decode(
      BudgetView.self,
      from: Data(
        #"{"kind":"week","start":"2026-09-07","end":"2026-09-13","amount":"2000.00","repeats":true,"expenses":"1530.00","remaining":"470.00","overBudget":false,"daysLeft":1,"leftPerDay":"470.00"}"#
          .utf8))
    #expect(view.amount == Money(2000))
    #expect(view.leftPerDay == Money(470))
    #expect(view.daysLeft == 1)
  }
  @Test func figuresReadAsTheWebDoes() throws {
    let today = Fixtures.today
    let week = Fixtures.summary().budget!
    #expect(week.standing() == "MXN 470.00 left")
    #expect(week.line(today: today) == "MXN 470.00 left this week")
    #expect(week.leftPerDayText?.amount == "MXN 470.00 left per day")
    #expect(week.leftPerDayText?.days == "Today is the last day")
    #expect(week.label(today: today) == "Week of 7–13 Sep")
    let over = Fixtures.budgetView(
      kind: .week, start: try CalendarDate("2026-08-31"), end: try CalendarDate("2026-09-06"),
      amount: Money(100), repeats: true, expenses: Money(400))
    #expect(over.overBudget)
    #expect(over.standing(ended: true) == "Over by MXN 300.00")
    #expect(over.line(today: today) == "Over by MXN 300.00 for the week of 31 Aug – 6 Sep")
    #expect(over.leftPerDayText == nil)
    let exact = Fixtures.budgetView(
      kind: .day, start: today, end: today, amount: Money(50), repeats: false, expenses: Money(50))
    #expect(!exact.overBudget)
    #expect(exact.standing() == "MXN 0.00 left")
    #expect(exact.daysLeft == nil)
    #expect(exact.label(today: today) == "Sunday 13 Sep")
    #expect(exact.line(today: today) == "MXN 0.00 left today")
    let ended = Fixtures.budgetView(
      kind: .month, start: try CalendarDate("2025-08-01"), end: try CalendarDate("2025-08-31"),
      amount: Money(1000), repeats: true, expenses: Money(400))
    #expect(ended.standing(ended: true) == "Under by MXN 600.00")
    #expect(ended.label(today: today) == "August 2025")
    #expect(PeriodKind.week.spanStartName(try CalendarDate("2025-09-01"), today: today) == "the week of 1 Sep 2025")
    let perDay = Fixtures.budgetView(
      kind: .month, start: try CalendarDate("2026-09-01"), end: try CalendarDate("2026-09-30"),
      amount: Money(1000), repeats: true, expenses: Money(0))
    #expect(perDay.daysLeft == 18)
    #expect(perDay.leftPerDay == Money(Decimal(string: "55.55")!))
  }
  @Test func editorPrefillsTheResolvedPeriodAndSavesExactlyIt() async throws {
    let api = FakeAPIClient()
    let store = BudgetEditorStore(client: api, kind: .week, date: Fixtures.today)
    await store.resolve()
    #expect(store.amount == "2000.00")
    #expect(store.oneOff == false)
    #expect(store.period?.kind == .week)
    await store.choose(kind: .week, date: try CalendarDate("2026-09-23"))
    #expect(store.amount == "5000.00")
    #expect(store.oneOff)
    #expect(store.canRemoveOneOff)
    store.amount = "5500"
    await store.save()
    #expect(store.saved)
    #expect(api.budgetRequests.last?.0 == PeriodSelection(kind: .week, date: try CalendarDate("2026-09-23")))
    #expect(api.budgetRequests.last?.1 == BudgetRequest(amount: Money(5500), oneOff: true))
    #expect(store.confirmation == "One-off budget of MXN 5,500.00 saved for the week of 21–27 Sep.")
  }
  @Test(arguments: ["-1", "1.234", "1000000000000", "", "1,000"])
  func invalidAmountsAreRefusedAndZeroIsAllowed(amount: String) {
    let store = BudgetEditorStore(client: FakeAPIClient(), kind: .day, date: Fixtures.today)
    store.amount = amount
    #expect(store.validate() == false)
    #expect(store.field == "amount")
    store.amount = "0"
    #expect(store.validate())
  }
  @Test func endedPeriodsAreReadOnly() async throws {
    let api = FakeAPIClient()
    let store = BudgetEditorStore(client: api, kind: .day, date: Fixtures.today.adding(days: -1))
    await store.resolve()
    #expect(store.ended)
    #expect(!store.canSave)
    await store.save()
    #expect(api.budgetRequests.isEmpty)
    let list = BudgetsStore(client: api)
    await list.load()
    api.failure = Refusal(.periodEnded, message: "This period has ended.", status: 409)
    #expect(await list.removeOneOff(kind: .week, date: Fixtures.today) == false)
    #expect(list.error == "This period has ended.")
  }
  @Test func repeatingBudgetSavedFromTodayAppliesNowAndPromotesAOneOff() async throws {
    let api = FakeAPIClient()
    let store = BudgetEditorStore(client: api, kind: .month, date: Fixtures.today)
    await store.resolve()
    #expect(store.amount == "")
    store.amount = "8000"
    await store.save()
    #expect(store.confirmation == "Budget of MXN 8,000.00 saved for every month from 1 Sep.")
    #expect(try await api.summary(.init(kind: .month)).budget?.remaining == Money(6470))
    let promote = BudgetEditorStore(client: api, kind: .week, date: try CalendarDate("2026-09-21"))
    await promote.resolve()
    promote.oneOff = false
    await promote.save()
    let list = try await api.budgets(before: nil)
    #expect(list.upcoming.isEmpty)
    #expect(list.repeating.map(\.amount) == [Money(2000), Money(5000), Money(8000)])
    #expect(list.repeating[0].until == (try CalendarDate("2026-09-14")))
  }
  @Test func listStopsSpansAndPagesPast() async throws {
    let api = FakeAPIClient()
    api.budgets = [
      .init(kind: .day, start: try CalendarDate("2026-08-01"), until: nil, repeats: true, amount: Money(100))
    ]
    let store = BudgetsStore(client: api)
    await store.load()
    #expect(store.list?.now.day?.amount == Money(100))
    #expect(store.list?.past.count == 20)
    #expect(store.list?.past.first?.start == Fixtures.today.adding(days: -1))
    #expect(store.list?.nextBefore == "2026-08-24_day")
    await store.showMore()
    #expect(store.list?.past.count == 40)
    #expect(Set(store.list!.past.map(\.id)).count == 40)
    await store.showMore()
    #expect(store.list?.past.count == 43)
    #expect(store.list?.nextBefore == nil)
    let span = store.list!.repeating[0]
    #expect(store.fromText(span) == "today")
    #expect(await store.stop(span))
    #expect(store.confirmation == "Day budget stopped from today.")
    #expect(api.removalRequests.last?.0 == PeriodSelection(kind: .day, date: Fixtures.today))
    #expect(store.list?.now.day == nil)
    #expect(store.list?.repeating.isEmpty == true)
    #expect(store.list?.past.count == 20)
  }
  @Test func savingAnEntryCarriesTheShortestBudgetedPeriod() async throws {
    let api = FakeAPIClient()
    let store = EntryEditorStore(
      client: api, today: Fixtures.today, categories: Fixtures.categories.all)
    store.amount = "42.50"
    await store.save()
    #expect(store.savedBudget?.kind == .week)
    #expect(store.savedBudget?.line(today: Fixtures.today) == "MXN 427.50 left this week")
    let income = EntryEditorStore(
      client: api, today: Fixtures.today, categories: Fixtures.categories.all)
    income.kind = .income
    income.amount = "10"
    await income.save()
    #expect(income.saved)
    #expect(income.savedBudget == nil)
  }
}
