import FinanceBuddyCore
import SwiftUI

/// One budget's figures, the same wherever a budget is shown: what is left, how far over, or how
/// an ended period ended; left per day where it applies; then the budget and its total expenses.
struct BudgetFigures: View {
  let budget: BudgetView
  let today: CalendarDate
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(budget.standing(ended: budget.hasEnded(today)))
        .font(.title2.bold().monospacedDigit())
        .foregroundStyle(budget.overBudget ? Color.red : Color.primary)
        .contentTransition(.numericText())
      if let perDay = budget.leftPerDayText {
        VStack(alignment: .leading, spacing: 2) {
          Text(perDay.amount).font(.headline.monospacedDigit())
          Text(perDay.days).font(.caption).foregroundStyle(.secondary)
        }
      }
      LabeledContent("Budget") { Text(budget.amount.formatted()).monospacedDigit() }
      LabeledContent("Total expenses") { Text(budget.expenses.formatted()).monospacedDigit() }
    }
    .fixedSize(horizontal: false, vertical: true)
  }
}
