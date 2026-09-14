import Foundation

public struct TrendPoint: Codable, Identifiable, Sendable {
  public let start: CalendarDate
  public let end: CalendarDate
  public let label: String
  public let tick: String
  public let income: Money
  public let expenses: Money
  public let netChange: Money
  public var id: CalendarDate { start }
}
