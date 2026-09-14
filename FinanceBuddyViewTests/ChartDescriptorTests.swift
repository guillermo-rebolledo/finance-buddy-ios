import Accessibility
import AppIntents
import FinanceBuddyCore
import Testing

@MainActor struct ChartDescriptorTests {
  @Test func audioGraphUpdatesWhenTheLoadedPeriodChanges() {
    let old = datum(label: "Previous week", money: Money(100))
    let descriptor = FinanceChartDescriptor(title: "Income", summary: "Old figures", data: [old])
      .makeChartDescriptor()
    let updated = FinanceChartDescriptor(
      title: "Net change", summary: "Current figures",
      data: [datum(label: "Current week", money: Money(-20))])
    updated.updateChartDescriptor(descriptor)
    #expect(descriptor.title == "Net change")
    #expect(descriptor.summary == "Current figures")
    #expect(
      (descriptor.xAxis as? AXCategoricalDataAxisDescriptor)?.categoryOrder == ["Current week"])
    #expect(descriptor.series[0].dataPoints[0].label == "Current week, Current, -MXN 20.00")
    #expect(descriptor.yAxis?.valueDescriptionProvider(-20) == "-MXN 20.00")
  }

  @Test func audioGraphPreservesEverySeriesAndExactMonetaryLabel() throws {
    let amount = try Money(string: "123456789012345678.25")
    let first = datum(label: "Groceries", money: amount)
    let second = ChartDatum(
      id: "previous", key: "Groceries", tick: "Groceries", label: "Groceries",
      series: "Previous", money: Money(50))
    let descriptor = FinanceChartDescriptor(
      title: "Spending", summary: "Two spans", data: [first, second], horizontal: true
    )
    .makeChartDescriptor()
    #expect(descriptor.series.map(\.name) == ["Current", "Previous"])
    #expect(
      descriptor.series[0].dataPoints[0].label?.contains("MXN 123,456,789,012,345,678.25") == true)
    #expect(descriptor.contentDirection == .topToBottom)
  }

  @Test func emptyAudioGraphHasAValidAxisAndNoInventedPoints() {
    let descriptor = FinanceChartDescriptor(title: "Empty", summary: "No activity", data: [])
      .makeChartDescriptor()
    #expect(descriptor.series.isEmpty)
    #expect((descriptor.xAxis as? AXCategoricalDataAxisDescriptor)?.categoryOrder.isEmpty == true)
    #expect(descriptor.yAxis?.range == 0...1)
  }

  private func datum(label: String, money: Money) -> ChartDatum {
    ChartDatum(id: label, key: label, tick: label, label: label, series: "Current", money: money)
  }
}
