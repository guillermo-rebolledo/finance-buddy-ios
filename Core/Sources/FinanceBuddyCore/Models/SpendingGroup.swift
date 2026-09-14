import Foundation

public struct SpendingGroup: Codable, Sendable, Identifiable {
  public let categoryId: String?
  public let category: String
  public let amount: Money
  public var id: String { categoryId ?? category }
}
