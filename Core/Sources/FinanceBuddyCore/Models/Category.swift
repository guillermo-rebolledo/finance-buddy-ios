import Foundation

public struct Category: Codable, Identifiable, Hashable, Sendable {
  public let id: String
  public let kind: CategoryKind
  public var name: String
  public var active: Bool?
  public init(id: String, kind: CategoryKind, name: String, active: Bool? = true) {
    self.id = id
    self.kind = kind
    self.name = name
    self.active = active
  }
}
