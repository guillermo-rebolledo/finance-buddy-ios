import Foundation
import OSLog
import Observation

@MainActor public protocol TokenStorage: AnyObject {
  func read() throws -> String?
  func write(_ token: String?) throws
}
