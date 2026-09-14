import Foundation

public enum CategoryKind: String, Codable, CaseIterable, Sendable {
  case income, expense
  public var title: String { rawValue.capitalized }
}
