import Foundation

public struct SessionReply: Codable, Sendable {
  public let user: User
  public let session: Session
  public struct Session: Codable, Sendable { public let id: String }
}
