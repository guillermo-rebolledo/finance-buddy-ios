import Foundation

public enum PeriodKind: String, Codable, CaseIterable, Sendable {
  case day, week, month
  public var title: String { rawValue.capitalized }
  public var currentTitle: String {
    switch self {
    case .day: "Today"
    case .week: "This week"
    case .month: "This month"
    }
  }
  public var spanTitle: String {
    switch self {
    case .day: "14 days"
    case .week: "12 weeks"
    case .month: "12 months"
    }
  }
}
