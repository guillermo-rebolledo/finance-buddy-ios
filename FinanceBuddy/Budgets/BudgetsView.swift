import FinanceBuddyCore
import SwiftUI

struct BudgetsView: View {
  let client: any APIClient
  let onChanged: () -> Void
  @State private var store: BudgetsStore
  @State private var editor: BudgetEditorStore?
  @State private var stopping: RepeatingSpan?
  @State private var notification: ToastMessage?
  init(client: any APIClient, onChanged: @escaping () -> Void, store: BudgetsStore? = nil) {
    self.client = client
    self.onChanged = onChanged
    _store = State(initialValue: store ?? BudgetsStore(client: client))
  }
  private var offline: Bool { client.access.offline }
  var body: some View {
    List {
      if let list = store.list {
        if list.isEmpty {
          emptyState(list)
        } else {
          nowSection(list)
          if !list.repeating.isEmpty { repeatingSection(list) }
          if !list.upcoming.isEmpty { upcomingSection(list) }
          if !list.past.isEmpty { pastSection(list) }
        }
      } else if store.loading {
        nowSection(Fixtures.budgetList())
          .redacted(reason: .placeholder).disabled(true).accessibilityHidden(true)
      }
    }.listStyle(.insetGrouped).navigationTitle("Budgets")
      .smoothChanges(store.list == nil)
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          Button("Set budget", systemImage: "plus") { open(.week, today) }
            .disabled(store.list == nil || offline).accessibilityIdentifier("setBudget")
        }
      }
      .task { await store.load(); showResult(includeSuccess: false) }
      .refreshable { await store.load(); showResult(includeSuccess: false) }
      .sheet(item: $editor) { model in
        BudgetEditorView(store: model, offline: offline) { message in
          notification = ToastMessage(text: message)
          Task {
            await store.load()
            onChanged()
          }
        }
      }
      .confirmationDialog(
        "Stop the repeating \(stopping?.kind.rawValue ?? "") budget?",
        isPresented: Binding(get: { stopping != nil }, set: { if !$0 { stopping = nil } }),
        titleVisibility: .visible, presenting: stopping
      ) { span in
        Button("Stop Budget", role: .destructive) {
          Task {
            if await store.stop(span) { onChanged() }
            showResult()
          }
        }
        Button("Keep Budget", role: .cancel) {}
      } message: { span in
        Text(
          "No \(span.kind.rawValue) budget repeats from \(store.fromText(span)) on, and every change scheduled after it goes too. Ended \(span.kind.rawValue)s keep the budgets they had, and one-off budgets stay."
        )
      }
      .toast($notification)
      .sensoryFeedback(.success, trigger: store.changeCount)
  }
  private var today: CalendarDate { store.list?.today ?? Fixtures.today }
  private func nowSection(_ list: BudgetList) -> some View {
    Section {
      ForEach(PeriodKind.allCases, id: \.self) { kind in
        let budget = list.now[kind]
        VStack(alignment: .leading, spacing: 8) {
          HStack(alignment: .firstTextBaseline) {
            Text(kind.currentTitle).font(.headline)
            Spacer()
            if let budget { sourceBadge(budget) }
          }
          Text(budget?.label(today: list.today) ?? "No budget for this \(kind.rawValue).")
            .font(.subheadline).foregroundStyle(.secondary)
          if let budget { BudgetFigures(budget: budget, today: list.today) }
          Button(budget == nil ? "Set budget" : "Change") { open(kind, list.today) }
            .accessibilityLabel(budget == nil ? "Set \(kind.rawValue) budget" : "Change \(kind.rawValue) budget")
            .accessibilityIdentifier("budget-\(kind.rawValue)")
        }.padding(.vertical, 4)
      }
    } header: {
      Text("Now")
    } footer: {
      Text("Today, this week, and this month in Mexico City.")
    }
    .buttonStyle(.bordered)
    .disabled(store.busy || offline)
  }
  private func repeatingSection(_ list: BudgetList) -> some View {
    Section {
      ForEach(list.repeating) { span in
        VStack(alignment: .leading, spacing: 8) {
          Text("\(span.amount.formatted()) every \(span.kind.rawValue)")
            .font(.headline.monospacedDigit())
          Text(span.label(today: list.today)).font(.subheadline).foregroundStyle(.secondary)
          HStack {
            Button("Change") { open(span.kind, store.from(span)) }
              .accessibilityLabel("Change \(span.kind.rawValue) budget from \(store.fromText(span))")
            Button("Stop") { stopping = span }
              .accessibilityLabel("Stop \(span.kind.rawValue) budget from \(store.fromText(span))")
          }
        }.padding(.vertical, 4)
      }
    } header: {
      Text("Repeating")
    } footer: {
      Text("Budgets that apply to every period of their kind, with the changes scheduled ahead.")
    }
    .buttonStyle(.bordered)
    .disabled(store.busy || offline)
  }
  private func upcomingSection(_ list: BudgetList) -> some View {
    Section {
      ForEach(list.upcoming) { budget in
        VStack(alignment: .leading, spacing: 8) {
          Text(budget.label(today: list.today)).font(.headline)
          Text(budget.amount.formatted()).font(.subheadline.monospacedDigit())
            .foregroundStyle(.secondary)
          HStack {
            Button("Change") { open(budget.kind, budget.start) }
              .accessibilityLabel("Change one-off budget for \(budget.label(today: list.today))")
            Button("Remove") {
              Task {
                if await store.removeOneOff(kind: budget.kind, date: budget.start) { onChanged() }
                showResult()
              }
            }
            .accessibilityLabel("Remove one-off budget for \(budget.label(today: list.today))")
          }
        }.padding(.vertical, 4)
      }
    } header: {
      Text("Upcoming one-offs")
    } footer: {
      Text("Budgets set for a single future period, in place of any repeating budget.")
    }
    .buttonStyle(.bordered)
    .disabled(store.busy || offline)
  }
  private func pastSection(_ list: BudgetList) -> some View {
    Section {
      ForEach(list.past) { budget in
        VStack(alignment: .leading, spacing: 4) {
          HStack(alignment: .firstTextBaseline) {
            Text(budget.label(today: list.today)).font(.headline)
            Spacer()
            sourceBadge(budget)
          }
          Text("Budget \(budget.amount.formatted()) · Total expenses \(budget.expenses.formatted())")
            .font(.subheadline.monospacedDigit()).foregroundStyle(.secondary)
          Text(budget.standing(ended: true)).font(.headline.monospacedDigit())
            .foregroundStyle(budget.overBudget ? Color.red : Color.primary)
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
      }
      if list.nextBefore != nil {
        Button(store.loadingMore ? "Loading…" : "Show more") { Task { await store.showMore(); showResult() } }
          .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
          .disabled(store.loadingMore)
      }
    } header: {
      Text("Past")
    } footer: {
      Text("Ended periods that had a budget, newest first.")
    }
  }
  private func emptyState(_ list: BudgetList) -> some View {
    Section {
      ContentUnavailableView {
        Label("No budgets yet", systemImage: "wallet.pass")
      } description: {
        Text(
          "A budget is the most you intend to spend in a day, week, or month. It is measured against that period’s total expenses, so refunds give room back and income never adds to it. It repeats every period until you change it, unless you set it for one period only."
        )
      } actions: {
        Button("Set your first budget") { open(.week, list.today) }
          .buttonStyle(.borderedProminent).disabled(offline)
          .accessibilityIdentifier("firstBudget")
      }
    }
  }
  private func sourceBadge(_ budget: BudgetView) -> some View {
    Text(budget.source).font(.caption.weight(.medium)).padding(.horizontal, 8)
      .padding(.vertical, 3).background(.quaternary, in: Capsule())
  }
  private func open(_ kind: PeriodKind, _ date: CalendarDate) {
    editor = BudgetEditorStore(client: client, kind: kind, date: date)
  }
  private func showResult(includeSuccess: Bool = true) {
    if let error = store.error {
      notification = ToastMessage(text: error, isError: true, actionTitle: "Retry") {
        Task {
          await store.retry()
          showResult()
        }
      }
    } else if includeSuccess, let confirmation = store.confirmation {
      notification = ToastMessage(text: confirmation)
    }
  }
}
