import Foundation

public enum RefusalCode: String, Codable, CaseIterable, Sendable {
  case unauthenticated, forbidden
  case requestNotAllowed = "request_not_allowed"
  case notFound = "not_found"
  case invalidPeriod = "invalid_period"
  case invalidField = "invalid_field"
  case reconnectRequired = "reconnect_required"
  case exportUnconfirmed = "export_unconfirmed"
  case exportPeriodMismatch = "export_period_mismatch"
  case upgradeRequired = "upgrade_required"
  case unavailable
  case notConfirmed = "not_confirmed"
  case unknown
  public init(from decoder: any Decoder) throws {
    self = Self(rawValue: try decoder.singleValueContainer().decode(String.self)) ?? .unknown
  }
}
