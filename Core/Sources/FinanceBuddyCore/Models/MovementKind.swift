import Foundation

public enum MovementKind: String, Codable, CaseIterable, Sendable {
  case income, expense, refund
  public var title: String { rawValue.capitalized }
  public var categoryKind: CategoryKind { self == .income ? .income : .expense }
}
