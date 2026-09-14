import Foundation

public struct JournalEntry: Codable, Identifiable, Hashable, Sendable {
  public let id: String
  public let kind: MovementKind
  public let amount: Money
  public let date: CalendarDate
  public let categoryId: String?
  public let category: String?
  public let note: String?
  public let currency: String
  public var categoryName: String { category ?? "Uncategorized" }
  public var signedAmount: Money { amount.signed(for: kind) }
}
