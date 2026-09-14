import Accessibility
import Charts
import FinanceBuddyCore
import SwiftUI

struct FinanceChartDescriptor: AXChartDescriptorRepresentable {
  let title: String
  let summary: String
  let data: [ChartDatum]
  var horizontal = false
  func makeChartDescriptor() -> AXChartDescriptor {
    let keys = data.reduce(into: [String]()) { if !$0.contains($1.label) { $0.append($1.label) } }
    let names = data.reduce(into: [String]()) {
      if !$0.contains($1.series) { $0.append($1.series) }
    }
    let values = data.map(\.plotted)
    let axis = AXNumericDataAxisDescriptor(
      title: "Mexican pesos", range: min(0, values.min() ?? 0)...max(1, values.max() ?? 1),
      gridlinePositions: [0]
    ) { value in Money(Decimal(value)).formatted() }
    let series = names.map { name in
      AXDataSeriesDescriptor(
        name: name, isContinuous: false,
        dataPoints: data.filter { $0.series == name }.map {
          AXDataPoint(
            x: $0.label, y: $0.plotted, label: "\($0.label), \(name), \($0.money.formatted())")
        })
    }
    let descriptor = AXChartDescriptor(
      title: title, summary: summary,
      xAxis: AXCategoricalDataAxisDescriptor(title: "Period or category", categoryOrder: keys),
      yAxis: axis, series: series)
    descriptor.contentDirection = horizontal ? .topToBottom : .leftToRight
    return descriptor
  }
  func updateChartDescriptor(_ descriptor: AXChartDescriptor) {
    let updated = makeChartDescriptor()
    descriptor.title = updated.title
    descriptor.summary = updated.summary
    descriptor.xAxis = updated.xAxis
    descriptor.yAxis = updated.yAxis
    descriptor.series = updated.series
    descriptor.contentDirection = updated.contentDirection
  }
}
