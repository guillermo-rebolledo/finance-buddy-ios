import Foundation
import OSLog
import Observation

@MainActor public final class MemoryTokenStorage: TokenStorage {
  public var token: String?
  public init(_ token: String? = nil) { self.token = token }
  public func read() throws -> String? { token }
  public func write(_ token: String?) throws { self.token = token }
}
