import Foundation

public struct User: Codable, Sendable {
  public let id: String
  public let name: String
  public let email: String
}
