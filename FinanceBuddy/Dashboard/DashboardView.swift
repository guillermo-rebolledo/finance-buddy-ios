import FinanceBuddyCore
import SwiftUI

struct DashboardView: View {
  @Bindable var period: PeriodStore
  let client: any APIClient
  @State private var export: ExportStore
  @State private var showingExport = false
  init(period: PeriodStore, client: any APIClient) {
    self.period = period
    self.client = client
    _export = State(initialValue: ExportStore(client: client))
  }
  var body: some View {
    List {
      Section { PeriodPicker(store: period) }
      if period.showsPlaceholder {
        placeholder
      } else if let summary = period.summary, let trends = period.trends {
        Section {
          total("Total income", summary.income)
          total("Total expenses", summary.expenses)
          total("Net change", summary.netChange, showPlus: true)
        } header: {
          Text("Recorded activity for this period")
        }
        Section("Spending by category") {
          if summary.breakdown.isEmpty {
            Text("No expenses or refunds in this period.").foregroundStyle(.secondary)
          }
          ForEach(summary.breakdown) { group in total(group.category, group.amount) }
        }
        Section {
          Text("The last \(trends.kind.spanTitle)").font(.title2.bold())
          Text("\(trends.start.description) – \(trends.end.description)").font(.caption)
            .foregroundStyle(.secondary)
          if trends.points.allSatisfy({
            $0.income.value == 0 && $0.expenses.value == 0 && $0.netChange.value == 0
          }) {
            Text("Nothing recorded in these \(trends.kind.spanTitle)").foregroundStyle(.secondary)
          }
          TrendChart(
            title: "Income and expenses",
            summary:
              "Income of \(trends.income.formatted()) and expenses of \(trends.expenses.formatted()), compared with \(trends.previousIncome.formatted()) income and \(trends.previousExpenses.formatted()) expenses in the previous span.",
            data: incomeAndExpenses(trends))
          TrendChart(
            title: "Net change",
            summary:
              "Net change of \(trends.netChange.formatted(showPlus: true)) in recorded activity across this span.",
            data: trends.points.map {
              ChartDatum(
                id: $0.start.description, key: $0.start.description, tick: $0.tick, label: $0.label,
                series: "Net change", money: $0.netChange)
            })
          TrendChart(
            title: "Where the spending went",
            summary:
              "Current: \(trends.start) – \(trends.end). Previous: \(trends.previous.start) – \(trends.previous.end). Refunds reduce spending.",
            data: spending(trends), horizontal: true)
        }
      }
    }.listStyle(.insetGrouped).navigationTitle("Dashboard")
    .smoothChanges(
      period.showsPlaceholder
        ? nil
        : period.summary.map { [$0.income, $0.expenses, $0.netChange] + $0.breakdown.map(\.amount) }
    )
    .refreshable {
      await period.refresh(dashboard: true)
    }
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Menu("Export", systemImage: "square.and.arrow.up") {
          Button("Export PDF", systemImage: "doc.richtext") { startExport(.pdf) }
          Button(
            export.pending == nil ? "Export to Google Sheets" : "Retry Google Sheets Export",
            systemImage: "tablecells"
          ) { startExport(.sheets) }
        }.disabled(
          period.summary == nil || period.trends == nil || client.access.offline || export.busy)
      }
    }
    .sheet(isPresented: $showingExport, onDismiss: { export.cleanupPDF() }) {
      ExportView(store: export, offline: client.access.offline)
    }
  }
  /// Mirrors the loaded sections so figures replace placeholders without the list jumping.
  private var placeholder: some View {
    Group {
      Section {
        total("Total income", Money(10000))
        total("Total expenses", Money(10000))
        total("Net change", Money(10000))
      } header: {
        Text("Recorded activity for this period")
      }
      Section("Spending by category") {
        ForEach(["Groceries", "Dining", "Transport"], id: \.self) { total($0, Money(1000)) }
      }
      Section {
        Text("The last 12 weeks").font(.title2.bold())
        Text("0000-00-00 – 0000-00-00").font(.caption)
        ForEach(["Income and expenses", "Net change", "Where the spending went"], id: \.self) {
          title in
          VStack(alignment: .leading, spacing: 16) {
            Text(title).font(.headline)
            Text("Placeholder summary describing the figures across this span of time.")
              .font(.subheadline)
            RoundedRectangle(cornerRadius: 8).fill(.quaternary).frame(height: 240)
            Text("Show as table")
          }.padding(.vertical, 8)
        }
      }
    }.redacted(reason: .placeholder).accessibilityHidden(true)
  }
  private func startExport(_ kind: ExportStore.Kind) {
    guard let summary = period.summary else { return }
    showingExport = true
    Task { await export.begin(kind, summary: summary) }
  }
  private func total(_ label: String, _ money: Money, showPlus: Bool = false) -> some View {
    LabeledContent {
      Text(money.formatted(showPlus: showPlus)).font(.headline.monospacedDigit()).foregroundStyle(
        .primary
      ).contentTransition(.numericText())
    } label: {
      Text(label)
    }.padding(.vertical, 3)
  }
  private func incomeAndExpenses(_ trends: Trends) -> [ChartDatum] {
    trends.points.flatMap { point in
      [
        ChartDatum(
          id: point.start.description + "income", key: point.start.description, tick: point.tick,
          label: point.label, series: "Income", money: point.income),
        ChartDatum(
          id: point.start.description + "expenses", key: point.start.description, tick: point.tick,
          label: point.label, series: "Expenses", money: point.expenses),
      ]
    }
  }
  private func spending(_ trends: Trends) -> [ChartDatum] {
    trends.categories.flatMap { group in
      [
        ChartDatum(
          id: group.id + "current", key: group.category, tick: group.category,
          label: group.category, series: "Current", money: group.amount),
        ChartDatum(
          id: group.id + "previous", key: group.category, tick: group.category,
          label: group.category, series: "Previous", money: group.previous),
      ]
    }
  }
}
