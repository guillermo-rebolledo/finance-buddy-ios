import Accessibility
import Charts
import FinanceBuddyCore
import SwiftUI

/// Conversion to Double is confined to chart geometry and Audio Graphs; labels and arithmetic use Decimal.
struct ChartDatum: Identifiable {
  let id: String
  let key: String
  let tick: String
  let label: String
  let series: String
  let money: Money
  var plotted: Double { NSDecimalNumber(decimal: money.value).doubleValue }
}
