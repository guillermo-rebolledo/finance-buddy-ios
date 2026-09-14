import Accessibility
import Charts
import FinanceBuddyCore
import SwiftUI

struct TrendChart: View {
  let title: String
  let summary: String
  let data: [ChartDatum]
  var horizontal = false
  @State private var selection: String?
  @State private var showTable = false
  @Environment(\.dynamicTypeSize) private var typeSize
  @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
  private var keys: [String] {
    data.reduce(into: []) { if !$0.contains($1.key) { $0.append($1.key) } }
  }
  private var axisKeys: [String] {
    guard keys.count > 3 else { return keys }
    if typeSize.isAccessibilitySize { return [keys[keys.count / 2]] }
    return [keys[0], keys[keys.count / 2], keys[keys.count - 1]]
  }
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text(title).font(.headline).accessibilityAddTraits(.isHeader)
      Text(summary).font(.subheadline).foregroundStyle(.secondary)
      if horizontal { horizontalChart } else { verticalChart }
      if let selection, let point = data.first(where: { $0.key == selection }) {
        VStack(alignment: .leading) {
          Text(point.label).font(.caption.bold())
          ForEach(data.filter { $0.key == selection }) {
            Text("\($0.series): \($0.money.formatted())").font(.caption).monospacedDigit()
          }
        }
      }
      DisclosureGroup("Show as table", isExpanded: $showTable) {
        ForEach(keys, id: \.self) { key in
          VStack(alignment: .leading, spacing: 6) {
            Text(data.first { $0.key == key }?.label ?? key).font(.subheadline.bold())
            ForEach(data.filter { $0.key == key }) { row in
              LabeledContent(row.series, value: row.money.formatted()).font(.subheadline)
                .monospacedDigit()
            }
          }.padding(.vertical, 6).accessibilityElement(children: .combine)
        }
      }.accessibilityLabel("Show \(title) as table")
    }.padding(.vertical, 8).onAppear {
      showTable = differentiateWithoutColor || typeSize.isAccessibilitySize
    }
  }
  private var verticalChart: some View {
    Chart {
      ForEach(data) { item in
        BarMark(x: .value("Period", item.key), y: .value("MXN", item.plotted))
          .foregroundStyle(by: .value("Series", item.series)).position(
            by: .value("Series", item.series)
          )
          .accessibilityLabel("\(item.label), \(item.series)").accessibilityValue(
            item.money.formatted())
      }
      RuleMark(y: .value("Zero", 0)).foregroundStyle(.secondary.opacity(0.4)).accessibilityHidden(
        true)
    }
    .chartForegroundStyleScale(range: [Color.blue, Color.orange])
    .chartXAxis {
      AxisMarks(values: axisKeys) { value in
        AxisValueLabel {
          if let key = value.as(String.self) {
            Text(data.first { $0.key == key }?.tick ?? "").font(.caption)
          }
        }
      }
    }
    .chartXSelection(value: $selection)
    .frame(height: 240)
    .accessibilityChartDescriptor(
      FinanceChartDescriptor(title: title, summary: summary, data: data))
  }
  private var horizontalChart: some View {
    Chart {
      ForEach(data) { item in
        BarMark(x: .value("MXN", item.plotted), y: .value("Category", item.key))
          .foregroundStyle(by: .value("Span", item.series)).position(
            by: .value("Span", item.series)
          )
          .accessibilityLabel("\(item.label), \(item.series)").accessibilityValue(
            item.money.formatted())
      }
      RuleMark(x: .value("Zero", 0)).foregroundStyle(.secondary.opacity(0.4)).accessibilityHidden(
        true)
    }
    .chartForegroundStyleScale(range: [Color.blue, Color.gray])
    .chartYSelection(value: $selection)
    .frame(height: max(180, CGFloat(keys.count) * 66))
    .accessibilityChartDescriptor(
      FinanceChartDescriptor(title: title, summary: summary, data: data, horizontal: true))
  }
}
