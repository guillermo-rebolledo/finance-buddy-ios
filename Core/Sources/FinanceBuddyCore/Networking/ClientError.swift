import Foundation
import OSLog
import Observation

public enum ClientError: Error, LocalizedError, Sendable {
  case invalidResponse, missingSignedToken, offline
  public var errorDescription: String? {
    switch self {
    case .invalidResponse: "The server response could not be read. Please try again."
    case .missingSignedToken: "Sign-in was not completed. Please try again."
    case .offline: "You’re offline. Loaded entries remain available. Reconnect to make changes."
    }
  }
}
