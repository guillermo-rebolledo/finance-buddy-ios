import Foundation
import Security

public struct KeychainError: Error, LocalizedError, Sendable {
  public let status: OSStatus
  public var errorDescription: String? {
    "The secure session could not be stored. Please try again."
  }
}
