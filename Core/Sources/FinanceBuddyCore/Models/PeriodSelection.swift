import Foundation

public struct PeriodSelection: Codable, Hashable, Sendable {
  public var kind: PeriodKind
  public var date: CalendarDate?
  public init(kind: PeriodKind = .week, date: CalendarDate? = nil) {
    self.kind = kind
    self.date = date
  }
  public var requestDescription: String {
    date?.formatted(kind == .month ? "MMMM yyyy" : "MMM d, yyyy") ?? kind.currentTitle
  }
}
