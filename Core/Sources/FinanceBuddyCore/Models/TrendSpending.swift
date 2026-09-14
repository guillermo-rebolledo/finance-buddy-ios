import Foundation

public struct TrendSpending: Codable, Sendable, Identifiable {
  public let categoryId: String?
  public let category: String
  public let amount: Money
  public let previous: Money
  public var id: String { categoryId ?? category }
}
