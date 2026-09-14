import Foundation

public struct Trends: Codable, Sendable {
  public let kind: PeriodKind
  public let date: CalendarDate
  public let start: CalendarDate
  public let end: CalendarDate
  public let today: CalendarDate
  public let currency: String
  public let length: Int
  public let points: [TrendPoint]
  public let previous: TrendRange
  public let income: Money
  public let expenses: Money
  public let netChange: Money
  public let previousIncome: Money
  public let previousExpenses: Money
  public let categories: [TrendSpending]
}
