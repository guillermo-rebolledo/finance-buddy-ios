import Foundation
import OSLog
import Observation

public struct EntryRequest: Codable, Equatable, Sendable {
  public let id: String
  public let kind: MovementKind
  public let amount: Money
  public let date: CalendarDate
  public let categoryId: String?
  public let note: String
  public init(
    id: String, kind: MovementKind, amount: Money, date: CalendarDate, categoryId: String?,
    note: String
  ) {
    self.id = id
    self.kind = kind
    self.amount = amount
    self.date = date
    self.categoryId = categoryId
    self.note = note
  }
  enum CodingKeys: String, CodingKey { case id, kind, amount, date, categoryId, note }
  public func encode(to encoder: any Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(id, forKey: .id)
    try c.encode(kind, forKey: .kind)
    try c.encode(amount, forKey: .amount)
    try c.encode(date, forKey: .date)
    try c.encode(categoryId, forKey: .categoryId)
    try c.encode(note, forKey: .note)
  }
}
