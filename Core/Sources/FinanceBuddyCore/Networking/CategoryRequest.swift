import Foundation
import OSLog
import Observation

public struct CategoryRequest: Codable, Equatable, Sendable {
  public enum Action: String, Codable, Sendable { case create, rename, archive, restore }
  public let action: Action
  public let id: String
  public let kind: CategoryKind?
  public let name: String?
  public init(action: Action, id: String, kind: CategoryKind? = nil, name: String? = nil) {
    self.action = action
    self.id = id
    self.kind = kind
    self.name = name
  }
}
