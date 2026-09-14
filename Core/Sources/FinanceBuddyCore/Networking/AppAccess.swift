import Foundation
import OSLog
import Observation

@MainActor @Observable public final class AppAccess {
  public var upgradeRequired = false
  public var signedOut = false
  public var offline = false
  public var sessionGeneration = 0
  public init() {}
}
