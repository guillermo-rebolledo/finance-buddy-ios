import Foundation

public struct Refusal: Error, Codable, Sendable, LocalizedError {
  public let error: String
  public let code: RefusalCode
  public let field: String?
  public let reconnect: Bool?
  public var status: Int?
  public init(_ code: RefusalCode, message: String, field: String? = nil, status: Int? = nil) {
    self.code = code
    error = message
    self.field = field
    reconnect = nil
    self.status = status
  }
  public var errorDescription: String? {
    code == .unknown || code == .requestNotAllowed
      ? "Something went wrong. Please try again." : error
  }
  public static let signInMessage =
    "Sign-in was not completed. Use the authorized, verified Google account and try again."
  public static func map(data: Data, status: Int, signIn: Bool = false, session: Bool = false)
    -> Self
  {
    if var refusal = try? JSONDecoder().decode(Self.self, from: data) {
      refusal.status = status
      return refusal
    }
    if signIn && (status == 401 || status == 403) {
      return Self(.forbidden, message: signInMessage, status: status)
    }
    if session && status == 403 { return Self(.forbidden, message: signInMessage, status: status) }
    if session && status == 503 {
      return Self(.unavailable, message: "Workspace temporarily unavailable.", status: status)
    }
    return Self(.unknown, message: "Something went wrong. Please try again.", status: status)
  }
}
